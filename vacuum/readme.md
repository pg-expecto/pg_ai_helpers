# PostgreSQL Table Administration Scripts

This directory contains two bash scripts for PostgreSQL administration:

1. `find_table.sh` – searches for databases containing a given table.
2. `vacuum_table.sh` – runs `VACUUM ANALYZE` on a given table across multiple databases.

Both scripts are designed to be run as the `postgres` user (or any user with sufficient privileges) and produce log files.

---

## English

### Requirements

- PostgreSQL (tested on version 17.7)
- `psql` in `PATH`
- Permissions to connect to databases and run `VACUUM` (typically the `postgres` user)

---

### Script 1: find_table.sh

#### Purpose
Finds all databases in the PostgreSQL cluster that contain a table with the specified name. The search is **case‑insensitive**. Output is written to a text file.

#### Syntax
```bash
./find_table.sh <table_name>
```

#### Arguments
| Argument | Description |
|----------|-------------|
| `table_name` | Name of the table to search for (can contain letters, digits, and underscores). |

#### Output
- A file named `databases_with_table_<table_name>.txt` containing a line‑separated list of databases where the table was found.
- The console displays either the list of found databases or a message that the table does not exist.

#### Example
```bash
sudo -u postgres ./find_table.sh "_table1"
```

**Example content of `databases_with_table__table1.txt`:**
```
db1
db2
db3
```

---

### Script 2: vacuum_table.sh

#### Purpose
Runs `VACUUM (VERBOSE, ANALYZE)` on the specified table in all databases listed in a text file. A detailed log file is created. The script automatically determines the actual table name (respecting case) and its schema.

#### Syntax
```bash
./vacuum_table.sh <table_name> <database_list_file>
```

#### Arguments
| Argument | Description |
|----------|-------------|
| `table_name` | Name of the table to vacuum (case‑insensitive). |
| `database_list_file` | Path to a text file containing one database name per line. |

#### Output
- A log file named `vacuum_analyze_<table_name>_YYYYMMDD_HHMMSS.log` containing:
  - Start and end timestamps.
  - For each database: existence check, the `VACUUM` command executed, and its output (including errors).
- The log file name is printed to the console upon completion.

#### Example

**`databases_list.txt`**
```
db1
db2
```

**Run**
```bash
sudo -u postgres ./vacuum_table.sh "_table1" databases_list.txt
```

**Log file snippet (`vacuum_analyze__table1_20260327_105103.log`):**
```
=== Start Fri Mar 27 10:51:03 AM MSK 2026 ===
Table: _table1
Database list: databases_list.txt
================================
----------------------------------------
Database: db1
Executing: VACUUM (VERBOSE, ANALYZE) "public"."_table1";
INFO:  vacuuming "public._table1"
INFO:  scanned index "_table1_1" to remove 0 row versions
...
Result: SUCCESS
================================
=== End Fri Mar 27 10:51:05 AM MSK 2026 ===
```

---

### Notes

#### Table name case sensitivity
- If a table was created **without quotes**, PostgreSQL folds the name to lower case. For example, `CREATE TABLE MyTable ...` creates a table named `mytable`.
- If created **with quotes**, the name is case‑sensitive, e.g., `CREATE TABLE "MyTable" ...`.
- Both scripts search case‑insensitively, so you can provide the name in any case. `vacuum_table.sh` additionally retrieves the real name and schema from the catalog to execute `VACUUM` correctly.

#### Special characters
The scripts automatically escape single quotes in the table name. Database names in the list file must be written without quotes, one per line.

#### Permissions
The executing user must be able to connect to all databases and perform:
- `SELECT` from `information_schema.tables`
- `VACUUM` on the target table (typically allowed for the table owner or a superuser).

#### Logging
- Result files are created in the current directory. File names include the table name and a timestamp to prevent overwriting.
- Running `find_table.sh` again does not delete previous results; a new file with a fresh timestamp is created.

---

## Русский

### Требования

- PostgreSQL (тестировалось на версии 17.7)
- Утилита `psql` в `PATH`
- Права на подключение к базам данных и выполнение `VACUUM` (обычно пользователь `postgres`)

---

### Скрипт 1: find_table.sh

#### Назначение
Находит все базы данных в кластере PostgreSQL, в которых существует таблица с указанным именем. Поиск выполняется **без учёта регистра**. Результат выводится в текстовый файл.

