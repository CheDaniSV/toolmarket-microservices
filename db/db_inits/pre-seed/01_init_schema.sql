-- Курсы валют, для поддержки мультивалютности
CREATE TABLE currencies (
    code CHAR(3) PRIMARY KEY NOT NULL, -- ISO 4217 код, например, 'USD', 'EUR', 'GBP', 'RUB'
    name VARCHAR(50) NOT NULL,
    symbol VARCHAR(5),            -- Символ валюты: '$', '€'
    is_base BOOLEAN DEFAULT FALSE -- Только у одной валюты здесь будет TRUE
);

-- Таблица пользователей
CREATE TABLE users (
    user_id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    username VARCHAR(80) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('customer', 'employee')),
    preferred_language VARCHAR(10) DEFAULT 'ru' CHECK (preferred_language IN ('ru', 'en')), -- Поддержка нескольких языков
    preferred_currency CHAR(3) NOT NULL REFERENCES currencies(code),
    preferred_shipment_method VARCHAR(50) DEFAULT 'standard' CHECK (preferred_shipment_method IN ('standard', 'express', 'pickup')),
    preferred_payment_method VARCHAR(50) DEFAULT 'card' CHECK (preferred_payment_method IN ('card', 'paypal', 'invoice')),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Таблица адресов пользователей, с поддержкой нескольких адресов для одного пользователя
CREATE TABLE user_addresses (
    address_id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    street VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    zip_code VARCHAR(20) NOT NULL,
    country VARCHAR(100) NOT NULL,
    is_default BOOLEAN NOT NULL DEFAULT FALSE -- Один адрес может быть помечен как основной для доставки
);

-- Таблица категорий товаров, с поддержкой иерархии (родительская категория может иметь дочерние)
CREATE TABLE categories (
    category_id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    parent_category_id INTEGER REFERENCES categories(category_id) ON DELETE SET NULL,
    name VARCHAR(50) UNIQUE NOT NULL
);

