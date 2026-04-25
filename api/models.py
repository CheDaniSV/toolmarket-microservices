from sqlalchemy import Column, Integer, Index, String, Numeric, Boolean, ForeignKey, DateTime, CheckConstraint, Text, UniqueConstraint
from sqlalchemy.sql import func
from .database import Base

class Currency(Base):
    __tablename__ = "currencies"

    code = Column(String(3), primary_key=True)
    name = Column(String(50), nullable=False)
    symbol = Column(String(5))
    is_base = Column(Boolean, default=False)

class User(Base):
    __tablename__ = "users"

    user_id = Column(Integer, primary_key=True, autoincrement=True, index=True)
    username = Column(String(80), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    role = Column(String(20), nullable=False, default="customer")
    preferred_language = Column(String(10), default='ru')
    preferred_currency = Column(String(3), ForeignKey("currencies.code"), nullable=False)
    preferred_shipment_method = Column(String(50), default='standard')
    preferred_payment_method = Column(String(50), default='card')
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    __table_args__ = (
        CheckConstraint("role IN ('customer', 'employee')"),
        CheckConstraint("preferred_language IN ('ru', 'en')"),
        CheckConstraint("preferred_shipment_method IN ('standard', 'express', 'pickup')"),
        CheckConstraint("preferred_payment_method IN ('card', 'paypal', 'invoice')"),
    )

class UserAddress(Base):
    __tablename__ = "user_addresses"

    address_id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.user_id", ondelete="CASCADE"), nullable=False, index=True)
    street = Column(String(255), nullable=False)
    city = Column(String(100), nullable=False)
    zip_code = Column(String(20), nullable=False)
    country = Column(String(100), nullable=False)
    is_default = Column(Boolean, nullable=False, default=False)

class Category(Base):
    __tablename__ = "categories"

    category_id = Column(Integer, primary_key=True, autoincrement=True)
    parent_category_id = Column(Integer, ForeignKey("categories.category_id", ondelete="SET NULL"), index=True)
    name = Column(String(50), unique=True, nullable=False)

class Product(Base):
    __tablename__ = "products"

    product_id = Column(Integer, primary_key=True, autoincrement=True, index=True)
    sku = Column(String(50), unique=True, nullable=False, index=True)
    name = Column(String(150), nullable=False)
    description = Column(Text)
    base_price = Column(Numeric(12,2), nullable=False)
    stock = Column(Integer, default=0)
    category_id = Column(Integer, ForeignKey("categories.category_id"), index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class ProductAttribute(Base):
    __tablename__ = "product_attributes"

    attribute_id = Column(Integer, primary_key=True, autoincrement=True)
    product_id = Column(Integer, ForeignKey("products.product_id", ondelete="CASCADE"), nullable=False, index=True)
    attr_name = Column(String(100), nullable=False)
    attr_value = Column(Text, nullable=False)

    __table_args__ = (
        UniqueConstraint('product_id', 'attr_name', name='unique_attr_name_per_product'),
    )

class ProductImage(Base):
    __tablename__ = "product_images"

    image_id = Column(Integer, primary_key=True, autoincrement=True)
    product_id = Column(Integer, ForeignKey("products.product_id", ondelete="CASCADE"), nullable=False, index=True)
    image_url = Column(String(255), nullable=False)
    image_order = Column(Integer, default=0)

    __table_args__ = (
        UniqueConstraint('product_id', 'image_order', name='unique_image_order_per_product'),
    )

class Order(Base):
    __tablename__ = "orders"

    order_id = Column(Integer, primary_key=True, autoincrement=True, index=True)
    shipping_address_id = Column(Integer, ForeignKey("user_addresses.address_id"), nullable=False, index=True)
    billing_address_id = Column(Integer, ForeignKey("user_addresses.address_id"), nullable=False, index=True)
    tracking_number = Column(String(100), unique=True)
    shipment_method = Column(String(50))
    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False, index=True)
    status = Column(String(20), default='created')
    total_amount_in_base = Column(Numeric(12,2))
    order_currency = Column(String(3), ForeignKey("currencies.code"), nullable=False)
    exchange_rate_at_purchase = Column(Numeric(12,6), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)

    __table_args__ = (
        CheckConstraint("shipment_method IN ('standard', 'express', 'pickup')"),
        CheckConstraint("status IN ('created', 'payed', 'processing', 'completed', 'cancelled')"),
    )

class OrderItem(Base):
    __tablename__ = "order_items"

    order_item_id = Column(Integer, primary_key=True, autoincrement=True)
    order_id = Column(Integer, ForeignKey("orders.order_id"), index=True)
    product_id = Column(Integer, ForeignKey("products.product_id", ondelete="CASCADE"), nullable=False, index=True)
    quantity = Column(Integer, nullable=False)
    base_price_at_purchase = Column(Numeric(12,2), nullable=False)

class Review(Base):
    __tablename__ = "reviews"

    review_id = Column(Integer, primary_key=True, autoincrement=True)
    product_id = Column(Integer, ForeignKey("products.product_id", ondelete="CASCADE"), nullable=False, index=True)
    user_id = Column(Integer, ForeignKey("users.user_id", ondelete="SET NULL"), index=True)
    rating = Column(Integer)
    comment = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    helpful_count = Column(Integer, default=0)

    __table_args__ = (
        CheckConstraint("rating >= 1 AND rating <= 5"),
        UniqueConstraint('product_id', 'user_id'),
    )

class CartItem(Base):
    __tablename__ = "cart_items"

    user_id = Column(Integer, ForeignKey("users.user_id", ondelete="CASCADE"), primary_key=True)
    product_id = Column(Integer, ForeignKey("products.product_id", ondelete="CASCADE"), primary_key=True)
    quantity = Column(Integer, nullable=False)
    added_at = Column(DateTime(timezone=True), server_default=func.now())

    __table_args__ = (
        CheckConstraint("quantity > 0"),
    )

class Payment(Base):
    __tablename__ = "payments"

    payment_id = Column(Integer, primary_key=True, autoincrement=True)
    order_id = Column(Integer, ForeignKey("orders.order_id"), nullable=False, index=True)
    amount = Column(Numeric(12,2), nullable=False)
    amount_in_base = Column(Numeric(12,2), nullable=False)
    method = Column(String(50), nullable=False)
    status = Column(String(20), default='pending')
    transaction_id = Column(String(100))
    paid_at = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    __table_args__ = (
        CheckConstraint("method IN ('card', 'paypal', 'invoice')"),
        CheckConstraint("status IN ('pending', 'completed', 'failed')"),
    )

class ExchangeRate(Base):
    __tablename__ = "exchange_rates"

    rate_id = Column(Integer, primary_key=True, autoincrement=True)
    from_currency = Column(String(3), ForeignKey("currencies.code"), nullable=False)
    to_currency = Column(String(3), ForeignKey("currencies.code"), nullable=False)
    rate = Column(Numeric(18,6), nullable=False)
    valid_from = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
    valid_until = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    __table_args__ = (
        Index('idx_exchange_rates_lookup', 'from_currency', 'to_currency', 'valid_from'),
    )