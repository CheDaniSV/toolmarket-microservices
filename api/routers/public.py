from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_
from typing import List, Optional

from ..database import get_db
from ..models import Product, Currency, Category, Review, ExchangeRate, ProductAttribute, ProductImage
from ..schemas import ProductOut, CategoryOut, CurrencyOut, ReviewOut, ExchangeRateOut, ProductAttributeOut, ProductImageOut

router = APIRouter(prefix="/public", tags=["public"])

@router.get("/products", response_model=List[ProductOut])
async def list_products(
    category_id: Optional[int] = Query(None, ge=1),
    search: Optional[str] = Query(None, min_length=1),
    offset: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db)
):
    query = select(Product)
    if category_id is not None:
        query = query.where(Product.category_id == category_id)
    if search:
        pattern = f"%{search}%"
        query = query.where(
            or_(Product.sku.ilike(pattern), Product.name.ilike(pattern), Product.description.ilike(pattern))
        )
    query = query.order_by(Product.product_id)
    result = await db.execute(query.offset(offset).limit(limit))
    return result.scalars().all()

@router.get("/products/{product_id}", response_model=ProductOut)
async def get_product(product_id: int, db: AsyncSession = Depends(get_db)):
    product = await db.get(Product, product_id)
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    return product

@router.get("/categories", response_model=List[CategoryOut])
async def list_categories(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Category))
    return result.scalars().all()

@router.get("/currencies", response_model=List[CurrencyOut])
async def list_currencies(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Currency))
    return result.scalars().all()

@router.get("/exchange-rates", response_model=List[ExchangeRateOut])
async def list_exchange_rates(
    from_currency: Optional[str] = Query(None, min_length=3, max_length=3),
    to_currency: Optional[str] = Query(None, min_length=3, max_length=3),
    active: bool = Query(True),
    db: AsyncSession = Depends(get_db)
):
    query = select(ExchangeRate)
    if from_currency:
        query = query.where(ExchangeRate.from_currency == from_currency.upper())
    if to_currency:
        query = query.where(ExchangeRate.to_currency == to_currency.upper())
    if active:
        query = query.where(ExchangeRate.valid_until.is_(None))
    result = await db.execute(query.order_by(ExchangeRate.valid_from.desc()))
    return result.scalars().all()

@router.get("/products/{product_id}/attributes", response_model=List[ProductAttributeOut])
async def list_product_attributes(product_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(ProductAttribute).where(ProductAttribute.product_id == product_id))
    return result.scalars().all()

@router.get("/products/{product_id}/images", response_model=List[ProductImageOut])
async def list_product_images(product_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(ProductImage).where(ProductImage.product_id == product_id))
    return result.scalars().all()

@router.get("/products/{product_id}/reviews", response_model=List[ReviewOut])
async def list_product_reviews(product_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Review).where(Review.product_id == product_id))
    return result.scalars().all()
