# compare.sh – Configuration file comparison tool

---

## English

This script compares two configuration files containing `key=value` pairs.  
It outputs lines where:

- a key exists in both files but values differ;
- a key exists only in the first file;
- a key exists only in the second file.

Output format:  
`key | value_from_first_file | value_from_second_file`

### Usage
```bash
./compare.sh file1 file2 [output_file]
```

### Parameters
- `file1` – path to the first file (required).
- `file2` – path to the second file (required).
- `output_file` – optional full path to a file where the result will be saved.  
  If omitted, the result is printed to stdout.  
  When an output file is specified, the script automatically sets its permissions to `777`.

### Input File Format
- Each non‑empty line must contain a `=` character separating the key and value.  
  Lines without `=` are ignored (a warning is printed to stderr).
- Comments:  
  - Lines starting with `#` are ignored entirely.  
  - Anything after a `#` character (including the `#`) is removed before processing, so inline comments are supported, e.g.:  
    `timeout=30  # seconds`
- Empty lines (or lines that become empty after comment removal) are skipped.
- If the same key appears multiple times, the last occurrence is used (order of keys that exist only in the second file is preserved based on the first occurrence).

### Output Format
- First line: `key | first_file_name | second_file_name` – header.
- Then, for each differing entry:
  - If the key exists in both files but with different values:  
    `key | value1 | value2`
  - If the key exists only in the first file:  
    `key | value1 | `
  - If the key exists only in the second file:  
    `key | | value2`

### Example
#### Create file1.txt
```bash
psql -Aqtc "select name||' = '||setting from pg_settings order by name" > /tmp/file1.txt
chmod 777 /tmp/file1.txt
```
#### Create file2.txt
```bash
psql -Aqtc "select name||' = '||setting from pg_settings order by name" > /tmp/file2.txt
chmod 777 /tmp/file2.txt
```
#### Run comparison
```bash
./compare.sh file1.txt file2.txt /tmp/settings.txt
```

### Notes
- The script uses associative arrays, so **bash 4.0 or higher** is required.
- On errors (e.g., missing input files), a message is printed to stderr and the script exits.
- Warnings about lines without `=` are sent to stderr and do not affect the result.
- The `777` permission is applied to the output file only when it is specified (even if the file already existed).

---

## Русский

Скрипт для сравнения двух файлов конфигурации в формате «ключ=значение».

### Назначение
Сравнивает два текстовых файла, содержащих пары `ключ=значение`.  
Выводит строки, в которых:
- ключ присутствует в обоих файлах, но значения отличаются;
- ключ есть только в первом файле;
- ключ есть только во втором файле.

Формат вывода:  
`ключ | значение_из_1го_файла | значение_из_2го_файла`

### Использование
```bash
./compare.sh файл1 файл2 [выходной_файл]
```

### Параметры
- `файл1` – путь к первому файлу (обязательный).
- `файл2` – путь ко второму файлу (обязательный).
- `выходной_файл` – необязательный параметр, полный путь к файлу для сохранения результата.  
  Если не указан, результат выводится на экран.  
  При указании файла скрипт автоматически устанавливает права доступа `777` на выходной файл.

### Формат входных файлов
- Каждая непустая строка должна содержать символ `=`, разделяющий ключ и значение.  
  Строки без `=` игнорируются с предупреждением в stderr.
- Комментарии:  
  - Строки, начинающиеся с `#`, полностью игнорируются.  
  - Часть строки после символа `#` (включая его) удаляется перед обработкой, поэтому можно использовать встроенные комментарии, например:  
    `timeout=30  # секунды`
- Пустые строки (или ставшие пустыми после удаления комментариев) пропускаются.
- Если один и тот же ключ встречается несколько раз, используется последнее значение (с сохранением порядка по первому вхождению для ключей, присутствующих только во втором файле).

### Формат вывода
- Первая строка: `ключ | имя_файла1 | имя_файла2` – заголовок.
- Затем для каждой отличающейся строки выводится:
  - если ключ есть в обоих файлах с разными значениями:  
    `ключ | значение1 | значение2`
  - если ключ только в первом файле:  
    `ключ | значение1 | `
  - если ключ только во втором файле:  
    `ключ | | значение2`

### Пример
#### Формирование file1.txt
```bash
psql -Aqtc "select name||' = '||setting from pg_settings order by name" > /tmp/file1.txt
chmod 777 /tmp/file1.txt
```
#### Формирование file2.txt
```bash
psql -Aqtc "select name||' = '||setting from pg_settings order by name" > /tmp/file2.txt
chmod 777 /tmp/file2.txt
```
#### Формирование результата
```bash
./compare.sh file1.txt file2.txt /tmp/settings.txt
```

### Примечания
- Скрипт использует ассоциативные массивы bash, поэтому требуется **версия bash 4.0 или выше**.
- При ошибках (например, отсутствие входных файлов) выводится сообщение в stderr и скрипт завершается.
- Все предупреждения о строках без `=` выводятся в stderr, не влияя на результат.
- Права `777` на выходной файл устанавливаются только если файл был указан (даже если он уже существовал).

---

## License / Лицензия

This project is distributed under the **MIT License**.  
See the [LICENSE](../LICENSE) file for details.

Данный проект распространяется под лицензией **MIT**.  
Подробности см. в файле [LICENSE](../LICENSE).
