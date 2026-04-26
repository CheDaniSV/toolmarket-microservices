from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, delete

from ..database import get_db
from ..models import (
    User,
    Order,
    CartItem,
    Product,
    UserAddress,
    OrderItem,
    Review,
    Currency,
    ExchangeRate,
    Payment,
)
from ..schemas import (
    OrderOut,
    CartItemCreate,
    CartItemOut,
    UserAddressCreate,
    UserAddressOut,
    UserAddressUpdate,
    OrderCreate,
    ReviewCreate,
    ReviewOut,
    PaymentCreate,
    PaymentOut,
)
from ..dependencies import role_required, get_current_user

router = APIRouter(prefix="/customer", tags=["customer"])

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

async def _get_order_items(db: AsyncSession, order_id: int) -> list[OrderItem]:
    result = await db.execute(select(OrderItem).where(OrderItem.order_id == order_id))
    return result.scalars().all()

async def _ensure_stock_for_order(order: Order, db: AsyncSession) -> None:
    item_result = await db.execute(select(OrderItem).where(OrderItem.order_id == order.order_id))
    items = item_result.scalars().all()
    for item in items:
        product = await db.get(Product, item.product_id)
        if product is None:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Product {item.product_id} not found")
        if item.quantity > product.stock:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Not enough stock for product {product.product_id}. Available: {product.stock}, requested: {item.quantity}",
            )
    for item in items:
        product = await db.get(Product, item.product_id)
        product.stock -= item.quantity

@router.get("/orders", response_model=list[OrderOut])
async def get_my_orders(
    current_user: User = Depends(role_required(["customer", "employee"])),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Order).where(Order.user_id == current_user.user_id).order_by(Order.created_at.desc())
    )
    orders = result.scalars().all()
    return [await _build_order_dict(order, await _get_order_items(db, order.order_id)) for order in orders]

@router.get("/cart", response_model=list[CartItemOut])
async def get_cart(
    current_user: User = Depends(role_required(["customer"])),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(CartItem).where(CartItem.user_id == current_user.user_id))
    return result.scalars().all()

@router.post("/cart/add", response_model=CartItemOut)
async def add_to_cart(
    item: CartItemCreate,
    current_user: User = Depends(role_required(["customer"])),
    db: AsyncSession = Depends(get_db),
):
    existing = await db.execute(
        select(CartItem).where(
            CartItem.user_id == current_user.user_id,
            CartItem.product_id == item.product_id,
        )
    )
    cart_item = existing.scalar_one_or_none()
    if cart_item:
        cart_item.quantity += item.quantity
    else:
        cart_item = CartItem(user_id=current_user.user_id, **item.model_dump())
        db.add(cart_item)
    await db.commit()
    await db.refresh(cart_item)
    return cart_item

@router.put("/cart/update", response_model=CartItemOut)
async def update_cart_item(
    item: CartItemCreate,
    current_user: User = Depends(role_required(["customer"])),
    db: AsyncSession = Depends(get_db),
):
    cart_item = await db.get(CartItem, (current_user.user_id, item.product_id))
    if cart_item is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Cart item not found")
    cart_item.quantity = item.quantity
    await db.commit()
    await db.refresh(cart_item)
    return cart_item

@router.delete("/cart/{product_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_from_cart(
    product_id: int,
    current_user: User = Depends(role_required(["customer"])),
    db: AsyncSession = Depends(get_db),
):
    cart_item = await db.get(CartItem, (current_user.user_id, product_id))
    if cart_item is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Cart item not found")
    await db.delete(cart_item)
    await db.commit()

@router.get("/addresses", response_model=list[UserAddressOut])
async def list_addresses(
    current_user: User = Depends(role_required(["customer"])),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(UserAddress).where(UserAddress.user_id == current_user.user_id))
    return result.scalars().all()

@router.post("/addresses", response_model=UserAddressOut)
async def create_address(
    address: UserAddressCreate,
    current_user: User = Depends(role_required(["customer"])),
    db: AsyncSession = Depends(get_db),
):
    new_address = UserAddress(user_id=current_user.user_id, **address.model_dump())
    db.add(new_address)
    await db.commit()
    await db.refresh(new_address)
    return new_address

@router.put("/addresses/{address_id}", response_model=UserAddressOut)
async def update_address(
    address_id: int,
    address: UserAddressUpdate,
    current_user: User = Depends(role_required(["customer"])),
    db: AsyncSession = Depends(get_db),
):
    existing = await db.get(UserAddress, address_id)
    if existing is None or existing.user_id != current_user.user_id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Address not found")
    for field, value in address.model_dump(exclude_unset=True).items():
        setattr(existing, field, value)
    await db.commit()
    await db.refresh(existing)
    return existing

@router.delete("/addresses/{address_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_address(
    address_id: int,
    current_user: User = Depends(role_required(["customer"])),
    db: AsyncSession = Depends(get_db),
):
    existing = await db.get(UserAddress, address_id)
    if existing is None or existing.user_id != current_user.user_id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Address not found")
    await db.delete(existing)
    await db.commit()