-- Таблица товаров
CREATE TABLE products (
    product_id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    sku VARCHAR(50) UNIQUE NOT NULL, -- Артикул
    name VARCHAR(150) NOT NULL,
    description TEXT,
    base_price NUMERIC(12,2) NOT NULL,
    stock INTEGER DEFAULT 0,
    category_id INTEGER REFERENCES categories(category_id),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Позволяет создавать несколько аттрибутов для одного товара (например, цвет, размер, вес и т.д.)
CREATE TABLE product_attributes (
    attribute_id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    product_id INTEGER NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    attr_name VARCHAR(100) NOT NULL,
    attr_value TEXT NOT NULL,
    CONSTRAINT unique_attr_name_per_product UNIQUE (product_id, attr_name)
);

-- Картинки товаров,
CREATE TABLE product_images (
    image_id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    product_id INTEGER NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    image_url VARCHAR(255) NOT NULL, -- URL-адрес картинки, может быть локальным (например, /images/product123.jpg) или внешним (https://example.com/image.jpg)
    image_order INTEGER DEFAULT 0, -- Порядок отображения картинок для одного товара,
    CONSTRAINT unique_image_order_per_product UNIQUE (product_id, image_order)
);

-- Таблица заказов
CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    shipping_address_id INTEGER NOT NULL REFERENCES user_addresses(address_id),
    billing_address_id INTEGER NOT NULL REFERENCES user_addresses(address_id), -- Если нужно хранить отдельный адрес для выставления счета
    tracking_number VARCHAR(100) UNIQUE,
    shipment_method VARCHAR(50) CHECK (shipment_method IN ('standard', 'express', 'pickup')),
    user_id INTEGER NOT NULL REFERENCES users(user_id),
    status VARCHAR(20) DEFAULT 'created' CHECK (status IN ('created', 'payed', 'processing', 'completed', 'cancelled')),
    total_amount_in_base NUMERIC(12,2),
    order_currency CHAR(3) NOT NULL REFERENCES currencies(code), -- Валюта, в которой был оформлен заказ
    exchange_rate_at_purchase NUMERIC(12,6) NOT NULL, -- Курс валюты на момент покупки, для корректного расчёта в случае изменения курсов (в случае покупки не в базовой валюте)
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE order_items (
    order_item_id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    order_id INTEGER REFERENCES orders(order_id),
    product_id INTEGER NOT NULL REFERENCES products(product_id) ON DELETE CASCADE, -- При удалении товара удаляются связанные позиции в заказах
    quantity INTEGER NOT NULL,
    base_price_at_purchase NUMERIC(12,2) NOT NULL
);

-- Таблица отзывов на товары
CREATE TABLE reviews (
    review_id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    product_id INTEGER NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE SET NULL, -- Если пользователь удалён, сохраняем отзыв, но без привязки к пользователю
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    helpful_count INTEGER DEFAULT 0,
    UNIQUE (product_id, user_id) -- Один пользователь может оставить только один отзыв на товар
);

-- Таблица для хранения товаров, добавленных в корзину пользователями
CREATE TABLE cart_items (
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    added_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, product_id) -- Один товар может быть добавлен в корзину пользователем только один раз
);

-- Таблица для хранения информации о платежах, связанных с заказами
CREATE TABLE payments (
    payment_id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    order_id INTEGER NOT NULL REFERENCES orders(order_id),
    amount NUMERIC(12,2) NOT NULL,
    amount_in_base NUMERIC(12,2) NOT NULL, -- Сумма в базовой валюте, для удобства отчетности
    method VARCHAR(50) NOT NULL CHECK (method IN ('card', 'paypal', 'invoice')),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed')),
    transaction_id VARCHAR(100),
    paid_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE exchange_rates (
    rate_id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    from_currency CHAR(3) NOT NULL,
    to_currency CHAR(3) NOT NULL,
    rate NUMERIC(18, 6) NOT NULL,        -- Курс: 1 RUB = сколько-то EUR
    valid_from TIMESTAMPTZ NOT NULL DEFAULT NOW(), -- Когда этот курс начал действовать
    valid_until TIMESTAMPTZ,             -- NULL означает 'действует сейчас'
    created_at TIMESTAMPTZ DEFAULT NOW() -- Когда этот курс был добавлен в базу
);

ALTER TABLE exchange_rates
ADD CONSTRAINT fk_exchange_rates_from_currency
FOREIGN KEY (from_currency) REFERENCES currencies(code);

ALTER TABLE exchange_rates
ADD CONSTRAINT fk_exchange_rates_to_currency
FOREIGN KEY (to_currency) REFERENCES currencies(code);

CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_shipping_address ON orders(shipping_address_id);
CREATE INDEX idx_orders_billing_address ON orders(billing_address_id);
CREATE INDEX idx_orders_created_at ON orders(created_at);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
CREATE INDEX idx_reviews_product_id ON reviews(product_id);
CREATE INDEX idx_reviews_user_id ON reviews(user_id);
CREATE INDEX idx_products_category_id ON products(category_id);
CREATE INDEX idx_product_images_product_id ON product_images(product_id);
CREATE INDEX idx_user_addresses_user_id ON user_addresses(user_id);
CREATE INDEX idx_product_attributes_product_id ON product_attributes(product_id);
CREATE INDEX idx_categories_parent ON categories(parent_category_id);
CREATE INDEX idx_payments_order_id ON payments(order_id);
CREATE INDEX idx_exchange_rates_lookup ON exchange_rates (from_currency, to_currency, valid_from);
CREATE UNIQUE INDEX idx_user_addresses_default ON user_addresses (user_id) WHERE is_default = TRUE;


--- Задание валют и триггеров
UPDATE currencies SET is_base = FALSE;

INSERT INTO currencies (code, name, symbol, is_base)
VALUES ('RUB', 'Russian Ruble', '₽', TRUE)
ON CONFLICT (code) DO UPDATE SET is_base = TRUE;

UPDATE currencies SET is_base = FALSE WHERE code <> 'RUB';

INSERT INTO currencies (code, name, symbol, is_base)
VALUES 
    ('EUR', 'Euro', '€', FALSE),
    ('USD', 'US Dollar', '$', FALSE)
ON CONFLICT (code) DO NOTHING;



-- Вставляем исторические курсы (например, с начала сегодняшнего дня)
-- Курсы: 1 RUB = 0.010 EUR, 1 RUB = 0.011 USD (примерные значения)
-- INSERT INTO exchange_rates (from_currency, to_currency, rate, valid_from, valid_until)
-- VALUES 
--     ('RUB', 'EUR', 0.010, CURRENT_DATE, NULL),
--     ('RUB', 'USD', 0.011, CURRENT_DATE, NULL)
-- ON CONFLICT DO NOTHING;



-- Функция-проверки одной базовой валюты
CREATE OR REPLACE FUNCTION check_single_base_currency()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_base THEN
        -- Если новое значение TRUE, сбрасываем флаг у всех остальных
        UPDATE currencies SET is_base = FALSE WHERE code <> NEW.code;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- Триггер на INSERT/UPDATE
CREATE TRIGGER trigger_single_base_currency
BEFORE INSERT OR UPDATE OF is_base ON currencies
FOR EACH ROW
EXECUTE FUNCTION check_single_base_currency();

-- Функция пересчёта суммы заказа
CREATE OR REPLACE FUNCTION update_order_total()
RETURNS TRIGGER AS $$
BEGIN
    -- Обновляем total_amount_in_base в таблице orders
    UPDATE orders
    SET total_amount_in_base = (
        SELECT COALESCE(SUM(quantity * base_price_at_purchase), 0)
        FROM order_items
        WHERE order_id = NEW.order_id
    )
    WHERE order_id = NEW.order_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- Триггер на INSERT/UPDATE/DELETE в order_items
CREATE TRIGGER trigger_update_order_total
AFTER INSERT OR UPDATE OR DELETE ON order_items
FOR EACH ROW
EXECUTE FUNCTION update_order_total();



-- Функция для установки amount_in_base в таблице payments (платежы) при вставке новой записи
CREATE OR REPLACE FUNCTION set_payment_amount_in_base()
RETURNS TRIGGER AS $$
DECLARE
    order_exch_rate NUMERIC(12,6);
BEGIN
    -- Получаем курс из заказа
    SELECT exchange_rate_at_purchase INTO order_exch_rate
    FROM orders WHERE order_id = NEW.order_id;
    -- Если курс не NULL, вычисляем сумму в базовой валюте
    IF order_exch_rate IS NOT NULL THEN
        NEW.amount_in_base := NEW.amount / order_exch_rate;
    ELSE
        -- Если курс не задан (например, заказ в базовой валюте), считаем amount = amount_in_base
        NEW.amount_in_base := NEW.amount;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- Триггер BEFORE INSERT
CREATE TRIGGER trigger_set_payment_amount_in_base
BEFORE INSERT ON payments
FOR EACH ROW
EXECUTE FUNCTION set_payment_amount_in_base();



--- Триггер для обеспечения одного основного адреса на пользователя
CREATE OR REPLACE function set_default_address()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_default THEN
        UPDATE user_addresses SET is_default = FALSE
        WHERE user_id = NEW.user_id AND address_id <> NEW.address_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_single_default_address
BEFORE INSERT OR UPDATE OF is_default ON user_addresses
FOR EACH ROW
EXECUTE FUNCTION set_default_address();




-- SELECT rate
-- FROM exchange_rates
-- WHERE from_currency = 'USD'   -- базовая валюта
--   AND to_currency = 'EUR'     -- валюта клиента
--   AND valid_from <= NOW()
--   AND (valid_until IS NULL OR valid_until > NOW())
-- ORDER BY valid_from DESC
-- LIMIT 1;

