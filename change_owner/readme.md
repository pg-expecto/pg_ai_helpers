# Скрипт смены владельца объектов базы данных PostgreSQL

Скрипт `change_owner.sql` позволяет сменить владельца всех объектов (схем, таблиц, представлений, материализованных представлений, последовательностей, функций и процедур) в указанной базе данных PostgreSQL. Новый владелец передаётся как параметр, что делает скрипт универсальным и безопасным.

## Возможности

- Смена владельца **несистемных схем** (исключая `pg_catalog`, `information_schema`, `public`, `pg_toast` и другие служебные схемы).
- Смена владельца для:
  - таблиц (`TABLE`),
  - представлений (`VIEW`),
  - материализованных представлений (`MATERIALIZED VIEW`),
  - последовательностей (`SEQUENCE`),
  - функций и процедур (`FUNCTION` / `PROCEDURE`).
- Поддержка объектов, находящихся в любой несистемной схеме.
- Защита от SQL-инъекций с использованием экранирования идентификаторов и строк.
- Возможность запуска без изменения кода: все настройки передаются через параметры командной строки `psql`.

## Требования

- PostgreSQL 9.5+ (используется синтаксис `DO`, `pg_get_function_identity_arguments` и т.д.).
- Пользователь, запускающий скрипт, должен иметь права суперпользователя или права на смену владельца объектов (обычно требуется `SUPERUSER` или явное `OWNER TO`).
- Утилита `psql`, установленная и доступная в командной строке.

## Параметры

Скрипт ожидает два обязательных параметра, передаваемых через переменные `psql`:

| Параметр   | Описание |
|------------|----------|
| `dbname`   | Имя базы данных, в которой будет произведена смена владельца. |
| `new_owner`| Имя роли PostgreSQL, которая станет новым владельцем всех объектов. |

Если один из параметров не задан, скрипт завершится с сообщением об ошибке и кодом возврата 1.

## Использование

### Синтаксис запуска

```bash
psql -v dbname="имя_бд" -v new_owner="имя_роли" -f change_owner.sql
```

### Пример

Допустим, необходимо сменить владельца всех объектов в базе данных `production_db` на роль `app_owner`:

```bash
psql -v dbname=production_db -v new_owner=app_owner -f change_owner.sql
```

### Запуск с авторизацией

Если требуется указать имя пользователя и пароль, используйте стандартные опции `psql`:

```bash
psql -U admin -h localhost -v dbname=production_db -v new_owner=app_owner -f change_owner.sql
```

После ввода пароля скрипт выполнится и выведет сообщение об успешном завершении.

## Примечания

- Скрипт **не изменяет** владельца объектов в схемах `pg_catalog`, `information_schema`, `public`, `pg_toast` и схемах, начинающихся с `pg_`, так как это может нарушить работу сервера.
- Для функций и процедур учитываются их сигнатуры (аргументы), что позволяет корректно изменять владельца даже для перегруженных функций.
- При выполнении скрипта все изменения фиксируются автоматически (в рамках одной транзакции, так как `DO` выполняется в транзакции).
- Если какой-либо объект уже принадлежит новому владельцу, команда `ALTER ... OWNER TO` не вызовет ошибку, но может выдать предупреждение (зависит от настройки `client_min_messages`).
- Для успешной смены владельца у функций и процедур необходимо, чтобы новая роль имела право `USAGE` на схему, в которой находится функция, а также (при необходимости) права на типы аргументов.

## Пример вывода

```
Смена владельца успешно завершена.
```
---

# Ниже приведена инструкция по созданию тестовой базы данных PostgreSQL объёмом около 100 МБ, наполнению её объектами и проверке корректности работы скрипта смены владельца (`change_owner.sql`).

---

## Цель

Создать тестовую среду, в которой можно безопасно проверить, что скрипт `change_owner.sql` корректно меняет владельца всех поддерживаемых типов объектов (схемы, таблицы, представления, материализованные представления, последовательности, функции, процедуры) на указанную роль.

---

## Предварительные требования

- Установленный PostgreSQL (версия 9.6 или выше, предпочтительно 12+).
- Пользователь с правами суперпользователя (например, `postgres`) или правами на создание баз данных и ролей.
- Файл скрипта `change_owner.sql` (содержимое предоставлено) в доступной директории.

