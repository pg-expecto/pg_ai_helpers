-- change_owner.sql
-- Запуск: psql -v dbname=имя_бд -v new_owner=имя_роли -f change_owner.sql

-- Проверяем, заданы ли параметры, иначе завершаем с ошибкой
\if :{?dbname}
\else
    \echo 'Ошибка: не указано имя базы данных. Используйте: psql -v dbname=... -f change_owner.sql'
    \quit 1
\endif

\if :{?new_owner}
\else
    \echo 'Ошибка: не указано имя нового владельца. Используйте: psql -v new_owner=... -f change_owner.sql'
    \quit 1
\endif

-- Подключаемся к целевой базе данных
\connect :dbname

-- Формируем динамический блок DO с подстановкой имени роли
SELECT format(
    $do$
    do $$
    declare
        new_owner text := %L;
        object_type record;
        r record;
        sql text;
    begin
        -- Смена владельца для несистемных схем
        for r in 
            select nspname 
            from pg_namespace 
            where nspname not in ('pg_catalog', 'pg_toast', 'information_schema', 'public')
              and nspname not like 'pg_%%'
        loop
            execute format('alter schema %I owner to %I', r.nspname, new_owner);
        end loop;

        -- Смена владельца для таблиц, представлений, материализованных представлений и последовательностей
        for object_type in
            select
                unnest('{type,table,table,view,materialized view,sequence}'::text[]) type_name,
                unnest('{c,p,r,v,m,S}'::text[]) code
        loop
            for r in
                execute format(
                    $sql$
                        select n.nspname, c.relname
                        from pg_class c
                        join pg_namespace n on n.oid = c.relnamespace
                        where n.nspname not in ('pg_catalog', 'information_schema')
                          and c.relkind = %L
                        order by c.relname
                    $sql$,
                    object_type.code
                )
            loop
                sql := format(
                    'alter %s %I.%I owner to %I;',
                    object_type.type_name, r.nspname, r.relname, new_owner
                );
                execute sql;
            end loop;
        end loop;

        -- Смена владельца для функций и процедур
        for r in 
            select
                p.proname,
                n.nspname,
                pg_catalog.pg_get_function_identity_arguments(p.oid) as args
            from pg_catalog.pg_namespace n
            join pg_catalog.pg_proc p on p.pronamespace = n.oid
            where n.nspname not in ('pg_catalog', 'information_schema')
              and p.proname not ilike 'dblink%%'
        loop
            sql := format(
                'alter function %I.%I(%s) owner to %I',
                r.nspname, r.proname, r.args, new_owner
            );
            execute sql;
        end loop;
    end
    $$;
    $do$,
    :'new_owner'
) AS cmd \gset

-- Выполняем сформированный блок
:cmd

\echo 'Смена владельца успешно завершена.'
