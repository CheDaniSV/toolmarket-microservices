
-- Заполнение БД категориями инструментов и товарами (стиль McMaster-Carr)
-- Скрипт можно запускать повторно — используются ON CONFLICT DO NOTHING

-- 1. Категории
INSERT INTO categories (parent_category_id, name) VALUES
  (NULL, 'Инструменты'),
  (NULL, 'Крепёж')
ON CONFLICT (name) DO NOTHING;

-- Подкатегории первого уровня
WITH root AS (
  SELECT category_id, name FROM categories WHERE name IN ('Инструменты', 'Крепёж')
)
INSERT INTO categories (parent_category_id, name)
SELECT root.category_id, sub.name
FROM root
CROSS JOIN (VALUES
  ('Ручные инструменты'),
  ('Электроинструменты'),
  ('Измерительные инструменты'),
  ('Слесарный инструмент')
) AS sub(name)
WHERE root.name = 'Инструменты'
ON CONFLICT (name) DO NOTHING;

WITH root AS (
  SELECT category_id, name FROM categories WHERE name = 'Крепёж'
)
INSERT INTO categories (parent_category_id, name)
SELECT root.category_id, sub.name
FROM root
CROSS JOIN (VALUES
  ('Болты'),
  ('Гайки'),
  ('Шайбы'),
  ('Винты')
) AS sub(name)
ON CONFLICT (name) DO NOTHING;

-- Подкатегории второго уровня (привязываем к родительским подкатегориям по имени)
INSERT INTO categories (parent_category_id, name)
SELECT parent.category_id, child.name
FROM (VALUES
  ('Ручные инструменты', 'Отвёртки'),
  ('Ручные инструменты', 'Гаечные ключи'),
  ('Ручные инструменты', 'Плоскогубцы'),
  ('Электроинструменты', 'Дрели'),
  ('Электроинструменты', 'Шлифмашины'),
  ('Измерительные инструменты', 'Рулетки'),
  ('Измерительные инструменты', 'Штангенциркули'),
  ('Слесарный инструмент', 'Молотки'),
  ('Болты', 'Болты с шестигранной головкой'),
  ('Болты', 'Болты с потайной головкой'),
  ('Гайки', 'Шестигранные гайки'),
  ('Шайбы', 'Плоские шайбы'),
  ('Шайбы', 'Пружинные шайбы'),
  ('Винты', 'Саморезы')
) AS child(parent_name, name)
JOIN categories parent ON parent.name = child.parent_name
ON CONFLICT (name) DO NOTHING;

-- 2. Товары
-- Все цены в базовой валюте (RUB)

-- Отвёртки
INSERT INTO products (sku, name, description, base_price, stock, category_id)
SELECT 'SCREW-PH2-150', 'Отвёртка крестовая PH2×150 мм', 
       'Профессиональная крестовая отвёртка с магнитным наконечником и двухкомпонентной рукояткой.',
       450.00, 120, cat.category_id
FROM categories cat WHERE cat.name = 'Отвёртки'
ON CONFLICT (sku) DO NOTHING;

INSERT INTO products (sku, name, description, base_price, stock, category_id)
SELECT 'SCREW-FLAT-4x100', 'Отвёртка плоская 4×100 мм', 
       'Плоская отвёртка с хром-ванадиевым стержнем и эргономичной рукояткой.',
       320.00, 85, cat.category_id
FROM categories cat WHERE cat.name = 'Отвёртки'
ON CONFLICT (sku) DO NOTHING;

-- Гаечные ключи
INSERT INTO products (sku, name, description, base_price, stock, category_id)
SELECT 'WRENCH-COMBO-13', 'Ключ комбинированный 13 мм', 
       'Рожково-накидной ключ из хром-ванадиевой стали, размер 13 мм.',
       280.00, 200, cat.category_id
FROM categories cat WHERE cat.name = 'Гаечные ключи'
ON CONFLICT (sku) DO NOTHING;

-- Дрели
INSERT INTO products (sku, name, description, base_price, stock, category_id)
SELECT 'DRILL-CORDLESS-18V', 'Дрель аккумуляторная 18 В', 
       'Бесщёточная аккумуляторная дрель-шуруповёрт, 2 аккумулятора 2.0 Ач, крутящий момент 60 Нм.',
       8900.00, 30, cat.category_id
FROM categories cat WHERE cat.name = 'Дрели'
ON CONFLICT (sku) DO NOTHING;

-- Рулетки
INSERT INTO products (sku, name, description, base_price, stock, category_id)
SELECT 'TAPE-5M', 'Рулетка 5 м × 19 мм', 
       'Измерительная рулетка с магнитным зацепом, класс точности II, автостоп.',
       590.00, 150, cat.category_id