---

## 1. Создание ролей и базы данных

Выполните следующие команды от имени суперпользователя (например, `postgres`), используя `psql` или любой клиент.

```sql
-- Создаём роль, которая будет исходным владельцем объектов (для наглядности)
CREATE ROLE original_owner LOGIN;

-- Создаём роль, которая станет новым владельцем после выполнения скрипта
CREATE ROLE new_owner LOGIN;

-- Создаём тестовую базу данных с владельцем original_owner
CREATE DATABASE test_db OWNER original_owner;

-- Подключаемся к новой базе для дальнейших операций
\c test_db
```

**Примечание:** В реальной среде роли уже могут существовать; главное, чтобы роль, указанная в параметре `new_owner`, была создана до выполнения скрипта.

---

## 2. Наполнение базы объектами и данными до ~100 МБ

В этом разделе мы создадим различные объекты (схемы, таблицы, представления, функции и т.д.) и наполним таблицы данными, чтобы общий размер базы достиг примерно 100 МБ.

### 2.1 Создание пользовательской схемы

```sql
CREATE SCHEMA test_schema;
```

### 2.2 Создание таблиц с данными

Создадим несколько таблиц, одна из которых будет содержать большое количество строк для достижения нужного размера.

**Таблица с большими текстовыми полями** (основной вклад в размер):

```sql
CREATE TABLE test_schema.large_table (
    id SERIAL PRIMARY KEY,
    random_text TEXT,
    created_at TIMESTAMP DEFAULT now()
);

-- Вставим 500 000 строк, каждая с текстом переменной длины (в среднем 200 байт)
INSERT INTO test_schema.large_table (random_text)
SELECT
    md5(random()::text) || repeat('x', (random() * 100)::int)  -- генерируем строки длиной ~32+переменная часть
FROM generate_series(1, 500000);
```

**Дополнительная таблица**:

```sql
CREATE TABLE test_schema.small_table (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    value INTEGER
);

INSERT INTO test_schema.small_table (name, value)
SELECT 'item_' || i, (random() * 1000)::int
FROM generate_series(1, 10000) AS i;
```

### 2.3 Создание представлений

```sql
CREATE VIEW test_schema.large_view AS
SELECT id, random_text, created_at
FROM test_schema.large_table
WHERE created_at > '2023-01-01';

CREATE VIEW test_schema.small_view AS
SELECT id, name, value
FROM test_schema.small_table
WHERE value > 500;
```

### 2.4 Создание материализованного представления

```sql
CREATE MATERIALIZED VIEW test_schema.matview AS
SELECT
    date_trunc('day', created_at) AS day,
    COUNT(*) AS cnt
FROM test_schema.large_table
GROUP BY date_trunc('day', created_at);
```

### 2.5 Создание последовательности

```sql
CREATE SEQUENCE test_schema.my_seq;
```

### 2.6 Создание функций и процедуры

**Функция**:

```sql
CREATE OR REPLACE FUNCTION test_schema.calc_total(p_id INTEGER)
RETURNS INTEGER AS $$
DECLARE
    total INTEGER;
BEGIN
    SELECT SUM(value) INTO total
    FROM test_schema.small_table
    WHERE id <= p_id;
    RETURN total;
END;
$$ LANGUAGE plpgsql;
```

**Процедура** (PostgreSQL 11+):

```sql
CREATE OR REPLACE PROCEDURE test_schema.update_small_table(p_id INTEGER, p_value INTEGER)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE test_schema.small_table
    SET value = p_value
    WHERE id = p_id;
    COMMIT;
END;
$$;
```

### 2.7 Дополнительные объекты для проверки

- **Таблица в схеме public** (скрипт не должен менять владельца для public? по условию он исключает только системные схемы, public не исключён, значит владелец изменится).

```sql
CREATE TABLE public.public_table (
    id INTEGER
);
```

### 2.8 Проверка размера базы

```sql
SELECT
    pg_database_size('test_db') AS size_bytes,
    pg_size_pretty(pg_database_size('test_db')) AS size_pretty;
```

Если размер меньше 100 МБ, можно увеличить количество строк в `large_table` или добавить больше записей с длинными текстами. Для достижения ~100 МБ потребуется около 500–800 тысяч строк (в зависимости от длины текста). Указанные 500 тысяч должны дать примерно 100 МБ (каждая строка занимает ~200 байт + накладные расходы). Можно проверить и при необходимости добавить ещё.

