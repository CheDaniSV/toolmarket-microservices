from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from ..database import get_db
from ..models import (
    Category,
    Currency,
    Order,
    OrderItem,
    Product,
    ProductAttribute,
    ProductImage,
    Review,
    ExchangeRate,
)
from ..schemas import (
    ProductCreate,
    ProductUpdate,
    ProductOut,
    ProductAttributeCreate,
    ProductAttributeOut,
    ProductAttributeUpdate,
    ProductImageCreate,
    ProductImageOut,
    ProductImageUpdate,
    CategoryCreate,
    CategoryOut,
    CategoryUpdate,
    CurrencyCreate,
    CurrencyOut,
    CurrencyUpdate,
    OrderOut,
    OrderStatusUpdate,
)
from ..dependencies import role_required

router = APIRouter(prefix="/employee", tags=["employee"])

async def _build_order_dict(order: Order, items: list[OrderItem]) -> dict:
    return {
        "order_id": order.order_id,
        "shipping_address_id": order.shipping_address_id,
        "billing_address_id": order.billing_address_id,
        "tracking_number": order.tracking_number,
        "shipment_method": order.shipment_method,
        "user_id": order.user_id,
        "status": order.status,
        "total_amount_in_base": float(order.total_amount_in_base),
        "order_currency": order.order_currency,
        "exchange_rate_at_purchase": float(order.exchange_rate_at_purchase),
        "created_at": order.created_at,
        "items": [
            {
                "product_id": item.product_id,
                "quantity": item.quantity,
                "base_price_at_purchase": float(item.base_price_at_purchase),
            }
            for item in items
        ],
    }

@router.post("/categories", response_model=CategoryOut)
async def create_category(
    category: CategoryCreate,
    db: AsyncSession = Depends(get_db),
    _: object = Depends(role_required(["employee"])),
):
    new_category = Category(**category.model_dump())
    db.add(new_category)
    await db.commit()
    await db.refresh(new_category)
    return new_category

@router.delete("/categories/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_category(
    category_id: int,
    db: AsyncSession = Depends(get_db),
    _: object = Depends(role_required(["employee"])),
):
    existing = await db.get(Category, category_id)
    if existing is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Category not found")
    await db.delete(existing)
    await db.commit()

@router.put("/categories/{category_id}", response_model=CategoryOut)
async def update_category(
    category_id: int,
    category: CategoryUpdate,
    db: AsyncSession = Depends(get_db),
    _: object = Depends(role_required(["employee"])),
):
    existing = await db.get(Category, category_id)
    if existing is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Category not found")
    for field, value in category.model_dump(exclude_unset=True).items():
        setattr(existing, field, value)
    await db.commit()
    await db.refresh(existing)
    return existing

@router.post("/currencies", response_model=CurrencyOut)
async def create_currency(
    currency: CurrencyCreate,
    db: AsyncSession = Depends(get_db),
    _: object = Depends(role_required(["employee"])),
):
    existing = await db.get(Currency, currency.code)
    if existing is not None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Currency already exists")
    new_currency = Currency(**currency.model_dump())
    db.add(new_currency)
    await db.commit()
    await db.refresh(new_currency)
    return new_currency

@router.put("/currencies/{currency_code}", response_model=CurrencyOut)
async def update_currency(
    currency_code: str,
    currency: CurrencyUpdate,
    db: AsyncSession = Depends(get_db),
    _: object = Depends(role_required(["employee"])),
):
    existing = await db.get(Currency, currency_code.upper())
    if existing is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Currency not found")
    for field, value in currency.model_dump(exclude_unset=True).items():
        setattr(existing, field, value)
    await db.commit()
    await db.refresh(existing)
    return existing

@router.post("/products", response_model=ProductOut)
async def create_product(
    product: ProductCreate,
    db: AsyncSession = Depends(get_db),
    _: object = Depends(role_required(["employee"])),
):
    existing = await db.execute(select(Product).where(Product.sku == product.sku))
    if existing.scalar_one_or_none() is not None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Product SKU already exists")
    new_product = Product(**product.model_dump())
    db.add(new_product)
    await db.commit()
    await db.refresh(new_product)
    return new_product

@router.put("/products/{product_id}", response_model=ProductOut)
async def update_product(
    product_id: int,
    product: ProductUpdate,
    db: AsyncSession = Depends(get_db),
    _: object = Depends(role_required(["employee"])),
):
    existing = await db.get(Product, product_id)
    if existing is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")
    update_data = product.model_dump(exclude_unset=True)
    if "sku" in update_data:
        sku_exists = await db.execute(select(Product).where(Product.sku == update_data["sku"], Product.product_id != product_id))
        if sku_exists.scalar_one_or_none() is not None:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Product SKU already exists")
    for field, value in update_data.items():
        setattr(existing, field, value)
    await db.commit()
    await db.refresh(existing)
    return existing

