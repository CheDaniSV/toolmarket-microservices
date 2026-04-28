-- =====================================================
-- Дополнительные товары для тестирования (большой объём)
-- Категории не изменяются – используются существующие
-- =====================================================

-- =====================================================
-- 1. Дополнительные товары в категории «Ручные инструменты»
-- =====================================================

-- Плоскогубцы (категория уже есть)
INSERT INTO products (sku, name, description, base_price, stock, category_id)
SELECT 'PLIERS-COMBO-200', 'Плоскогубцы комбинированные 200 мм', 
       'Комбинированные плоскогубцы с зоной для захвата труб, индукционная закалка губок.',
       890.00, 110, cat.category_id
FROM categories cat WHERE cat.name = 'Плоскогубцы'
ON CONFLICT (sku) DO NOTHING;

INSERT INTO products (sku, name, description, base_price, stock, category_id)
SELECT 'PLIERS-NEEDLE-160', 'Плоскогубцы узкогубочные 160 мм', 
       'Узкогубочные плоскогубцы с изогнутыми губками, длинные губки для точных работ.',
       720.00, 65, cat.category_id
FROM categories cat WHERE cat.name = 'Плоскогубцы'
ON CONFLICT (sku) DO NOTHING;

-- Гаечные ключи – добавляем ещё размеры и типы
INSERT INTO products (sku, name, description, base_price, stock, category_id)
SELECT 'WRENCH-COMBO-17', 'Ключ комбинированный 17 мм', 
       'Рожково-накидной ключ 17 мм, хром-ванадий, матовое хромирование.',
       350.00, 180, cat.category_id
FROM categories cat WHERE cat.name = 'Гаечные ключи'
ON CONFLICT (sku) DO NOTHING;

INSERT INTO products (sku, name, description, base_price, stock, category_id)
SELECT 'WRENCH-ADJ-250', 'Разводной ключ 250 мм (зев до 30 мм)', 
       'Разводной ключ с точной подводкой губок, шкала размера.',
       1250.00, 55, cat.category_id
FROM categories cat WHERE cat.name = 'Гаечные ключи'
ON CONFLICT (sku) DO NOTHING;

-- Отвёртки – набор бит и прецизионная
INSERT INTO products (sku, name, description, base_price, stock, category_id)
SELECT 'SCREW-SET-32', 'Набор бит 32 предмета', 
       'Набор сменных бит PH, PZ, SL, Torx, Hex в пластиковом кейсе.',
       1850.00, 40, cat.category_id
FROM categories cat WHERE cat.name = 'Отвёртки'
ON CONFLICT (sku) DO NOTHING;

INSERT INTO products (sku, name, description, base_price, stock, category_id)
SELECT 'SCREW-PREC-6', 'Отвёртка прецизионная 6-в-1', 
       'Набор сменных наконечников для мелкого ремонта (смартфоны, часы).',
       650.00, 95, cat.category_id
FROM categories cat WHERE cat.name = 'Отвёртки'
ON CONFLICT (sku) DO NOTHING;

-- =====================================================
-- 2. Электроинструменты
-- =====================================================

-- Шлифмашины (категория уже есть)
INSERT INTO products (sku, name, description, base_price, stock, category_id)
SELECT 'SANDER-OSC-300W', 'Шлифмашина вибрационная 300 Вт', 
       'Вибрационная шлифмашина с пылеотводом, размер подошвы 187×92 мм.',
       3450.00, 25, cat.category_id
FROM categories cat WHERE cat.name = 'Шлифмашины'
ON CONFLICT (sku) DO NOTHING;

INSERT INTO products (sku, name, description, base_price, stock, category_id)
SELECT 'SANDER-BELT-850W', 'Ленточная шлифмашина 850 Вт', 
       'Ленточная шлифмашина с регулировкой скорости, лента 75×533 мм.',
       6750.00, 12, cat.category_id
FROM categories cat WHERE cat.name = 'Шлифмашины'
ON CONFLICT (sku) DO NOTHING;

-- Дрели – ещё одна модель
INSERT INTO products (sku, name, description, base_price, stock, category_id)
SELECT 'DRILL-IMPACT-12V', 'Аккумуляторная ударная дрель 12 В', 
       'Компактная ударная дрель-шуруповёрт, светодиодная подсветка, патрон 10 мм.',
       5900.00, 42, cat.category_id
