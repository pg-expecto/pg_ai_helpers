# pg_ai_helpers

These scripts are AI‑generated utilities for PostgreSQL administration and are **not part of pg_expecto**.

---

## English

This repository contains helper scripts created with the assistance of AI. They are designed to simplify routine tasks for PostgreSQL database administration.

### Scripts

| Script | Description |
|--------|-------------|
| [`compare/compare.sh`](./compare/compare.sh) | Compare PostgreSQL configuration files (key = value format). |
| [`mask_pgpro_pwr/mask_pgpro_pwr.sh`](./mask_pgpro_pwr/mask_pgpro_pwr.sh) | Mask IP addresses, constants in SQL queries, and database names in pgpro_pwr reports. |
| [`vacuum/vacuum`](./vacuum/vacuum) | Service scripts to manually run VACUUM on selected tables in the cluster. |

---

## Русский

Этот репозиторий содержит вспомогательные скрипты, созданные с использованием нейросетей. Они предназначены для упрощения рутинных задач администрирования PostgreSQL.

### Скрипты

| Скрипт | Описание |
|--------|----------|
| [`compare/compare.sh`](./compare/compare.sh) | Сравнение конфигурационных файлов СУБД (формат ключ = значение). |
| [`mask_pgpro_pwr/mask_pgpro_pwr.sh`](./mask_pgpro_pwr/mask_pgpro_pwr.sh) | Маскирование IP, констант в SQL-запросах и имён баз данных в отчётах pgpro_pwr. |
| [`vacuum/vacuum`](./vacuum/vacuum) | Сервисные скрипты для ручного выполнения VACUUM для отдельных таблиц в кластере. |

---

## License

This project is distributed under the **MIT License**.  
See the [LICENSE](LICENSE) file for details.

---

## Note

All scripts are provided “as is” without warranty of any kind. Use them at your own risk.
