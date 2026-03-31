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

-- Формируем динамический DO блок с подстановкой new_owner
SELECT format('
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
        where nspname not in (''pg_catalog'', ''pg_toast'', ''information_schema'', ''public'')
          and nspname not like ''pg_%%''
    loop
        execute ''alter schema '' || quote_ident(r.nspname) || '' owner to '' || quote_ident(new_owner);
    end loop;

    -- Смена владельца для таблиц, представлений, материализованных представлений и последовательностей
    for object_type in
        select
            unnest(''{type,table,table,view,materialized view,sequence}''::text[]) type_name,
            unnest(''{c,p,r,v,m,S}''::text[]) code
    loop
        for r in
            execute ''select n.nspname, c.relname
                     from pg_class c
                     join pg_namespace n on n.oid = c.relnamespace
                     where n.nspname not in (''''pg_catalog'''', ''''information_schema'''')
                       and c.relkind = '' || quote_literal(object_type.code) || ''
                     order by c.relname''
        loop
            execute ''alter '' || object_type.type_name || '' '' || quote_ident(r.nspname) || ''.'' || quote_ident(r.relname) || '' owner to '' || quote_ident(new_owner);
        end loop;
    end loop;

    -- Смена владельца для функций и процедур
    for r in 
        select
            p.proname,
            n.nspname,
            pg_catalog.pg_get_function_identity_arguments(p.oid) as args,
            p.prokind
        from pg_catalog.pg_namespace n
        join pg_catalog.pg_proc p on p.pronamespace = n.oid
        where n.nspname not in (''pg_catalog'', ''information_schema'')
          and p.proname not ilike ''dblink%%''
    loop
        if r.prokind = ''f'' then
            execute ''alter function '' || quote_ident(r.nspname) || ''.'' || quote_ident(r.proname) || ''('' || r.args || '') owner to '' || quote_ident(new_owner);
        elsif r.prokind = ''p'' then
            execute ''alter procedure '' || quote_ident(r.nspname) || ''.'' || quote_ident(r.proname) || ''('' || r.args || '') owner to '' || quote_ident(new_owner);
        end if;
    end loop;
end;
$$;', :'new_owner') AS cmd \gset

-- Выполняем сформированный блок
:cmd

\echo 'Смена владельца успешно завершена.'