FROM categories cat WHERE cat.name = 'Рулетки'
ON CONFLICT (sku) DO NOTHING;

-- Штангенциркули
INSERT INTO products (sku, name, description, base_price, stock, category_id)
SELECT 'CALIPER-DIG-150', 'Штангенциркуль цифровой 150 мм', 
       'Цифровой штангенциркуль с точностью 0.01 мм, нержавеющая сталь, автовыключение.',
       1450.00, 45, cat.category_id
FROM categories cat WHERE cat.name = 'Штангенциркули'
ON CONFLICT (sku) DO NOTHING;

-- Молотки
INSERT INTO products (sku, name, description, base_price, stock, category_id)
SELECT 'HAMMER-500G', 'Молоток слесарный 500 г', 
       'Молоток с фибергласовой рукояткой, головка из кованой стали.',
       650.00, 70, cat.category_id
FROM categories cat WHERE cat.name = 'Молотки'
ON CONFLICT (sku) DO NOTHING;

-- Болты с шестигранной головкой
INSERT INTO products (sku, name, description, base_price, stock, category_id)
SELECT 'BOLT-HEX-M8x30', 'Болт с шестигранной головкой M8×30', 
       'Болт с частичной резьбой, класс прочности 8.8, оцинкованная сталь.',
       12.50, 1000, cat.category_id
FROM categories cat WHERE cat.name = 'Болты с шестигранной головкой'
ON CONFLICT (sku) DO NOTHING;

INSERT INTO products (sku, name, description, base_price, stock, category_id)
SELECT 'BOLT-HEX-M10x40', 'Болт с шестигранной головкой M10×40', 
       'Болт с полной резьбой, класс прочности 10.9, нержавеющая сталь A2.',
       18.00, 800, cat.category_id
FROM categories cat WHERE cat.name = 'Болты с шестигранной головкой'
ON CONFLICT (sku) DO NOTHING;

-- Гайки
INSERT INTO products (sku, name, description, base_price, stock, category_id)
SELECT 'NUT-HEX-M8', 'Гайка шестигранная M8', 
       'Гайка шестигранная, класс прочности 8, оцинкованная сталь.',
       5.00, 1500, cat.category_id
FROM categories cat WHERE cat.name = 'Шестигранные гайки'
ON CONFLICT (sku) DO NOTHING;

-- Шайбы
INSERT INTO products (sku, name, description, base_price, stock, category_id)
SELECT 'WASHER-FLAT-M8', 'Шайба плоская M8', 
       'Плоская шайба, оцинкованная сталь, DIN 125.',
       2.50, 2000, cat.category_id
FROM categories cat WHERE cat.name = 'Плоские шайбы'
ON CONFLICT (sku) DO NOTHING;

INSERT INTO products (sku, name, description, base_price, stock, category_id)
SELECT 'WASHER-SPRING-M8', 'Шайба пружинная M8', 
       'Пружинная шайба (гровер), сталь 65Г, без покрытия.',
       3.80, 1800, cat.category_id
FROM categories cat WHERE cat.name = 'Пружинные шайбы'
ON CONFLICT (sku) DO NOTHING;

-- Саморезы
INSERT INTO products (sku, name, description, base_price, stock, category_id)
SELECT 'SCREW-SELF-4x25', 'Саморез 4×25 мм', 
       'Саморез по дереву с потайной головкой, фосфатированный, крестообразный шлиц.',
       0.90, 5000, cat.category_id
FROM categories cat WHERE cat.name = 'Саморезы'
ON CONFLICT (sku) DO NOTHING;

-- 3. Характеристики товаров (product_attributes)
-- Используем подзапросы для получения product_id по SKU

-- Отвёртка крестовая PH2×150 мм
INSERT INTO product_attributes (product_id, attr_name, attr_value)
SELECT p.product_id, attr.*
FROM products p, (VALUES
  ('Тип наконечника', 'Phillips PH2'),
  ('Длина стержня', '150 мм'),
  ('Материал стержня', 'Хром-ванадиевая сталь'),
  ('Материал рукоятки', 'Двухкомпонентный пластик/резина'),
  ('Магнитный наконечник', 'Да')
) AS attr(attr_name, attr_value)
WHERE p.sku = 'SCREW-PH2-150'
ON CONFLICT (product_id, attr_name) DO NOTHING;

