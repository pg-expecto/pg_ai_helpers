#!/bin/bash
# mask_pgpro_pwr.sh
set -euo pipefail

usage() {
    echo "Usage: $0 input.html [output.html]"
    exit 1
}

if [ $# -lt 1 ]; then
    usage
fi

INPUT="$1"
OUTPUT="${2:-masked_${INPUT}}"

if [ ! -f "$INPUT" ]; then
    echo "Error: File '$INPUT' not found" >&2
    exit 1
fi

# Проверка наличия необходимых утилит
if ! command -v psql &>/dev/null; then
    echo "Error: psql not found. Cannot retrieve database list." >&2
    exit 1
fi

if ! command -v awk &>/dev/null; then
    echo "Error: awk not found. Required for text processing." >&2
    exit 1
fi

# 1. Формирование списка баз данных через psql
DB_LIST_FILE="db.txt"
if ! psql -Aqtc 'SELECT datname FROM pg_database' > "$DB_LIST_FILE" 2>/dev/null; then
    echo "Error: Failed to execute psql command. Check connection and permissions." >&2
    exit 1
fi

if [ ! -s "$DB_LIST_FILE" ]; then
    echo "Error: Database list is empty. Cannot proceed with masking." >&2
    exit 1
fi

echo "Database list saved to $DB_LIST_FILE"

# 2. Формирование списка пользователей (ролей)
USER_LIST_FILE="users.txt"
if ! psql -Aqtc "SELECT rolname FROM pg_roles WHERE rolname NOT LIKE 'pg_%' AND rolname != 'postgres'" > "$USER_LIST_FILE" 2>/dev/null; then
    echo "Warning: Failed to retrieve user list. Skipping user masking." >&2
    USER_LIST_FILE=""
fi

if [ -s "$USER_LIST_FILE" ]; then
    echo "User list saved to $USER_LIST_FILE"
else
    echo "No users found or user list empty. Skipping user masking."
    USER_LIST_FILE=""
fi

# 3. Замена названий баз данных на DB-N
replace_db_names() {
    local input_file="$1"
    local output_file="$2"
    local db_file="$3"

    awk -v db_file="$db_file" '
    function escape_regex(str) {
        gsub(/[.[\\*+?^${}()|]/, "\\\\&", str)
        return str
    }
    BEGIN {
        i = 1
        while ((getline db < db_file) > 0) {
            if (db == "") continue
            map[db] = "DB-" i
            i++
        }
        close(db_file)
    }
    {
        for (db in map) {
            escaped = escape_regex(db)
            gsub("\\y" escaped "\\y", map[db])
        }
        print
    }' "$input_file" > "$output_file"
}

# 4. Замена названий пользователей на USER-N
replace_user_names() {
    local input_file="$1"
    local output_file="$2"
    local user_file="$3"

    awk -v user_file="$user_file" '
    function escape_regex(str) {
        gsub(/[.[\\*+?^${}()|]/, "\\\\&", str)
        return str
    }
    BEGIN {
        i = 1
        while ((getline usr < user_file) > 0) {
            if (usr == "") continue
            map[usr] = "USER-" i
            i++
        }
        close(user_file)
    }
    {
        for (usr in map) {
            escaped = escape_regex(usr)
            gsub("\\y" escaped "\\y", map[usr])
        }
        print
    }' "$input_file" > "$output_file"
}

# 5. Маскировка IPv4-адресов (только локальные, валидные, без привязки к границам слов)
mask_ip() {
    awk '
    function is_local_ip(ip,   arr, i, val, o1, o2) {
        # Проверяем, что IP состоит только из цифр и точек
        if (ip ~ /[^0-9.]/) return 0
        split(ip, arr, ".")
        if (length(arr) != 4) return 0
        for (i = 1; i <= 4; i++) {
            val = arr[i]
            # Удаляем ведущие нули для числовой проверки
            sub(/^0+/, "", val)
            if (val == "") val = 0
            if (val > 255) return 0
        }
        o1 = arr[1] + 0
        o2 = arr[2] + 0
        if (o1 == 10) return 1
        if (o1 == 172 && o2 >= 16 && o2 <= 31) return 1
        if (o1 == 192 && o2 == 168) return 1
        return 0
    }

    {
        line = $0
        newline = ""
        while (match(line, /[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/)) {
            start = RSTART
            len = RLENGTH
            ip = substr(line, start, len)

            # Символы до и после совпадения
            before = (start > 1) ? substr(line, start-1, 1) : ""
            after = (start+len <= length(line)) ? substr(line, start+len, 1) : ""

            # Если рядом цифра или точка — это не отдельный IP (например, часть длинного числа)
            if (before ~ /[0-9.]/ || after ~ /[0-9.]/) {
                newline = newline substr(line, 1, start+len-1)
                line = substr(line, start+len)
                continue
            }

            if (is_local_ip(ip)) {
                replacement = "ip"
            } else {
                replacement = ip
            }

            newline = newline substr(line, 1, start-1) replacement
            line = substr(line, start+len)
        }
        newline = newline line
        print newline
    }' "$1"
}

# 6. Маскировка SQL-литералов
mask_sql_literals() {
    awk '
    BEGIN { in_sql = 0 }
    /<pre[^>]*class="[^"]*sql[^"]*"[^>]*>/ || /<code[^>]*class="[^"]*sql[^"]*"[^>]*>/ {
        in_sql = 1
    }
    /<\/pre>/ || /<\/code>/ {
        in_sql = 0
    }
    {
        if (in_sql) {
            gsub(/\047(\047\047|[^\047])*\047/, "\047?\047")
            gsub(/\b[0-9]+(\.[0-9]+)?\b/, "?")
        }
        print
    }' "$1"
}

# Временные файлы
TMP1=$(mktemp)
TMP2=$(mktemp)
TMP3=$(mktemp)
trap "rm -f $TMP1 $TMP2 $TMP3" EXIT

# Последовательная обработка
replace_db_names "$INPUT" "$TMP1" "$DB_LIST_FILE"

if [ -n "$USER_LIST_FILE" ] && [ -s "$USER_LIST_FILE" ]; then
    replace_user_names "$TMP1" "$TMP2" "$USER_LIST_FILE"
else
    cp "$TMP1" "$TMP2"
fi

mask_ip "$TMP2" > "$TMP3"
mask_sql_literals "$TMP3" > "$OUTPUT"

echo "Masked report saved to $OUTPUT"
