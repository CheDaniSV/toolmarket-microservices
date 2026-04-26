from time import perf_counter

from fastapi import FastAPI, Depends, HTTPException, Response, status
from fastapi.middleware.cors import CORSMiddleware
from prometheus_client import Counter, Gauge, Histogram, CONTENT_TYPE_LATEST, generate_latest
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, text, func
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from contextlib import asynccontextmanager

from .config import settings
from .database import engine, Base, get_db
from .models import User, Currency, Product, Order, Payment
from .auth import create_access_token, get_password_hash, verify_password
from .dependencies import get_current_user
from .schemas import Token, UserLogin, UserRegister, UserOut
from .routers import employee, public, customer

@asynccontextmanager
async def lifespan(app: FastAPI):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
        await conn.execute(
            text(
                "ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_status_check"
            )
        )
        await conn.execute(
            text(
                "ALTER TABLE orders ADD CONSTRAINT orders_status_check CHECK (status IN ('created', 'payed', 'processing', 'completed', 'cancelled'))"
            )
        )
    yield

app = FastAPI(title=settings.PROJECT_NAME, version=settings.VERSION, lifespan=lifespan)

HTTP_REQUESTS = Counter(
    "toolmarket_http_requests_total",
    "HTTP requests received",
    ["method", "path", "status"],
)
HTTP_REQUEST_DURATION_SECONDS = Histogram(
    "toolmarket_http_request_duration_seconds",
    "HTTP request duration in seconds",
    ["method", "path", "status"],
)
HTTP_REQUEST_EXCEPTIONS = Counter(
    "toolmarket_http_exceptions_total",
    "HTTP exceptions raised during request handling",
    ["method", "path", "exception"],
)

USER_COUNT_GAUGE = Gauge("toolmarket_users_total", "Total registered users")
PRODUCT_COUNT_GAUGE = Gauge("toolmarket_products_total", "Total products")
STOCK_UNITS_GAUGE = Gauge("toolmarket_stock_units_total", "Total product units in stock")
ORDER_COUNT_GAUGE = Gauge("toolmarket_orders_total", "Total orders")
ORDER_STATUS_GAUGE = Gauge(
    "toolmarket_orders_by_status_total",
    "Orders grouped by status",
    ["status"],
)
PAYMENT_COUNT_GAUGE = Gauge("toolmarket_payments_total", "Total payments")
COMPLETED_PAYMENT_COUNT_GAUGE = Gauge(
    "toolmarket_payments_completed_total",
    "Payments completed",
)
TOTAL_REVENUE_GAUGE = Gauge("toolmarket_revenue_base_total", "Total payment revenue in base currency")


def _get_route_path(request: Request) -> str:
    route = request.scope.get("route")
    if route is not None and hasattr(route, "path"):
        return route.path
    return request.url.path


class PrometheusMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        start_time = perf_counter()
        exception = None
        status_code = "500"
        try:
            response = await call_next(request)
            status_code = str(response.status_code)
            return response
        except Exception as exc:
            exception = exc
            raise
        finally:
            elapsed = perf_counter() - start_time
            path = _get_route_path(request)
            HTTP_REQUESTS.labels(method=request.method, path=path, status=status_code).inc()
            HTTP_REQUEST_DURATION_SECONDS.labels(method=request.method, path=path, status=status_code).observe(elapsed)
            if exception is not None:
                HTTP_REQUEST_EXCEPTIONS.labels(
                    method=request.method,
                    path=path,
                    exception=type(exception).__name__,
                ).inc()


app.add_middleware(PrometheusMiddleware)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # для разработки, продакшн ограничить
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


async def _collect_business_metrics(db: AsyncSession) -> None:
    result = await db.execute(select(func.count(User.user_id)))
    USER_COUNT_GAUGE.set(result.scalar_one())

    result = await db.execute(select(func.count(Product.product_id)))
    PRODUCT_COUNT_GAUGE.set(result.scalar_one())

    result = await db.execute(select(func.coalesce(func.sum(Product.stock), 0)))
    STOCK_UNITS_GAUGE.set(float(result.scalar_one()))

    result = await db.execute(select(func.count(Order.order_id)))
    ORDER_COUNT_GAUGE.set(result.scalar_one())

    ORDER_STATUS_GAUGE.clear()
    status_counts = await db.execute(select(Order.status, func.count(Order.order_id)).group_by(Order.status))
    for status, count in status_counts.all():
        ORDER_STATUS_GAUGE.labels(status=status).set(count)

    result = await db.execute(select(func.count(Payment.payment_id)))
    PAYMENT_COUNT_GAUGE.set(result.scalar_one())

    result = await db.execute(
        select(func.count(Payment.payment_id)).where(Payment.status == "completed")
    )
    COMPLETED_PAYMENT_COUNT_GAUGE.set(result.scalar_one())

    result = await db.execute(
        select(func.coalesce(func.sum(Payment.amount_in_base), 0)).where(Payment.status == "completed")
    )
    TOTAL_REVENUE_GAUGE.set(float(result.scalar_one()))


@app.get("/metrics")
async def metrics(db: AsyncSession = Depends(get_db)):
    await _collect_business_metrics(db)
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)


# Подключаем роутеры
app.include_router(public.router, prefix="/api/v1")
app.include_router(customer.router, prefix="/api/v1")
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