-- Отвёртка плоская 4×100 мм
INSERT INTO product_attributes (product_id, attr_name, attr_value)
SELECT p.product_id, attr.*
FROM products p, (VALUES
  ('Тип наконечника', 'Плоский 4 мм'),
  ('Длина стержня', '100 мм'),
  ('Материал стержня', 'Хром-ванадиевая сталь'),
  ('Материал рукоятки', 'Эргономичный термопластик')
) AS attr(attr_name, attr_value)
WHERE p.sku = 'SCREW-FLAT-4x100'
ON CONFLICT (product_id, attr_name) DO NOTHING;

-- Ключ комбинированный 13 мм
INSERT INTO product_attributes (product_id, attr_name, attr_value)
SELECT p.product_id, attr.*
FROM products p, (VALUES
  ('Размер', '13 мм'),
  ('Тип', 'Комбинированный (рожковый + накидной)'),
  ('Материал', 'Хром-ванадиевая сталь'),
  ('Покрытие', 'Хромированное')
) AS attr(attr_name, attr_value)
WHERE p.sku = 'WRENCH-COMBO-13'
ON CONFLICT (product_id, attr_name) DO NOTHING;

-- Дрель аккумуляторная 18 В
INSERT INTO product_attributes (product_id, attr_name, attr_value)
SELECT p.product_id, attr.*
FROM products p, (VALUES
  ('Напряжение', '18 В'),
  ('Тип двигателя', 'Бесщёточный'),
  ('Крутящий момент', '60 Нм'),
  ('Ёмкость аккумулятора', '2.0 Ач × 2 шт'),
  ('Тип патрона', 'Быстрозажимной 13 мм'),
  ('Число скоростей', '2'),
  ('Вес', '1.8 кг')
) AS attr(attr_name, attr_value)
WHERE p.sku = 'DRILL-CORDLESS-18V'
ON CONFLICT (product_id, attr_name) DO NOTHING;

-- Рулетка 5 м × 19 мм
INSERT INTO product_attributes (product_id, attr_name, attr_value)
SELECT p.product_id, attr.*
FROM products p, (VALUES
  ('Длина', '5 м'),
  ('Ширина ленты', '19 мм'),
  ('Класс точности', 'II'),
  ('Зацеп', 'Магнитный'),
  ('Автостоп', 'Да'),
  ('Материал корпуса', 'Ударопрочный АБС-пластик')
) AS attr(attr_name, attr_value)
WHERE p.sku = 'TAPE-5M'
ON CONFLICT (product_id, attr_name) DO NOTHING;

-- Штангенциркуль цифровой 150 мм
INSERT INTO product_attributes (product_id, attr_name, attr_value)
SELECT p.product_id, attr.*
FROM products p, (VALUES
  ('Диапазон измерений', '0–150 мм'),
  ('Точность', '0.01 мм'),
  ('Материал', 'Нержавеющая сталь'),
  ('Питание', 'LR44'),
  ('Автовыключение', 'Да'),
  ('Дисплей', 'ЖК-дисплей')
) AS attr(attr_name, attr_value)
WHERE p.sku = 'CALIPER-DIG-150'
ON CONFLICT (product_id, attr_name) DO NOTHING;

-- Молоток слесарный 500 г
INSERT INTO product_attributes (product_id, attr_name, attr_value)
SELECT p.product_id, attr.*
FROM products p, (VALUES
  ('Вес головки', '500 г'),
  ('Материал головки', 'Кованая сталь'),
  ('Материал рукоятки', 'Фиберглас'),
  ('Длина рукоятки', '320 мм'),
  ('Виброгасящее покрытие', 'Да')
) AS attr(attr_name, attr_value)
WHERE p.sku = 'HAMMER-500G'
ON CONFLICT (product_id, attr_name) DO NOTHING;

-- Болт M8×30
INSERT INTO product_attributes (product_id, attr_name, attr_value)
SELECT p.product_id, attr.*
FROM products p, (VALUES
  ('Диаметр резьбы', 'M8'),
  ('Шаг резьбы', '1.25 мм'),
  ('Длина', '30 мм'),
  ('Тип головки', 'Шестигранная'),
  ('Класс прочности', '8.8'),
  ('Материал', 'Оцинкованная сталь'),
  ('Тип резьбы', 'Частичная')
) AS attr(attr_name, attr_value)
WHERE p.sku = 'BOLT-HEX-M8x30'
ON CONFLICT (product_id, attr_name) DO NOTHING;