@router.post("/orders", response_model=OrderOut)
async def create_order(
    order_data: OrderCreate,
    current_user: User = Depends(role_required(["customer"])),
    db: AsyncSession = Depends(get_db),
):
    cart_result = await db.execute(select(CartItem).where(CartItem.user_id == current_user.user_id))
    cart_items = cart_result.scalars().all()
    if not cart_items:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Cart is empty")

    billing_address_id = order_data.billing_address_id or order_data.shipping_address_id
    address_ids = {order_data.shipping_address_id, billing_address_id}
    address_result = await db.execute(
        select(UserAddress).where(
            UserAddress.address_id.in_(list(address_ids)),
            UserAddress.user_id == current_user.user_id,
        )
    )
    valid_addresses = address_result.scalars().all()
    if len(valid_addresses) < len(address_ids):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Shipping or billing address is invalid")

    base_currency_result = await db.execute(select(Currency).where(Currency.is_base == True))
    base_currency = base_currency_result.scalar_one_or_none()
    if base_currency is None:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Base currency not configured")

    total_amount_in_base = Decimal(0)
    order_items: list[OrderItem] = []
    for cart_item in cart_items:
        product = await db.get(Product, cart_item.product_id)
        if product is None:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Product {cart_item.product_id} not found")
        if cart_item.quantity > product.stock:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Not enough stock for product {product.product_id}. Available: {product.stock}, requested: {cart_item.quantity}",
            )
        total_amount_in_base += Decimal(product.base_price) * cart_item.quantity
        order_items.append((cart_item, product))

    order_currency = current_user.preferred_currency or base_currency.code
    exchange_rate_at_purchase = Decimal(1)
    if order_currency != base_currency.code:
        rate_result = await db.execute(
            select(ExchangeRate)
            .where(
                ExchangeRate.from_currency == base_currency.code,
                ExchangeRate.to_currency == order_currency,
                ExchangeRate.valid_until.is_(None),
            )
            .order_by(ExchangeRate.valid_from.desc())
            .limit(1)
        )
        active_rate = rate_result.scalar_one_or_none()
        if active_rate is None:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Exchange rate for user currency is not available")
        exchange_rate_at_purchase = active_rate.rate

    new_order = Order(
        shipping_address_id=order_data.shipping_address_id,
        billing_address_id=billing_address_id,
        shipment_method=order_data.shipment_method,
        user_id=current_user.user_id,
        status="created",
        total_amount_in_base=total_amount_in_base,
        order_currency=order_currency,
        exchange_rate_at_purchase=exchange_rate_at_purchase,
    )
    db.add(new_order)
    await db.flush()

    created_items = []
    for cart_item, product in order_items:
        order_item = OrderItem(
            order_id=new_order.order_id,
            product_id=product.product_id,
            quantity=cart_item.quantity,
            base_price_at_purchase=product.base_price,
        )
        db.add(order_item)
        created_items.append(order_item)

    await db.execute(delete(CartItem).where(CartItem.user_id == current_user.user_id))
    await db.commit()
    await db.refresh(new_order)

    return await _build_order_dict(new_order, created_items)

@router.delete("/account", status_code=status.HTTP_204_NO_CONTENT)
async def delete_account(
    current_user: User = Depends(role_required(["customer"])),
    db: AsyncSession = Depends(get_db),
):
    order_result = await db.execute(select(Order.order_id).where(Order.user_id == current_user.user_id))
    order_ids = [order_id for order_id in order_result.scalars().all()]
    if order_ids:
        await db.execute(delete(Payment).where(Payment.order_id.in_(order_ids)))
        await db.execute(delete(OrderItem).where(OrderItem.order_id.in_(order_ids)))
        await db.execute(delete(Order).where(Order.order_id.in_(order_ids)))

    await db.delete(current_user)
    await db.commit()

@router.delete("/reviews/{review_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_review(
    review_id: int,
    current_user: User = Depends(role_required(["customer"])),
    db: AsyncSession = Depends(get_db),
):
    review = await db.get(Review, review_id)
    if review is None or review.user_id != current_user.user_id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Review not found")
    await db.delete(review)
    await db.commit()

@router.post("/payments", response_model=PaymentOut)
async def create_payment(
    payment_data: PaymentCreate,
    current_user: User = Depends(role_required(["customer"])),
    db: AsyncSession = Depends(get_db),
):
    order = await db.get(Order, payment_data.order_id)
    if order is None or order.user_id != current_user.user_id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    if order.status != "created":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Order cannot be paid in the current status")

    base_currency_result = await db.execute(select(Currency).where(Currency.is_base == True))
    base_currency = base_currency_result.scalar_one_or_none()
    if base_currency is None:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Base currency not configured")

    amount_in_base = Decimal(payment_data.amount)
    if order.order_currency != base_currency.code:
        if order.exchange_rate_at_purchase is None or order.exchange_rate_at_purchase == 0:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Exchange rate for this order is not available")
        amount_in_base = Decimal(payment_data.amount) / Decimal(order.exchange_rate_at_purchase)

    if amount_in_base != Decimal(order.total_amount_in_base):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Payment amount does not match order total",
        )

    await _ensure_stock_for_order(order, db)

    new_payment = Payment(
        order_id=order.order_id,
        amount=payment_data.amount,
        amount_in_base=amount_in_base,
        method=payment_data.method,
        status="completed",
    )
    order.status = "payed"
    db.add(new_payment)
    db.add(order)
    await db.commit()
    await db.refresh(new_payment)
    await db.refresh(order)
    return new_payment

@router.post("/reviews", response_model=ReviewOut)
async def add_review(
    review_data: ReviewCreate,
    current_user: User = Depends(role_required(["customer"])),
    db: AsyncSession = Depends(get_db),
):
    product = await db.get(Product, review_data.product_id)
    if product is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")

    existing = await db.execute(
        select(Review).where(
            Review.product_id == review_data.product_id,
            Review.user_id == current_user.user_id,
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Review already exists")

    new_review = Review(
        product_id=review_data.product_id,
        user_id=current_user.user_id,
        rating=review_data.rating,
        comment=review_data.comment,
    )
    db.add(new_review)
    await db.commit()
    await db.refresh(new_review)
    return new_review