---

## 3. Выполнение скрипта смены владельца

Теперь нужно выполнить `change_owner.sql`, передав параметры:

- `dbname` = имя базы данных (test_db)
- `new_owner` = имя роли, которая станет новым владельцем (new_owner)

**Важно:** Скрипт должен выполняться от имени пользователя, имеющего права на изменение владельца всех объектов (обычно суперпользователь или член роли с атрибутом `CREATEDB`/`CREATEROLE`). Для простоты используем `postgres`.

```bash
psql -v dbname=test_db -v new_owner=new_owner -f change_owner.sql
```

Если всё выполнено успешно, в конце будет выведено сообщение: `Смена владельца успешно завершена.`

---

## 4. Проверка корректности смены владельца

После выполнения скрипта убедимся, что все объекты, которые должны были сменить владельца, действительно принадлежат роли `new_owner`.

### 4.1 Проверка владельца схем

```sql
SELECT
    nspname AS schema_name,
    pg_catalog.pg_get_userbyid(nspowner) AS owner
FROM pg_catalog.pg_namespace
WHERE nspname NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
ORDER BY nspname;
```

Ожидаем, что для схем `public` и `test_schema` владельцем будет `new_owner`. (Исходный владелец был `original_owner`, но скрипт меняет все несистемные схемы.)

### 4.2 Проверка владельца таблиц, представлений, материализованных представлений, последовательностей

```sql
SELECT
    n.nspname AS schema_name,
    c.relname AS object_name,
    CASE c.relkind
        WHEN 'r' THEN 'table'
        WHEN 'v' THEN 'view'
        WHEN 'm' THEN 'materialized view'
        WHEN 'S' THEN 'sequence'
    END AS object_type,
    pg_catalog.pg_get_userbyid(c.relowner) AS owner
FROM pg_catalog.pg_class c
JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
  AND c.relkind IN ('r', 'v', 'm', 'S')
ORDER BY n.nspname, object_type, c.relname;
```

Все объекты из `test_schema` и `public` должны иметь владельца `new_owner`.

### 4.3 Проверка владельца функций и процедур

```sql
SELECT
    n.nspname AS schema_name,
    p.proname AS function_name,
    pg_catalog.pg_get_function_identity_arguments(p.oid) AS arguments,
    pg_catalog.pg_get_userbyid(p.proowner) AS owner
FROM pg_catalog.pg_proc p
JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
ORDER BY n.nspname, p.proname;
```

Ожидаем, что у функции `calc_total` и процедуры `update_small_table` владелец `new_owner`.

### 4.4 Проверка, что системные объекты не затронуты

Можно выборочно проверить несколько системных таблиц, например:

```sql
SELECT relname, relowner::regrole FROM pg_class WHERE relname = 'pg_class';
```

Владелец должен остаться `pg_database_owner` или суперпользователь, но точно не `new_owner`.

---

## 5. Дополнительные тесты

Если есть подозрения, что скрипт может пропустить какие-то объекты (например, объекты в схеме `public`), можно перед выполнением скрипта изменить владельца `public` на другого пользователя и проверить, что скрипт его перехватил.

Также можно создать объекты с именами, содержащими специальные символы, и убедиться, что кавычение в `format` корректно отрабатывает.

---

## Заключение

Данная инструкция позволяет развернуть тестовую базу данных объёмом ~100 МБ, содержащую все типы объектов, которые обрабатываются скриптом `change_owner.sql`, и проверить, что смена владельца происходит корректно. При необходимости размер базы можно увеличить, добавив больше строк в `large_table`.

После успешного выполнения теста тестовую базу можно удалить:

```sql
DROP DATABASE test_db;
DROP ROLE original_owner;
DROP ROLE new_owner;
```

## License / Лицензия

This project is distributed under the **MIT License**.  
See the [LICENSE](../LICENSE) file for details.

Данный проект распространяется под лицензией **MIT**.  
Подробности см. в файле [LICENSE](../LICENSE).

По вопросам, связанным со скриптом, обращайтесь к администратору вашей базы данных или к разработчику, предоставившему данный инструмент.
```
