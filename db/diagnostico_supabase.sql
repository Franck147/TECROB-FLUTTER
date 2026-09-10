-- Diagnóstico de la base de TecrobSys.
--
-- Sólo lee: no crea, no borra y no modifica nada. Ejecutar bloque por bloque
-- en el editor SQL de Supabase y comparar con lo que espera la app.
--
-- Cada consulta responde a una pregunta que no se puede contestar leyendo el
-- código de Flutter, porque la respuesta vive en la base.

-- ─────────────────────────────────────────────────────────────────────
-- 1. ¿Qué disparadores mantienen los importes al día?
--
-- La app inserta en 'pago' y nunca escribe orden.saldo_pendiente, así que
-- alguien tiene que recalcularlo. Si aquí no sale ningún disparador sobre
-- 'pago', el saldo mostrado en pantalla está congelado desde la creación.
-- ─────────────────────────────────────────────────────────────────────
select
  c.relname            as tabla,
  t.tgname             as disparador,
  p.proname            as funcion,
  pg_get_triggerdef(t.oid) as definicion
from pg_trigger t
join pg_class c on c.oid = t.tgrelid
join pg_proc  p on p.oid = t.tgfoid
where not t.tgisinternal
  and c.relnamespace = 'public'::regnamespace
order by c.relname, t.tgname;

-- ─────────────────────────────────────────────────────────────────────
-- 2. ¿Se actualiza orden.updated_at al cambiar de estado?
--
-- La insignia de días esperando del panel usa updated_at. Si todas las filas
-- tienen updated_at igual a created_at, la insignia está contando días desde
-- el ingreso, no desde que el equipo quedó listo.
-- ─────────────────────────────────────────────────────────────────────
select
  count(*)                                          as ordenes,
  count(*) filter (where updated_at > created_at)   as con_updated_at_movido,
  count(*) filter (where updated_at = created_at)   as sin_mover
from orden;

-- ─────────────────────────────────────────────────────────────────────
-- 3. ¿Quién genera numero_orden?
--
-- La función crear_orden_completa no lo escribe, pero la app muestra códigos
-- tipo ORD-0035. Si aquí sale null en todas las filas recientes, el código
-- visible es sólo el id.
-- ─────────────────────────────────────────────────────────────────────
select id, numero_orden, created_at
from orden
order by id desc
limit 10;

-- ─────────────────────────────────────────────────────────────────────
-- 4. ¿Los importes guardados cuadran con las líneas y los pagos?
--
-- subtotal debe ser la suma de las líneas de servicio, y saldo_pendiente
-- debe ser total menos lo pagado. Las filas que salgan aquí están torcidas.
-- ─────────────────────────────────────────────────────────────────────
with calculado as (
  select
    o.id,
    o.numero_orden,
    o.estado,
    o.subtotal,
    o.descuento,
    o.total,
    o.adelanto,
    o.saldo_pendiente,
    coalesce((select sum(os.precio_unitario * os.cantidad)
              from orden_servicio os where os.orden_id = o.id), 0) as subtotal_real,
    coalesce((select sum(pg.monto)
              from pago pg where pg.orden_id = o.id), 0)           as pagado_real
  from orden o
)
select *,
       subtotal - subtotal_real                       as desfase_subtotal,
       saldo_pendiente - (total - pagado_real)        as desfase_saldo,
       adelanto - pagado_real                         as desfase_adelanto
from calculado
where subtotal <> subtotal_real
   or saldo_pendiente <> (total - pagado_real)
   or total <> (subtotal - descuento)
order by id;

-- ─────────────────────────────────────────────────────────────────────
-- 5. ¿Hay saldos negativos? Son cobros por encima de lo debido.
-- ─────────────────────────────────────────────────────────────────────
select id, numero_orden, estado, total, adelanto, saldo_pendiente
from orden
where saldo_pendiente < 0
order by saldo_pendiente;

-- ─────────────────────────────────────────────────────────────────────
-- 6. ¿Se está usando historial_estado?
--
-- La app no escribe en esta tabla. Si sale 0, la tabla está muerta: o se
-- empieza a llenar desde la app, o se elimina.
-- ─────────────────────────────────────────────────────────────────────
select count(*) as filas_de_historial from historial_estado;

-- ─────────────────────────────────────────────────────────────────────
-- 7. ¿Se están usando las columnas que la app nunca toca?
-- ─────────────────────────────────────────────────────────────────────
select
  count(*) filter (where observaciones is not null and observaciones <> '') as con_observaciones,
  count(*) filter (where pdf_url is not null and pdf_url <> '')             as con_pdf_url,
  count(*) filter (where contrasena_equipo is not null)                     as con_contrasena
from orden;

-- ─────────────────────────────────────────────────────────────────────
-- 8. ¿Hay clientes duplicados?
--
-- No existe restricción única por DNI ni por teléfono dentro de una empresa,
-- así que el asistente de nueva orden puede crear el mismo cliente dos veces.
-- ─────────────────────────────────────────────────────────────────────
select empresa_id, dni, count(*) as veces
from cliente
where dni is not null and dni <> ''
group by empresa_id, dni
having count(*) > 1
order by veces desc;

select empresa_id, telefono, count(*) as veces
from cliente
group by empresa_id, telefono
having count(*) > 1
order by veces desc;

-- ─────────────────────────────────────────────────────────────────────
-- 9. ¿Hay órdenes sin equipo? La app da el equipo por hecho en pantalla.
-- ─────────────────────────────────────────────────────────────────────
select o.id, o.numero_orden, o.estado
from orden o
left join equipo e on e.orden_id = o.id
where e.id is null
order by o.id;

-- ─────────────────────────────────────────────────────────────────────
-- 10. ¿Están protegidas todas las tablas con RLS y con qué políticas?
--
-- Una tabla con rls_activo = false queda expuesta a cualquiera que tenga la
-- clave publicable, que viaja dentro de la app.
-- ─────────────────────────────────────────────────────────────────────
select
  c.relname   as tabla,
  c.relrowsecurity as rls_activo,
  count(p.polname) as politicas
from pg_class c
left join pg_policy p on p.polrelid = c.oid
where c.relnamespace = 'public'::regnamespace
  and c.relkind = 'r'
group by c.relname, c.relrowsecurity
order by c.relname;

select tablename, policyname, cmd, qual, with_check
from pg_policies
where schemaname = 'public'
order by tablename, policyname;

-- ─────────────────────────────────────────────────────────────────────
-- 11. ¿Están indexadas las columnas por las que la app filtra siempre?
--
-- La app pide todas las órdenes de una empresa con sus relaciones en cada
-- carga del panel y del listado.
-- ─────────────────────────────────────────────────────────────────────
select tablename, indexname, indexdef
from pg_indexes
where schemaname = 'public'
order by tablename, indexname;