@router.delete("/products/{product_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_product(
    product_id: int,
    db: AsyncSession = Depends(get_db),
    _: object = Depends(role_required(["employee"])),
):
    existing = await db.get(Product, product_id)
    if existing is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")
    await db.delete(existing)
    await db.commit()

@router.post("/product_images", response_model=ProductImageOut)
async def create_product_image(
    image: ProductImageCreate,
    db: AsyncSession = Depends(get_db),
    _: object = Depends(role_required(["employee"])),
):
    new_image = ProductImage(**image.model_dump())
    db.add(new_image)
    await db.commit()
    await db.refresh(new_image)
    return new_image

@router.put("/product_images/{image_id}", response_model=ProductImageOut)
async def update_product_image(
    image_id: int,
    image: ProductImageUpdate,
    db: AsyncSession = Depends(get_db),
    _: object = Depends(role_required(["employee"])),
):
    existing = await db.get(ProductImage, image_id)
    if existing is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product image not found")
    for field, value in image.model_dump(exclude_unset=True).items():
        setattr(existing, field, value)
    await db.commit()
    await db.refresh(existing)
    return existing

@router.delete("/product_images/{image_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_product_image(
    image_id: int,
    db: AsyncSession = Depends(get_db),
    _: object = Depends(role_required(["employee"])),
):
    existing = await db.get(ProductImage, image_id)
    if existing is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product image not found")
    await db.delete(existing)
    await db.commit()

@router.post("/product_attributes", response_model=ProductAttributeOut)
async def create_product_attribute(
    attribute: ProductAttributeCreate,
    db: AsyncSession = Depends(get_db),
    _: object = Depends(role_required(["employee"])),
):
    existing = await db.execute(
        select(ProductAttribute).where(
            ProductAttribute.product_id == attribute.product_id,
            ProductAttribute.attr_name == attribute.attr_name,
        )
    )
    if existing.scalar_one_or_none() is not None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Product attribute already exists")
    new_attribute = ProductAttribute(**attribute.model_dump())
    db.add(new_attribute)
    await db.commit()
    await db.refresh(new_attribute)
    return new_attribute

@router.put("/product_attributes/{attribute_id}", response_model=ProductAttributeOut)
async def update_product_attribute(
    attribute_id: int,
    attribute: ProductAttributeUpdate,
    db: AsyncSession = Depends(get_db),
    _: object = Depends(role_required(["employee"])),
):
    existing = await db.get(ProductAttribute, attribute_id)
    if existing is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product attribute not found")
    for field, value in attribute.model_dump(exclude_unset=True).items():
        setattr(existing, field, value)
    await db.commit()
    await db.refresh(existing)
    return existing

@router.delete("/product_attributes/{attribute_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_product_attribute(
    attribute_id: int,
    db: AsyncSession = Depends(get_db),
    _: object = Depends(role_required(["employee"])),
):
    existing = await db.get(ProductAttribute, attribute_id)
    if existing is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product attribute not found")
    await db.delete(existing)
    await db.commit()

@router.delete("/reviews/{review_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_review(
    review_id: int,
    db: AsyncSession = Depends(get_db),
    _: object = Depends(role_required(["employee"])),
):
    review = await db.get(Review, review_id)
    if review is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Review not found")
    await db.delete(review)
    await db.commit()

@router.get("/orders", response_model=list[OrderOut])
async def list_orders(
    status_filter: str | None = Query(None, alias="status"),
    db: AsyncSession = Depends(get_db),
    _: object = Depends(role_required(["employee"])),
):
    query = select(Order)
    if status_filter:
        query = query.where(Order.status == status_filter)
    result = await db.execute(query.order_by(Order.created_at.desc()))
    orders = result.scalars().all()
    order_list = []
    for order in orders:
        item_result = await db.execute(select(OrderItem).where(OrderItem.order_id == order.order_id))
        items = item_result.scalars().all()
        order_list.append(await _build_order_dict(order, items))
    return order_list

@router.put("/orders/{order_id}/status", response_model=OrderOut)
async def update_order_status(
    order_id: int,
    status_update: OrderStatusUpdate,
    db: AsyncSession = Depends(get_db),
    _: object = Depends(role_required(["employee"])),
):
    order = await db.get(Order, order_id)
    if order is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    order.status = status_update.status
    await db.commit()
    await db.refresh(order)
    item_result = await db.execute(select(OrderItem).where(OrderItem.order_id == order.order_id))
    items = item_result.scalars().all()
    return await _build_order_dict(order, items)