#### Синтаксис
```bash
./find_table.sh <имя_таблицы>
```

#### Аргументы
| Аргумент | Описание |
|----------|----------|
| `имя_таблицы` | Имя искомой таблицы (может содержать буквы в любом регистре, цифры и символ `_`). |

#### Выходные данные
- Файл с именем `databases_with_table_<имя_таблицы>.txt`, содержащий построчный список баз данных, где таблица найдена.
- На экран выводится либо список найденных баз, либо сообщение об отсутствии таблицы.

#### Пример
```bash
sudo -u postgres ./find_table.sh "_table1"
```

**Пример содержимого файла `databases_with_table__table1.txt`:**
```
db1
db2
db3
```

---

### Скрипт 2: vacuum_table.sh

#### Назначение
Выполняет `VACUUM (VERBOSE, ANALYZE)` для указанной таблицы во всех базах данных, перечисленных в текстовом файле. Протокол выполнения записывается в детальный лог-файл. Скрипт автоматически определяет реальное имя таблицы (с учётом регистра) и схему, в которой она находится.

#### Синтаксис
```bash
./vacuum_table.sh <имя_таблицы> <файл_со_списком_БД>
```

#### Аргументы
| Аргумент | Описание |
|----------|----------|
| `имя_таблицы` | Имя таблицы для выполнения `VACUUM ANALYZE` (регистр не важен). |
| `файл_со_списком_БД` | Путь к текстовому файлу, в котором каждая строка содержит имя базы данных. |

#### Выходные данные
- Файл лога с именем `vacuum_analyze_<имя_таблицы>_YYYYMMDD_HHMMSS.log`, содержащий:
  - Начало и окончание выполнения с временными метками.
  - Для каждой базы: результат проверки существования таблицы, команду `VACUUM` и её вывод (включая ошибки).
- На экран выводится имя файла лога по окончании работы.

#### Пример

**Файл `databases_list.txt`:**
```
db1
db2
```

**Запуск:**
```bash
sudo -u postgres ./vacuum_table.sh "_table1" databases_list.txt
```

**Фрагмент лог-файла (`vacuum_analyze__table1_20260327_105103.log`):**
```
=== Начало выполнения Fri Mar 27 10:51:03 AM MSK 2026 ===
Таблица: _table1
Список БД: databases_list.txt
================================
----------------------------------------
База данных: db1
Выполнение: VACUUM (VERBOSE, ANALYZE) "public"."_table1";
INFO:  vacuuming "public._table1"
INFO:  scanned index "_table1_1" to remove 0 row versions
...
Результат: УСПЕШНО
================================
=== Окончание выполнения Fri Mar 27 10:51:05 AM MSK 2026 ===
```

---

### Примечания

#### Регистр имён таблиц
- Если таблица создавалась **без кавычек**, PostgreSQL автоматически приводит её имя к нижнему регистру. Например, команда `CREATE TABLE MyTable ...` создаст таблицу с именем `mytable`.
- Если таблица создавалась **с кавычками**, имя сохраняется с учётом регистра, например `CREATE TABLE "MyTable" ...`.
- Оба скрипта выполняют поиск без учёта регистра, поэтому достаточно указать имя в любом удобном регистре. Скрипт `vacuum_table.sh` дополнительно извлекает реальное имя и схему из каталога, чтобы корректно выполнить `VACUUM`.

#### Экранирование специальных символов
Скрипты автоматически экранируют одинарные кавычки в имени таблицы. Имена баз данных в файле должны быть указаны без кавычек, по одному на строку.

#### Права доступа
Пользователь, запускающий скрипты, должен иметь возможность подключаться ко всем базам данных и выполнять:
- `SELECT` из `information_schema.tables`
- `VACUUM` для целевой таблицы (обычно это доступно владельцу таблицы или суперпользователю).

#### Логирование
- Все скрипты создают файлы с результатами в текущей директории. Имена файлов включают имя таблицы и временную метку, что предотвращает случайное перезаписывание.
- При повторном запуске `find_table.sh` предыдущий результат не удаляется, а создаётся новый файл с актуальной меткой времени.

---

## License / Лицензия

This project is distributed under the **MIT License**.  
See the [LICENSE](../LICENSE) file for details.

Данный проект распространяется под лицензией **MIT**.  
Подробности см. в файле [LICENSE](../LICENSE).
