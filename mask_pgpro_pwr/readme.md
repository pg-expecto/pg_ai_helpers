# mask_pgpro_pwr.sh – Postgres Pro HTML report anonymizer

---

## English

This script masks sensitive data in Postgres Pro performance reports (output of `pgpro_pwr`) to enable safe sharing and analysis. It replaces real database names, usernames, IP addresses, and SQL literals with anonymized aliases.

### Features

- **Database names** → `DB-1`, `DB-2`, … (order based on `pg_database` output)
- **Usernames** → `USER-1`, `USER-2`, … (order based on `pg_user` output)
- **IP addresses** (IPv4 and IPv6) → `ip`
- **SQL literals** (strings and numbers) → `?`

### Requirements

- **Postgres Pro** (or PostgreSQL) with the `psql` client installed and configured to connect to the target database.
- **GNU awk** (for correct word boundary handling) – usually installed by default on Linux.
- Standard Unix utilities: `bash`, `sed`, `mktemp`, `trap`.

### Usage

```bash
./mask_pgpro_pwr.sh input.html [output.html]
```

- `input.html` – source report file.
- `output.html` – (optional) output file name. Default: `masked_<input>`.

#### Example

```bash
./mask_pgpro_pwr.sh pgpro_pwr.9961-9962.mask.html masked_report.html
```

### How It Works

1. **Retrieve database list**  
   Runs `SELECT datname FROM pg_database` via `psql` and saves the result to `db.txt`.

2. **Retrieve user list**  
   Runs `SELECT usename FROM pg_user` via `psql` and saves the result to `user.txt`.

3. **Mask database names**  
   Uses `awk` to replace each database name in the HTML file with `DB-N` (where N is the index in the list). Replacement respects word boundaries (e.g., `BDC_prod` is replaced only as a whole word).

4. **Mask usernames**  
   Similarly replaces each username with `USER-N`.

5. **Mask IP addresses**  
   Uses `sed` to replace IPv4 and IPv6 addresses with the string `ip`.

6. **Mask SQL literals**  
   Uses `awk` to replace string literals (`'...'`) and numeric literals with `?` inside `<pre>` or `<code>` tags that have a class containing `sql`.

7. **Output file**  
   The masked report is written to the specified output file.

### Important Notes

- The script must be run on a machine that has access to the target Postgres Pro instance.  
  It uses the default `psql` connection settings (user, host, port). If needed, modify the `psql` commands (e.g., add `-h`, `-p`, `-U`).

- The script uses `mktemp` for temporary files and cleans them up on exit via `trap`.

- Word boundaries in `awk` are handled using `\y` (GNU awk). If you are using a different `awk` version, you may need to adjust the pattern (e.g., use `\<` and `\>` if supported).

- SQL literals are replaced only inside code blocks that have a class containing `sql` (e.g., `<pre class="sql ...">`). This prevents accidental replacements in plain text.

### Customization

The script can be easily extended to mask other identifiers (e.g., table names, index names) by following the same pattern:

1. Retrieve the list of objects via `psql`.
2. Add a masking function (similar to `mask_names`) that uses `awk` to replace each name with an alias.

Example for table names:

```bash
# Retrieve table list
psql -Atc "SELECT tablename FROM pg_tables WHERE schemaname = 'public'" > tables.txt

# Masking function (similar to mask_db_names, but with a different prefix)
mask_table_names() {
    awk -v file="$1" '...' "$2" > "$3"
}
```

---

## Русский

Скрипт маскирует чувствительные данные в отчётах о производительности Postgres Pro (вывод `pgpro_pwr`), чтобы обеспечить безопасный обмен и анализ. Он заменяет реальные имена баз данных, пользователей, IP-адреса и литералы SQL на обезличенные псевдонимы.

### Возможности

- **Имена баз данных** → `DB-1`, `DB-2`, ... (порядок на основе вывода `pg_database`)
- **Имена пользователей** → `USER-1`, `USER-2`, ... (порядок на основе вывода `pg_user`)
- **IP-адреса** (IPv4 и IPv6) → `ip`
- **Литералы SQL** (строки и числа) → `?`

### Требования

- **Postgres Pro** (или PostgreSQL) с установленным клиентом `psql`, настроенным для подключения к целевой базе данных.
- **GNU awk** (для корректной обработки границ слов) – обычно установлен в Linux по умолчанию.
- Стандартные утилиты Unix: `bash`, `sed`, `mktemp`, `trap`.

### Использование

```bash
./mask_pgpro_pwr.sh входной.html [выходной.html]
```

- `входной.html` – исходный файл отчёта.
- `выходной.html` – (необязательно) имя выходного файла. По умолчанию – `masked_<входной>`.

#### Пример

```bash
./mask_pgpro_pwr.sh pgpro_pwr.9961-9962.mask.html masked_report.html
```

### Как это работает

1. **Получение списка баз данных**  
   Выполняется `SELECT datname FROM pg_database` через `psql`, результат сохраняется в `db.txt`.

2. **Получение списка пользователей**  
   Выполняется `SELECT usename FROM pg_user` через `psql`, результат сохраняется в `user.txt`.

3. **Маскировка имён баз данных**  
   Используется `awk` для замены каждого имени базы данных в HTML-файле на `DB-N` (где N – порядковый номер в списке). Замена учитывает границы слов (например, `BDC_prod` заменяется только как целое слово).

4. **Маскировка имён пользователей**  
   Аналогично заменяет каждое имя пользователя на `USER-N`.

5. **Маскировка IP-адресов**  
   Используется `sed` для замены IPv4 и IPv6 адресов на строку `ip`.

6. **Маскировка литералов SQL**  
   Используется `awk` для замены строковых литералов (`'...'`) и числовых литералов на `?` внутри тегов `<pre>` или `<code>`, имеющих класс, содержащий `sql`.

7. **Выходной файл**  
   Маскированный отчёт записывается в указанный выходной файл.

### Важные замечания

- Скрипт должен выполняться на машине, имеющей доступ к целевому экземпляру Postgres Pro.  
  Подключение выполняется с настройками `psql` по умолчанию (пользователь, хост, порт). При необходимости можно изменить команду `psql` (например, добавить `-h`, `-p`, `-U`).

- Скрипт использует `mktemp` для временных файлов и очищает их при выходе через `trap`.

- Границы слов в `awk` обрабатываются с помощью `\y` (GNU awk). Если используется другая версия `awk`, возможно, потребуется изменить шаблон (например, использовать `\<` и `\>` при их поддержке).

- Литералы SQL заменяются только внутри блоков кода, имеющих класс, содержащий `sql` (например, `<pre class="sql ...">`). Это предотвращает случайные замены в обычном тексте.

### Настройка

Скрипт легко расширить для маскировки других идентификаторов (например, имён таблиц, индексов), следуя той же схеме:

1. Получить список объектов через `psql`.
2. Добавить функцию маскировки (аналогично `mask_names`), использующую `awk` для замены каждого имени на псевдоним.

Пример для имён таблиц:

```bash
# Получить список таблиц
psql -Atc "SELECT tablename FROM pg_tables WHERE schemaname = 'public'" > tables.txt

# Функция маскировки (аналогично mask_db_names, но с другим префиксом)
mask_table_names() {
    awk -v file="$1" '...' "$2" > "$3"
}
```

---

## License / Лицензия

This project is distributed under the **MIT License**.  
See the [LICENSE](../LICENSE) file for details.

Данный проект распространяется под лицензией **MIT**.  
Подробности см. в файле [LICENSE](../LICENSE).
