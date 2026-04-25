from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from contextlib import asynccontextmanager

from .config import settings
from .database import engine, Base, get_db
from .models import User, Currency
from .auth import create_access_token, get_password_hash, verify_password
from .dependencies import get_current_user
from .schemas import Token, UserLogin, UserRegister, UserOut
from .routers import admin, employee, public, customer

@asynccontextmanager
async def lifespan(app: FastAPI):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield

app = FastAPI(title=settings.PROJECT_NAME, version=settings.VERSION, lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # для разработки, продакшн ограничить
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Подключаем роутеры
app.include_router(public.router, prefix="/api/v1")
app.include_router(customer.router, prefix="/api/v1")
app.include_router(admin.router, prefix="/api/v1")
app.include_router(employee.router, prefix="/api/v1")

@app.post("/api/v1/auth/login", response_model=Token)
async def login(login_data: UserLogin, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.username == login_data.username))
    user = result.scalar_one_or_none()
    if not user or not verify_password(login_data.password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
    access_token = create_access_token(data={"sub": str(user.user_id), "role": user.role})
    return {"access_token": access_token, "token_type": "bearer"}

@app.post("/api/v1/auth/register", response_model=UserOut)
async def register(user_data: UserRegister, db: AsyncSession = Depends(get_db)):
    existing = await db.execute(select(User).where(User.username == user_data.username))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Username already exists")

    currency_result = await db.execute(select(Currency).where(Currency.code == user_data.preferred_currency))
    if currency_result.scalar_one_or_none() is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Preferred currency is not supported")

    new_user = User(
        username=user_data.username,
        password_hash=get_password_hash(user_data.password),
        preferred_currency=user_data.preferred_currency,
        preferred_language=user_data.preferred_language,
        preferred_shipment_method=user_data.preferred_shipment_method,
        preferred_payment_method=user_data.preferred_payment_method,
    )
    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)
    return new_user

@app.get("/api/v1/auth/me", response_model=UserOut)
async def get_current_user_info(current_user: User = Depends(get_current_user)):
    return current_user