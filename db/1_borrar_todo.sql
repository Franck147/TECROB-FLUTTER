-- ═══════════════════════════════════════════════════════════════════════════
--  TecrobSys · Paso 1 · Borrar la base para empezar de cero
-- ═══════════════════════════════════════════════════════════════════════════
--
-- ⚠ DESTRUYE TODOS LOS DATOS DE LA APP: órdenes, clientes, pagos, catálogo y
--   técnicos. No hay vuelta atrás. Si hay algo que quieras conservar, sácalo
--   antes desde Table Editor con Export to CSV.
--
-- Borra todas las tablas, vistas, funciones y tipos del esquema public,
-- también lo que sólo existía en la versión vieja con empresa_id: la tabla
-- empresa, la columna estado_desde, la función empresa_actual y la
-- crear_orden_completa de tres parámetros. No hace falta saber qué quedó,
-- porque recorre lo que haya.
--
-- Lo que NO toca: los usuarios de acceso, que viven en el esquema auth. Tu
-- correo y tu contraseña siguen funcionando, y el proyecto conserva su URL y
-- sus claves. Tampoco toca lo que instalan las extensiones.
--
-- Orden completo, cada archivo entero en el editor SQL de Supabase:
--   1. db/1_borrar_todo.sql       este archivo
--   2. db/2_esquema.sql           crea las tablas, ya sin empresa_id
--   3. db/3_tecnicos.sql          da acceso a tus usuarios
--   4. db/4_datos_de_prueba.sql   opcional, un taller ficticio para probar

do $$
declare
  v_sentencias text[];
  v_sentencia  text;
begin
  -- Las sentencias se arman todas antes de borrar nada. Armadas sobre la
  -- marcha, un cascade podría llevarse un objeto que el recorrido aún no ha
  -- visitado y su nombre ya no se podría leer.
  select coalesce(array_agg(s.sentencia order by s.orden), '{}')
    into v_sentencias
    from (
      -- Funciones y procedimientos, con su firma completa.
      select 1 as orden,
             format('drop %s if exists public.%I(%s) cascade',
                    case p.prokind when 'p' then 'procedure' else 'function' end,
                    p.proname,
                    pg_get_function_identity_arguments(p.oid)) as sentencia
        from pg_proc p
       where p.pronamespace = 'public'::regnamespace
         and p.prokind in ('f', 'p')
         and not exists (select 1 from pg_depend d
                          where d.classid = 'pg_proc'::regclass
                            and d.objid = p.oid
                            and d.deptype = 'e')

      union all

      -- Vistas, luego tablas y al final las secuencias sueltas. Las de las
      -- columnas identity caen con su tabla.
      select case c.relkind when 'v' then 2 when 'm' then 3 when 'S' then 5 else 4 end,
             format('drop %s if exists public.%I cascade',
                    case c.relkind
                      when 'v' then 'view'
                      when 'm' then 'materialized view'
                      when 'S' then 'sequence'
                      else 'table'
                    end,
                    c.relname)
        from pg_class c
       where c.relnamespace = 'public'::regnamespace
         and c.relkind in ('r', 'p', 'v', 'm', 'S')
         and not exists (select 1 from pg_depend d
                          where d.classid = 'pg_class'::regclass
                            and d.objid = c.oid
                            and d.deptype = 'e')

      union all

      -- Tipos enumerados, por si la versión vieja usaba alguno.
      select 6,
             format('drop type if exists public.%I cascade', t.typname)
        from pg_type t
       where t.typnamespace = 'public'::regnamespace
         and t.typtype = 'e'
         and not exists (select 1 from pg_depend d
                          where d.classid = 'pg_type'::regclass
                            and d.objid = t.oid
                            and d.deptype = 'e')
    ) s;

  foreach v_sentencia in array v_sentencias loop
    execute v_sentencia;
  end loop;

  raise notice 'Objetos borrados: %', cardinality(v_sentencias);
end $$;

-- Comprobación: no debe devolver ninguna fila.
select c.relname as queda
  from pg_class c
 where c.relnamespace = 'public'::regnamespace
   and c.relkind in ('r', 'p', 'v', 'm');
