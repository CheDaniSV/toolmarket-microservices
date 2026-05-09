from pydantic import BaseModel, Field
from typing import Optional, List, Literal
from datetime import datetime

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"

class UserLogin(BaseModel):
    username: str
    password: str

class UserRegister(BaseModel):
    username: str
    password: str
    preferred_currency: str = "RUB"
    preferred_language: str = "en"
    preferred_shipment_method: str = "standard"
    preferred_payment_method: str = "card"

class UserOut(BaseModel):
    user_id: int
    username: str
    role: str
    preferred_language: str
    preferred_currency: str
    preferred_shipment_method: str
    preferred_payment_method: str
    created_at: datetime

    model_config = {"from_attributes": True}

class UserUpdate(BaseModel):
    username: Optional[str] = None
    preferred_language: Optional[Literal["ru", "en"]]
    preferred_currency: Optional[str] = None
    preferred_payment_method: Optional[Literal["card", "paypal", "invoice"]]

class CurrencyOut(BaseModel):
    code: str
    name: str
    symbol: Optional[str] = None
    is_base: bool

    model_config = {"from_attributes": True}

class CategoryBase(BaseModel):
    name: str
    parent_category_id: Optional[int] = None

class CategoryCreate(CategoryBase):
    pass

class CategoryUpdate(BaseModel):
    name: Optional[str] = None
    parent_category_id: Optional[int] = None

class CategoryOut(CategoryBase):
    category_id: int

    model_config = {"from_attributes": True}

class CurrencyCreate(BaseModel):
    code: str
    name: str
    symbol: Optional[str] = None
    is_base: bool = False

class CurrencyUpdate(BaseModel):
    name: Optional[str] = None
    symbol: Optional[str] = None
    is_base: Optional[bool] = None

class UserAddressBase(BaseModel):
    street: str
    city: str
    zip_code: str
    country: str
    is_default: bool = False

class UserAddressCreate(UserAddressBase):
    pass

class UserAddressUpdate(BaseModel):
    street: Optional[str] = None
    city: Optional[str] = None
    zip_code: Optional[str] = None
    country: Optional[str] = None
    is_default: Optional[bool] = None

class UserAddressOut(UserAddressBase):
    address_id: int
    user_id: int

    model_config = {"from_attributes": True}

class ProductBase(BaseModel):
    sku: str
    name: str
    description: Optional[str] = None
    base_price: float = Field(..., gt=0)
    stock: int = Field(0, ge=0)
    category_id: Optional[int] = None

class ProductCreate(ProductBase):
    category_id: Optional[int] = None

class ProductOut(ProductBase):
    product_id: int
    created_at: datetime

    class Config:
        from_attributes = True

class ProductUpdate(BaseModel):
    sku: Optional[str] = None
    name: Optional[str] = None
    description: Optional[str] = None
    base_price: Optional[float] = Field(None, gt=0)
    stock: Optional[int] = Field(None, ge=0)
    category_id: Optional[int] = None

class ProductAttributeCreate(BaseModel):
    product_id: int
    attr_name: str
    attr_value: str

class ProductAttributeUpdate(BaseModel):
    attr_name: Optional[str] = None
    attr_value: Optional[str] = None

class ProductAttributeOut(BaseModel):
    attribute_id: int
    product_id: int
    attr_name: str
    attr_value: str

    model_config = {"from_attributes": True}

class ProductImageCreate(BaseModel):
    product_id: int
    image_url: str
    image_order: int = 0

class ProductImageUpdate(BaseModel):
    image_url: Optional[str] = None
    image_order: Optional[int] = None

class ProductImageOut(BaseModel):
    image_id: int
    product_id: int
    image_url: str
    image_order: int

    model_config = {"from_attributes": True}

class PaymentCreate(BaseModel):
    order_id: int
    amount: float = Field(..., gt=0)
    method: Literal["card", "paypal", "invoice"]

class PaymentOut(BaseModel):
    payment_id: int
    order_id: int
    amount: float
    amount_in_base: float
    method: str
    status: str
    transaction_id: Optional[str] = None
    paid_at: Optional[datetime] = None
    created_at: datetime

    model_config = {"from_attributes": True}

class CartItemCreate(BaseModel):
    product_id: int
    quantity: int = Field(..., gt=0)

class CartItemOut(BaseModel):
    user_id: int
    product_id: int
    quantity: int
    added_at: datetime

    model_config = {"from_attributes": True}

class OrderItemOut(BaseModel):
    product_id: int
    quantity: int
    base_price_at_purchase: float

    model_config = {"from_attributes": True}

class OrderCreate(BaseModel):
    shipping_address_id: int
    billing_address_id: Optional[int] = None
    shipment_method: str = "standard"

class OrderStatusUpdate(BaseModel):
    status: str

class OrderOut(BaseModel):
    order_id: int
    shipping_address_id: int
    billing_address_id: int
    tracking_number: Optional[str] = None
    shipment_method: Optional[str] = None
    user_id: int
    status: str
    total_amount_in_base: float
    order_currency: str
    exchange_rate_at_purchase: float
    created_at: datetime
    items: List[OrderItemOut] = []

    model_config = {"from_attributes": True}

class ReviewCreate(BaseModel):
    product_id: int
    rating: int = Field(..., ge=1, le=5)
    comment: Optional[str] = None

class ReviewOut(BaseModel):
    review_id: int
    product_id: int
    user_id: int
    rating: int
    comment: Optional[str] = None
    created_at: datetime
    helpful_count: int

    model_config = {"from_attributes": True}

class ExchangeRateOut(BaseModel):
    rate_id: int
    from_currency: str
    to_currency: str
    rate: float
    valid_from: datetime
    valid_until: Optional[datetime] = None

    model_config = {"from_attributes": True}