FROM categories cat WHERE cat.name = 'Дрели'
ON CONFLICT (sku) DO NOTHING;

-- =====================================================
-- 3. Измерительные инструменты
-- =====================================================

-- Рулетки – другая длина
INSERT INTO products (sku, name, description, base_price, stock, category_id)
SELECT 'TAPE-8M', 'Рулетка 8 м × 25 мм', 
       'Рулетка с двухсторонней шкалой, клипса на поясе, класс точности II.',
       820.00, 130, cat.category_id
FROM categories cat WHERE cat.name = 'Рулетки'
ON CONFLICT (sku) DO NOTHING;

-- Штангенциркуль механический
INSERT INTO products (sku, name, description, base_price, stock, category_id)
SELECT 'CALIPER-MECH-150', 'Штангенциркуль механический 150 мм', 
       'Нониус 0.05 мм, закалённая сталь, глубомер.',
       890.00, 60, cat.category_id
FROM categories cat WHERE cat.name = 'Штангенциркули'
ON CONFLICT (sku) DO NOTHING;

-- Угольник (добавим новую категорию? Нет, в существующих нет – пропустим. Но можно добавить в "Измерительные инструменты" – она есть)
-- Создадим угольник, но это допустимо, так как категория "Измерительные инструменты" существует.
INSERT INTO products (sku, name, description, base_price, stock, category_id)
SELECT 'SQUARE-300', 'Угольник поверочный 300 мм', 
       'Угольник лекальный, класс точности 2, из нержавеющей стали.',
       1050.00, 30, cat.category_id
FROM categories cat WHERE cat.name = 'Измерительные инструменты'
ON CONFLICT (sku) DO NOTHING;

-- Микрометр
INSERT INTO products (sku, name, description, base_price, stock, category_id)
SELECT 'MICRO-25', 'Микрометр гладкий 0-25 мм', 
       'Микрометр с классом точности 1, трещотка, стопорный винт.',
       2150.00, 18, cat.category_id
FROM categories cat WHERE cat.name = 'Измерительные инструменты'
ON CONFLICT (sku) DO NOTHING;

-- =====================================================
-- 4. Слесарный инструмент
-- =====================================================

-- Напильники (в подкатегории "Слесарный инструмент" – добавляем)
INSERT INTO products (sku, name, description, base_price, stock, category_id)
SELECT 'FILE-FLAT-200', 'Напильник плоский 200 мм (№3)', 
       'Напильник для слесарных работ, насечка №3, хвостовик для рукоятки.',
       340.00, 85, cat.category_id
FROM categories cat WHERE cat.name = 'Слесарный инструмент'
ON CONFLICT (sku) DO NOTHING;

INSERT INTO products (sku, name, description, base_price, stock, category_id)
SELECT 'FILE-ROUND-150', 'Надфиль круглый 150 мм (№5)', 
       'Надфиль для тонкой обработки, мелкая насечка, диаметр 4 мм.',
       190.00, 120, cat.category_id
FROM categories cat WHERE cat.name = 'Слесарный инструмент'
ON CONFLICT (sku) DO NOTHING;

-- Зубило
INSERT INTO products (sku, name, description, base_price, stock, category_id)
SELECT 'CHISEL-200', 'Зубило слесарное 200 мм', 
       'Зубило с ударной головкой, ширина рабочей части 20 мм, кованая сталь.',
       480.00, 45, cat.category_id
FROM categories cat WHERE cat.name = 'Слесарный инструмент'
ON CONFLICT (sku) DO NOTHING;

-- =====================================================
-- 5. Крепёж – дополнительные товары
-- =====================================================

-- Болты с потайной головкой (категория есть, но товаров не было)
INSERT INTO products (sku, name, description, base_price, stock, category_id)
SELECT 'BOLT-FLAT-M6x20', 'Болт с потайной головкой M6×20', 
       'Дин 7991, неполная резьба, оцинкованная сталь, класс прочности 8.8.',
       8.50, 2500, cat.category_id
FROM categories cat WHERE cat.name = 'Болты с потайной головкой'
ON CONFLICT (sku) DO NOTHING;

INSERT INTO products (sku, name, description, base_price, stock, category_id)
SELECT 'BOLT-FLAT-M8x25', 'Болт с потайной головкой M8×25', 
       'Полная резьба, нержавеющая сталь A2, класс прочности 70.',
       14.90, 1200, cat.category_id
