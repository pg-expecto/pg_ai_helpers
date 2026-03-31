do $$
declare
  new_owner text := 'poy_user'; -- Укажите здесь имя нового владельца
  object_type record;
  r record;
  sql text;
begin
  -- Смена владельца для всех схем
   -- Смена владельца ТОЛЬКО для несистемных схем
  for r in 
    select nspname 
    from pg_namespace 
    where nspname NOT IN ('pg_catalog', 'pg_toast', 'information_schema','public')
      and nspname NOT LIKE 'pg_%'
  loop
    execute format('ALTER SCHEMA %I OWNER TO %I', r.nspname, new_owner);
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
          join pg_namespace n on
            n.oid = c.relnamespace
            and not n.nspname in ('pg_catalog', 'information_schema')
            and c.relkind = %L
          order by c.relname
        $sql$,
        object_type.code
      )
    loop
      sql := format(
        'alter %s %I.%I owner to %I;',
        object_type.type_name,
        r.nspname,
        r.relname,
        new_owner
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
    from pg_catalog.pg_namespace as n
    join pg_catalog.pg_proc as p on p.pronamespace = n.oid
    where
      not n.nspname in ('pg_catalog', 'information_schema')
      and p.proname not ilike 'dblink%'
  loop
    sql := format(
      'alter function %I.%I(%s) owner to %I',
      r.nspname,
      r.proname,
      r.args,
      new_owner
    );
    execute sql;
  end loop;
end
$$;