-- Болт M10×40
INSERT INTO product_attributes (product_id, attr_name, attr_value)
SELECT p.product_id, attr.*
FROM products p, (VALUES
  ('Диаметр резьбы', 'M10'),
  ('Шаг резьбы', '1.5 мм'),
  ('Длина', '40 мм'),
  ('Тип головки', 'Шестигранная'),
  ('Класс прочности', '10.9'),
  ('Материал', 'Нержавеющая сталь A2'),
  ('Тип резьбы', 'Полная')
) AS attr(attr_name, attr_value)
WHERE p.sku = 'BOLT-HEX-M10x40'
ON CONFLICT (product_id, attr_name) DO NOTHING;

-- Гайка M8
INSERT INTO product_attributes (product_id, attr_name, attr_value)
SELECT p.product_id, attr.*
FROM products p, (VALUES
  ('Диаметр резьбы', 'M8'),
  ('Тип', 'Шестигранная'),
  ('Класс прочности', '8'),
  ('Материал', 'Оцинкованная сталь')
) AS attr(attr_name, attr_value)
WHERE p.sku = 'NUT-HEX-M8'
ON CONFLICT (product_id, attr_name) DO NOTHING;

-- Шайба плоская M8
INSERT INTO product_attributes (product_id, attr_name, attr_value)
SELECT p.product_id, attr.*
FROM products p, (VALUES
  ('Внутренний диаметр', '8.4 мм'),
  ('Наружный диаметр', '16 мм'),
  ('Толщина', '1.6 мм'),
  ('Материал', 'Оцинкованная сталь'),
  ('Стандарт', 'DIN 125')
) AS attr(attr_name, attr_value)
WHERE p.sku = 'WASHER-FLAT-M8'
ON CONFLICT (product_id, attr_name) DO NOTHING;

-- Шайба пружинная M8
INSERT INTO product_attributes (product_id, attr_name, attr_value)
SELECT p.product_id, attr.*
FROM products p, (VALUES
  ('Диаметр', 'M8'),
  ('Тип', 'Пружинная (гровер)'),
  ('Материал', 'Сталь 65Г'),
  ('Покрытие', 'Без покрытия')
) AS attr(attr_name, attr_value)
WHERE p.sku = 'WASHER-SPRING-M8'
ON CONFLICT (product_id, attr_name) DO NOTHING;

-- Саморез 4×25 мм
INSERT INTO product_attributes (product_id, attr_name, attr_value)
SELECT p.product_id, attr.*
FROM products p, (VALUES
  ('Диаметр', '4 мм'),
  ('Длина', '25 мм'),
  ('Тип головки', 'Потайная'),
  ('Шлиц', 'Крестообразный (PH)'),
  ('Материал', 'Сталь, фосфатированный'),
  ('Применение', 'По дереву')
) AS attr(attr_name, attr_value)
WHERE p.sku = 'SCREW-SELF-4x25'
ON CONFLICT (product_id, attr_name) DO NOTHING;

-- 4. Изображения товаров (product_images)
-- Используем заглушки, чтобы обозначить наличие картинок

-- INSERT INTO product_images (product_id, image_url, image_order)
-- SELECT p.product_id, img.url, img.order
-- FROM products p, (VALUES
--   ('SCREW-PH2-150',   '/images/products/screwdriver_ph2_150_01.jpg', 0),
--   ('SCREW-PH2-150',   '/images/products/screwdriver_ph2_150_02.jpg', 1),
--   ('SCREW-FLAT-4x100','/images/products/screwdriver_flat_4x100.jpg', 0),
--   ('WRENCH-COMBO-13', '/images/products/wrench_13_01.jpg', 0),
--   ('DRILL-CORDLESS-18V','/images/products/drill_18v_01.jpg', 0),
--   ('DRILL-CORDLESS-18V','/images/products/drill_18v_02.jpg', 1),
--   ('TAPE-5M',         '/images/products/tape_5m.jpg', 0),
--   ('CALIPER-DIG-150', '/images/products/caliper_digital_150.jpg', 0),
--   ('HAMMER-500G',     '/images/products/hammer_500g.jpg', 0),
--   ('BOLT-HEX-M8x30',  '/images/products/bolt_m8x30.jpg', 0),
--   ('BOLT-HEX-M10x40', '/images/products/bolt_m10x40.jpg', 0),
--   ('NUT-HEX-M8',      '/images/products/nut_m8.jpg', 0),
--   ('WASHER-FLAT-M8',  '/images/products/washer_flat_m8.jpg', 0),
--   ('WASHER-SPRING-M8','/images/products/washer_spring_m8.jpg', 0),
--   ('SCREW-SELF-4x25', '/images/products/screw_self_4x25.jpg', 0)
-- ) AS img(sku, url, "order")
-- WHERE p.sku = img.sku
-- ON CONFLICT (product_id, image_order) DO NOTHING;