FROM categories cat WHERE cat.name = 'Болты с потайной головкой'
ON CONFLICT (sku) DO NOTHING;

-- Шестигранные гайки – добавим M10 и M12
INSERT INTO products (sku, name, description, base_price, stock, category_id)
SELECT 'NUT-HEX-M10', 'Гайка шестигранная M10', 
       'Гайка DIN 934, класс прочности 8, оцинкованная сталь.',
       7.20, 2000, cat.category_id
FROM categories cat WHERE cat.name = 'Шестигранные гайки'
ON CONFLICT (sku) DO NOTHING;

INSERT INTO products (sku, name, description, base_price, stock, category_id)
SELECT 'NUT-HEX-M12', 'Гайка шестигранная M12', 
       'Гайка DIN 934, класс прочности 10, без покрытия.',
       12.00, 1500, cat.category_id
FROM categories cat WHERE cat.name = 'Шестигранные гайки'
ON CONFLICT (sku) DO NOTHING;

-- Гайки-барашки (добавим в ту же категорию "Гайки" – но там уже есть "Шестигранные гайки", создадим новую подкатегорию? Нельзя, т.к. категории менять нельзя. Поэтому просто добавим в существующую подкатегорию "Гайки" (которая является родительской для "Шестигранные гайки"? Нет, по структуре: Крепёж -> Гайки -> Шестигранные гайки. У нас есть категория "Гайки" (средний уровень) и "Шестигранные гайки" (дочерняя). Добавим в "Гайки" напрямую? Лучше не нарушать. Создадим новый товар в "Шестигранные гайки", но он не будет барашком. Для барашка нужна отдельная подкатегория – по условию нельзя менять категории. Поэтому пропускаем барашки.)

-- Шайбы плоские других размеров
INSERT INTO products (sku, name, description, base_price, stock, category_id)
SELECT 'WASHER-FLAT-M10', 'Шайба плоская M10', 
       'Шайба DIN 125, оцинкованная сталь, внутренний 10.5 мм, наружный 20 мм, толщина 2 мм.',
       4.50, 3000, cat.category_id
FROM categories cat WHERE cat.name = 'Плоские шайбы'
ON CONFLICT (sku) DO NOTHING;

INSERT INTO products (sku, name, description, base_price, stock, category_id)
SELECT 'WASHER-FLAT-M12', 'Шайба плоская M12', 
       'Шайба DIN 125, нержавеющая сталь A2, толщина 2.5 мм.',
       7.80, 1800, cat.category_id
FROM categories cat WHERE cat.name = 'Плоские шайбы'
ON CONFLICT (sku) DO NOTHING;

-- Пружинные шайбы под M10 и M6
INSERT INTO products (sku, name, description, base_price, stock, category_id)
SELECT 'WASHER-SPRING-M6', 'Шайба пружинная M6', 
       'Гровер DIN 127, сталь 65Г, без покрытия, для M6.',
       2.20, 4000, cat.category_id
FROM categories cat WHERE cat.name = 'Пружинные шайбы'
ON CONFLICT (sku) DO NOTHING;

INSERT INTO products (sku, name, description, base_price, stock, category_id)
SELECT 'WASHER-SPRING-M10', 'Шайба пружинная M10', 
       'Гровер DIN 127, оцинкованная сталь, для предохранения от самоотвинчивания.',
       5.60, 2200, cat.category_id
FROM categories cat WHERE cat.name = 'Пружинные шайбы'
ON CONFLICT (sku) DO NOTHING;

-- Саморезы разных размеров
INSERT INTO products (sku, name, description, base_price, stock, category_id)
SELECT 'SCREW-SELF-3.5x16', 'Саморез 3.5×16 мм', 
       'Саморез по дереву, потайная головка, крест PH2, фосфатированный.',
       0.60, 8000, cat.category_id
FROM categories cat WHERE cat.name = 'Саморезы'
ON CONFLICT (sku) DO NOTHING;

INSERT INTO products (sku, name, description, base_price, stock, category_id)
SELECT 'SCREW-SELF-4.5x50', 'Саморез 4.5×50 мм (универсальный)', 
       'Саморез с бочкообразной резьбой, буроватый наконечник, для металла и дерева.',
       2.30, 3500, cat.category_id
FROM categories cat WHERE cat.name = 'Саморезы'
ON CONFLICT (sku) DO NOTHING;

-- Винты (добавим в категорию "Винты" – она существует)
INSERT INTO products (sku, name, description, base_price, stock, category_id)
SELECT 'SCREW-MACHINE-M3x10', 'Винт M3×10 с потайной головкой', 
       'Винт DIN 965, нержавеющая сталь A2, крест PH0, полная резьба.',
       1.20, 5000, cat.category_id
FROM categories cat WHERE cat.name = 'Винты'
ON CONFLICT (sku) DO NOTHING;

INSERT INTO products (sku, name, description, base_price, stock, category_id)
SELECT 'SCREW-MACHINE-M4x16', 'Винт M4×16 с полукруглой головкой', 
       'Винт DIN 85, оцинкованная сталь, крест PH2, частичная резьба.',
       1.80, 4000, cat.category_id
FROM categories cat WHERE cat.name = 'Винты'
ON CONFLICT (sku) DO NOTHING;

-- =====================================================
-- 6. Характеристики для новых товаров
-- =====================================================

-- Плоскогубцы комбинированные
INSERT INTO product_attributes (product_id, attr_name, attr_value)
SELECT p.product_id, attr.*
FROM products p, (VALUES
  ('Длина', '200 мм'),
  ('Материал', 'Хром-ванадиевая сталь'),
  ('Обработка губок', 'Индукционная закалка'),
  ('Зона для захвата труб', 'Да'),
  ('Резак для проволоки', 'Да'),
  ('Покрытие', 'Матовый хром')
) AS attr(attr_name, attr_value)
WHERE p.sku = 'PLIERS-COMBO-200'
ON CONFLICT (product_id, attr_name) DO NOTHING;

-- Плоскогубцы узкогубочные
INSERT INTO product_attributes (product_id, attr_name, attr_value)
SELECT p.product_id, attr.*
FROM products p, (VALUES
  ('Длина', '160 мм'),
  ('Форма губок', 'Изогнутые узкие'),
  ('Материал', 'Сталь Cr-V'),
  ('Применение', 'Для ювелирных и электронных работ')
) AS attr(attr_name, attr_value)
WHERE p.sku = 'PLIERS-NEEDLE-160'
ON CONFLICT (product_id, attr_name) DO NOTHING;

-- Ключ комбинированный 17 мм
INSERT INTO product_attributes (product_id, attr_name, attr_value)
SELECT p.product_id, attr.*
FROM products p, (VALUES
  ('Размер', '17 мм'),
  ('Тип', 'Комбинированный'),
  ('Материал', 'Хром-ванадий'),
  ('Покрытие', 'Матовое хромирование')
) AS attr(attr_name, attr_value)
WHERE p.sku = 'WRENCH-COMBO-17'
ON CONFLICT (product_id, attr_name) DO NOTHING;

-- Разводной ключ
INSERT INTO product_attributes (product_id, attr_name, attr_value)
SELECT p.product_id, attr.*
FROM products p, (VALUES
  ('Длина', '250 мм'),
  ('Макс. зев', '30 мм'),
  ('Точность разводки', 'Шкала в мм'),
  ('Материал', 'Инструментальная сталь')
) AS attr(attr_name, attr_value)
WHERE p.sku = 'WRENCH-ADJ-250'
ON CONFLICT (product_id, attr_name) DO NOTHING;

-- Набор бит 32 пр.
INSERT INTO product_attributes (product_id, attr_name, attr_value)
SELECT p.product_id, attr.*
FROM products p, (VALUES
  ('Количество предметов', '32'),
  ('Типы бит', 'PH, PZ, SL, Torx, Hex'),
  ('Материал', 'S2 сталь'),
  ('Магнитный держатель', 'Да'),
  ('Кейс', 'Пластиковый')
) AS attr(attr_name, attr_value)
WHERE p.sku = 'SCREW-SET-32'
ON CONFLICT (product_id, attr_name) DO NOTHING;

-- Отвёртка прецизионная
INSERT INTO product_attributes (product_id, attr_name, attr_value)
SELECT p.product_id, attr.*
FROM products p, (VALUES
  ('Тип', 'Сменные наконечники (6 шт)'),
  ('Размеры наконечников', 'PH0, PH00, SL1.5, SL2.0, T5, T6'),
  ('Материал рукоятки', 'Алюминий + резиновые вставки'),
  ('Вращающийся колпачок', 'Да')
) AS attr(attr_name, attr_value)
WHERE p.sku = 'SCREW-PREC-6'
ON CONFLICT (product_id, attr_name) DO NOTHING;

-- Шлифмашина вибрационная
INSERT INTO product_attributes (product_id, attr_name, attr_value)
SELECT p.product_id, attr.*
FROM products p, (VALUES
  ('Мощность', '300 Вт'),
  ('Размер подошвы', '187×92 мм'),
  ('Колебания', '20000 об/мин'),
  ('Пылеотвод', 'Да, с адаптером под пылесос'),
  ('Регулировка скорости', 'Плавная'),
  ('Вес', '1.4 кг')
) AS attr(attr_name, attr_value)
WHERE p.sku = 'SANDER-OSC-300W'
ON CONFLICT (product_id, attr_name) DO NOTHING;

-- Ленточная шлифмашина
INSERT INTO product_attributes (product_id, attr_name, attr_value)
SELECT p.product_id, attr.*
FROM products p, (VALUES
  ('Мощность', '850 Вт'),
  ('Размер ленты', '75×533 мм'),
  ('Скорость ленты', '150-350 м/мин'),
  ('Регулировка центровки ленты', 'Да'),
  ('Мешок для пыли', 'В комплекте')
) AS attr(attr_name, attr_value)
WHERE p.sku = 'SANDER-BELT-850W'
ON CONFLICT (product_id, attr_name) DO NOTHING;

-- Ударная дрель 12В
INSERT INTO product_attributes (product_id, attr_name, attr_value)
SELECT p.product_id, attr.*
FROM products p, (VALUES
  ('Напряжение', '12 В'),
  ('Тип патрона', 'Быстрозажимной 10 мм'),
  ('Макс. крутящий момент', '30 Нм'),
  ('Ударный режим', 'Да (до 6000 уд/мин)'),
  ('Подсветка', 'Светодиодная'),
  ('Вес без аккумулятора', '0.9 кг')
) AS attr(attr_name, attr_value)
WHERE p.sku = 'DRILL-IMPACT-12V'
ON CONFLICT (product_id, attr_name) DO NOTHING;

-- Рулетка 8 м
INSERT INTO product_attributes (product_id, attr_name, attr_value)
SELECT p.product_id, attr.*
FROM products p, (VALUES
  ('Длина', '8 м'),
  ('Ширина ленты', '25 мм'),
  ('Класс точности', 'II'),
  ('Двухсторонняя шкала', 'Да'),
  ('Клипса на поясе', 'Да')
) AS attr(attr_name, attr_value)
WHERE p.sku = 'TAPE-8M'
ON CONFLICT (product_id, attr_name) DO NOTHING;

-- Штангенциркуль механический
INSERT INTO product_attributes (product_id, attr_name, attr_value)
SELECT p.product_id, attr.*
FROM products p, (VALUES
  ('Диапазон', '0-150 мм'),
  ('Погрешность', '0.05 мм'),
  ('Материал', 'Закалённая сталь'),
  ('Наличие глубиномера', 'Да'),
  ('Нониус', 'Механический')
) AS attr(attr_name, attr_value)
WHERE p.sku = 'CALIPER-MECH-150'
ON CONFLICT (product_id, attr_name) DO NOTHING;

-- Угольник 300 мм
INSERT INTO product_attributes (product_id, attr_name, attr_value)
SELECT p.product_id, attr.*
FROM products p, (VALUES
  ('Длина', '300 мм'),
  ('Класс точности', '2'),
  ('Материал', 'Нержавеющая сталь'),
  ('Тип', 'Лекальный')
) AS attr(attr_name, attr_value)
WHERE p.sku = 'SQUARE-300'
ON CONFLICT (product_id, attr_name) DO NOTHING;

-- Микрометр 0-25 мм
INSERT INTO product_attributes (product_id, attr_name, attr_value)
SELECT p.product_id, attr.*
FROM products p, (VALUES
  ('Диапазон', '0-25 мм'),
  ('Цена деления', '0.01 мм'),
  ('Трещотка', 'Да'),
  ('Стопорный винт', 'Да'),
  ('Класс точности', '1')
) AS attr(attr_name, attr_value)
WHERE p.sku = 'MICRO-25'
ON CONFLICT (product_id, attr_name) DO NOTHING;

-- Напильник плоский
INSERT INTO product_attributes (product_id, attr_name, attr_value)
SELECT p.product_id, attr.*
FROM products p, (VALUES
  ('Длина рабочей части', '200 мм'),
  ('Насечка', '№3 (средняя)'),
  ('Материал', 'Углеродистая сталь U8A'),
  ('Хвостовик', 'Для рукоятки')
) AS attr(attr_name, attr_value)
WHERE p.sku = 'FILE-FLAT-200'
ON CONFLICT (product_id, attr_name) DO NOTHING;

-- Надфиль круглый
INSERT INTO product_attributes (product_id, attr_name, attr_value)
SELECT p.product_id, attr.*
FROM products p, (VALUES
  ('Длина', '150 мм'),
  ('Диаметр', '4 мм'),
  ('Насечка', '№5 (мелкая)'),
  ('Применение', 'Для доводочных работ')
) AS attr(attr_name, attr_value)
WHERE p.sku = 'FILE-ROUND-150'
ON CONFLICT (product_id, attr_name) DO NOTHING;

-- Зубило
INSERT INTO product_attributes (product_id, attr_name, attr_value)
SELECT p.product_id, attr.*
FROM products p, (VALUES
  ('Длина', '200 мм'),
  ('Ширина режущей кромки', '20 мм'),
  ('Материал', 'Кованая сталь 40Х'),
  ('Термообработка', 'Закалка HRC 50-55')
) AS attr(attr_name, attr_value)
WHERE p.sku = 'CHISEL-200'
ON CONFLICT (product_id, attr_name) DO NOTHING;

-- Болт с потайной головкой M6x20
INSERT INTO product_attributes (product_id, attr_name, attr_value)
SELECT p.product_id, attr.*
FROM products p, (VALUES
  ('Диаметр резьбы', 'M6'),
  ('Шаг резьбы', '1.0 мм'),
  ('Длина', '20 мм'),
  ('Тип головки', 'Потайная (DIN 7991)'),
  ('Класс прочности', '8.8'),
  ('Материал', 'Оцинкованная сталь'),
  ('Тип резьбы', 'Неполная')
) AS attr(attr_name, attr_value)
WHERE p.sku = 'BOLT-FLAT-M6x20'
ON CONFLICT (product_id, attr_name) DO NOTHING;

-- Болт с потайной головкой M8x25
INSERT INTO product_attributes (product_id, attr_name, attr_value)
SELECT p.product_id, attr.*
FROM products p, (VALUES
  ('Диаметр резьбы', 'M8'),
  ('Шаг резьбы', '1.25 мм'),
  ('Длина', '25 мм'),
  ('Тип головки', 'Потайная'),
  ('Класс прочности', '70 (нерж)'),
  ('Материал', 'Нержавеющая сталь A2'),
  ('Тип резьбы', 'Полная')
) AS attr(attr_name, attr_value)
WHERE p.sku = 'BOLT-FLAT-M8x25'
ON CONFLICT (product_id, attr_name) DO NOTHING;

-- Гайки M10, M12
INSERT INTO product_attributes (product_id, attr_name, attr_value)
SELECT p.product_id, attr.*
FROM products p, (VALUES
  ('Диаметр резьбы', 'M10'),
  ('Тип', 'Шестигранная'),
  ('Класс прочности', '8'),
  ('Стандарт', 'DIN 934'),
  ('Материал', 'Оцинкованная сталь')
) AS attr(attr_name, attr_value)
WHERE p.sku = 'NUT-HEX-M10'
ON CONFLICT (product_id, attr_name) DO NOTHING;

INSERT INTO product_attributes (product_id, attr_name, attr_value)
SELECT p.product_id, attr.*
FROM products p, (VALUES
  ('Диаметр резьбы', 'M12'),
  ('Тип', 'Шестигранная'),
  ('Класс прочности', '10'),
  ('Стандарт', 'DIN 934'),
  ('Материал', 'Сталь без покрытия')
) AS attr(attr_name, attr_value)
WHERE p.sku = 'NUT-HEX-M12'
ON CONFLICT (product_id, attr_name) DO NOTHING;

-- Шайбы плоские M10, M12
INSERT INTO product_attributes (product_id, attr_name, attr_value)
SELECT p.product_id, attr.*
FROM products p, (VALUES
  ('Внутренний диаметр', '10.5 мм'),
  ('Наружный диаметр', '20 мм'),
  ('Толщина', '2.0 мм'),
  ('Материал', 'Оцинкованная сталь'),
  ('Стандарт', 'DIN 125')
) AS attr(attr_name, attr_value)
WHERE p.sku = 'WASHER-FLAT-M10'
ON CONFLICT (product_id, attr_name) DO NOTHING;

INSERT INTO product_attributes (product_id, attr_name, attr_value)
SELECT p.product_id, attr.*
FROM products p, (VALUES
  ('Внутренний диаметр', '13.0 мм'),
  ('Наружный диаметр', '24 мм'),
  ('Толщина', '2.5 мм'),
  ('Материал', 'Нержавеющая сталь A2'),
  ('Стандарт', 'DIN 125')
) AS attr(attr_name, attr_value)
WHERE p.sku = 'WASHER-FLAT-M12'
ON CONFLICT (product_id, attr_name) DO NOTHING;

-- Пружинные шайбы M6, M10
INSERT INTO product_attributes (product_id, attr_name, attr_value)
SELECT p.product_id, attr.*
FROM products p, (VALUES
  ('Диаметр', 'M6'),
  ('Тип', 'Пружинная (гровер)'),
  ('Материал', 'Сталь 65Г'),
  ('Покрытие', 'Без покрытия'),
  ('Стандарт', 'DIN 127')
) AS attr(attr_name, attr_value)
WHERE p.sku = 'WASHER-SPRING-M6'
ON CONFLICT (product_id, attr_name) DO NOTHING;

INSERT INTO product_attributes (product_id, attr_name, attr_value)
SELECT p.product_id, attr.*
FROM products p, (VALUES
  ('Диаметр', 'M10'),
  ('Тип', 'Пружинная (гровер)'),
  ('Материал', 'Оцинкованная сталь'),
  ('Стандарт', 'DIN 127')
) AS attr(attr_name, attr_value)
WHERE p.sku = 'WASHER-SPRING-M10'
ON CONFLICT (product_id, attr_name) DO NOTHING;

-- Саморезы 3.5x16 и 4.5x50
INSERT INTO product_attributes (product_id, attr_name, attr_value)
SELECT p.product_id, attr.*
FROM products p, (VALUES
  ('Диаметр', '3.5 мм'),
  ('Длина', '16 мм'),
  ('Тип головки', 'Потайная'),
  ('Шлиц', 'PH2'),
  ('Материал', 'Фосфатированная сталь'),
  ('Применение', 'По дереву')
) AS attr(attr_name, attr_value)
WHERE p.sku = 'SCREW-SELF-3.5x16'
ON CONFLICT (product_id, attr_name) DO NOTHING;

INSERT INTO product_attributes (product_id, attr_name, attr_value)
SELECT p.product_id, attr.*
FROM products p, (VALUES
  ('Диаметр', '4.5 мм'),
  ('Длина', '50 мм'),
  ('Тип головки', 'Потайная с крестообразным шлицем'),
  ('Наконечник', 'Буравчик (self-drilling)'),
  ('Материал', 'Закалённая сталь с покрытием'),
  ('Применение', 'Универсальный (дерево+металл до 2 мм)')
) AS attr(attr_name, attr_value)
WHERE p.sku = 'SCREW-SELF-4.5x50'
ON CONFLICT (product_id, attr_name) DO NOTHING;

-- Винты M3x10 и M4x16
INSERT INTO product_attributes (product_id, attr_name, attr_value)
SELECT p.product_id, attr.*
FROM products p, (VALUES
  ('Диаметр резьбы', 'M3'),
  ('Длина', '10 мм'),
  ('Тип головки', 'Потайная (DIN 965)'),
  ('Материал', 'Нержавеющая сталь A2'),
  ('Шлиц', 'PH0'),
  ('Тип резьбы', 'Полная')
) AS attr(attr_name, attr_value)
WHERE p.sku = 'SCREW-MACHINE-M3x10'
ON CONFLICT (product_id, attr_name) DO NOTHING;

INSERT INTO product_attributes (product_id, attr_name, attr_value)
SELECT p.product_id, attr.*
FROM products p, (VALUES
  ('Диаметр резьбы', 'M4'),
  ('Длина', '16 мм'),
  ('Тип головки', 'Полукруглая (DIN 85)'),
  ('Материал', 'Оцинкованная сталь'),
  ('Шлиц', 'PH2'),
  ('Тип резьбы', 'Частичная')
) AS attr(attr_name, attr_value)
WHERE p.sku = 'SCREW-MACHINE-M4x16'
ON CONFLICT (product_id, attr_name) DO NOTHING;

-- =====================================================
-- Конец скрипта
-- =====================================================