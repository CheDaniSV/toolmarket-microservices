-- Проверка существования расширений и создание при необходимости
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS http;

-- Функция для обновления курсов валют с fallback
CREATE OR REPLACE FUNCTION update_currency_rates()
RETURNS TEXT AS $$
DECLARE
    response_record RECORD;
    response_json JSONB;
    rub_rates JSONB;
    exchange_rate NUMERIC;
    target_currency_code CHAR(3);
    base_currency_code CHAR(3) := 'RUB';
    urls TEXT[] := ARRAY[
        'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/rub.json',
        'https://latest.currency-api.pages.dev/v1/currencies/rub.json'
    ];
    url TEXT;
    success BOOLEAN := FALSE;
BEGIN
    -- Перебираем URL-адреса до первого успешного
    FOREACH url IN ARRAY urls
    LOOP
        BEGIN
            -- Выполняем HTTP GET запрос
            SELECT * INTO response_record FROM http_get(url);
            -- Проверяем, что статус 200 OK и тело ответа не пустое
            IF response_record.status = 200 AND response_record.content IS NOT NULL THEN
                response_json := response_record.content::jsonb;
                -- Проверяем, что JSON содержит поле 'rub' с данными
                IF response_json ? 'rub' AND jsonb_typeof(response_json->'rub') = 'object' THEN
                    rub_rates := response_json -> 'rub';
                    success := TRUE;
                    EXIT; -- Выходим из цикла, данные получены
                END IF;
            END IF;
        EXCEPTION WHEN OTHERS THEN
            -- Логируем ошибку (можно через RAISE NOTICE) и продолжаем со следующим URL
            RAISE NOTICE 'Failed to fetch from %, error: %', url, SQLERRM;
        END;
    END LOOP;

    -- Если ни один URL не дал валидных данных
    IF NOT success OR rub_rates IS NULL THEN
        RETURN 'Error: Failed to fetch valid currency data from all available APIs';
    END IF;

    -- Обновляем курсы для каждой целевой валюты (кроме базовой)
    FOR target_currency_code IN
        SELECT code FROM currencies WHERE code != base_currency_code
    LOOP
        -- Получаем курс из JSON, ключ в нижнем регистре
        exchange_rate := (rub_rates->>lower(target_currency_code))::NUMERIC;

        IF exchange_rate IS NOT NULL THEN
            -- Закрываем предыдущий активный курс
            UPDATE exchange_rates
            SET valid_until = NOW()
            WHERE to_currency = target_currency_code
              AND from_currency = base_currency_code
              AND valid_until IS NULL;

            -- Вставляем новый курс
            INSERT INTO exchange_rates (from_currency, to_currency, rate, valid_from, valid_until)
            VALUES (base_currency_code, target_currency_code, exchange_rate, NOW(), NULL);
        END IF;
    END LOOP;

    RETURN 'Currency rates updated successfully using ' || url;
END;
$$ LANGUAGE plpgsql;

-- Обновляем один раз в ручную
SELECT update_currency_rates();

-- Планируем выполнение функции каждый час
SELECT cron.schedule(
    'update-currency-rates',      -- Уникальное имя задания
    '0 * * * *',                  -- Cron-выражение: каждый час в 0 минут
    'SELECT update_currency_rates();'
);