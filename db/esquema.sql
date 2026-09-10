-- ═══════════════════════════════════════════════════════════════════════════
--  TecrobSys · Esquema completo de la base
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Este archivo es la única fuente de verdad del esquema. Crea las tablas, sus
-- reglas, los índices, los disparadores que mantienen los importes y el
-- historial, las políticas de seguridad por fila y la función que crea una
-- orden completa en una sola transacción.
--
-- Pensado para ejecutarse entero sobre una base vacía, en el editor SQL de
-- Supabase. Es idempotente en lo que puede serlo: las tablas usan IF NOT
-- EXISTS y las funciones y políticas se reemplazan.
--
-- ── Idea de fondo ──────────────────────────────────────────────────────────
--
-- Los importes de una orden no se escriben desde la app: se derivan de sus
-- hijos. El subtotal sale de las líneas de servicio y el saldo sale de los
-- pagos. La app sólo decide el descuento. Así ninguna pantalla puede dejar
-- una orden descuadrada, y cobrar de más es imposible porque la base lo
-- rechaza antes de escribirlo.
--
-- El adelanto ya no es una columna. Entra como el primer pago, que es lo que
-- realmente es. Antes vivía en dos sitios y las pantallas leían el equivocado.

-- ───────────────────────────────────────────────────────────────────────────
-- 0. BORRADO PREVIO · DESTRUYE TODOS LOS DATOS
--
-- Descomenta este bloque SÓLO si quieres partir de cero. Borra las nueve
-- tablas con todo su contenido y no hay vuelta atrás.
--
-- Lo que NO se toca: los usuarios de acceso, que viven en el esquema auth. Tu
-- correo y tu contraseña siguen funcionando, y el proyecto conserva su URL y
-- sus claves. Lo único que hay que rehacer después es la fila de tu técnico,
-- que es lo que ata tu usuario a una empresa.
--
-- El cascade se lleva por delante los disparadores, las políticas y los
-- índices de esas tablas. Las funciones sueltas hay que borrarlas aparte,
-- incluida la versión antigua de crear_orden_completa, que tenía tres
-- parámetros en lugar de cuatro y quedaría conviviendo con la nueva.
-- ───────────────────────────────────────────────────────────────────────────

-- drop table if exists public.historial_estado  cascade;
-- drop table if exists public.pago              cascade;
-- drop table if exists public.orden_servicio    cascade;
-- drop table if exists public.equipo            cascade;
-- drop table if exists public.orden             cascade;
-- drop table if exists public.servicio_catalogo cascade;
-- drop table if exists public.cliente           cascade;
-- drop table if exists public.tecnico           cascade;
-- drop table if exists public.empresa           cascade;
--
-- drop function if exists public.crear_orden_completa(jsonb, jsonb, jsonb) cascade;
--
-- -- Cualquier otra función suelta que quedara del esquema anterior.
-- do $limpieza$
-- declare
--   f record;
-- begin
--   for f in
--     select p.oid::regprocedure as firma
--       from pg_proc p
--      where p.pronamespace = 'public'::regnamespace
--        and p.prokind = 'f'
--   loop
--     execute format('drop function if exists %s cascade', f.firma);
--   end loop;
-- end $limpieza$;

-- ───────────────────────────────────────────────────────────────────────────
-- 1. TABLAS
-- ───────────────────────────────────────────────────────────────────────────

create table if not exists public.empresa (
  id          integer generated always as identity primary key,
  nombre      text not null,
  ruc         text,
  telefono    text,
  email       text,
  direccion   text,
  created_at  timestamptz not null default now()
);

create table if not exists public.tecnico (
  id            integer generated always as identity primary key,
  empresa_id    integer not null references public.empresa(id) on delete restrict,
  auth_user_id  uuid unique,
  nombre        text not null,
  apellido      text,
  email         text not null,
  rol           text not null default 'tecnico'
                check (rol in ('administrador', 'tecnico')),
  activo        boolean not null default true,
  created_at    timestamptz not null default now()
);

create table if not exists public.cliente (
  id          integer generated always as identity primary key,
  empresa_id  integer not null references public.empresa(id) on delete restrict,
  nombre      text not null,
  apellido    text,
  telefono    text not null,
  email       text,
  dni         text,
  direccion   text,
  created_at  timestamptz not null default now()
);

create table if not exists public.servicio_catalogo (
  id           integer generated always as identity primary key,
  empresa_id   integer not null references public.empresa(id) on delete restrict,
  nombre       text not null,
  descripcion  text,
  precio_base  numeric(10,2) not null default 0 check (precio_base >= 0),
  categoria    text not null default 'otro'
               check (categoria in ('mantenimiento', 'reparacion', 'software',
                                    'repuesto', 'diagnostico', 'otro')),
  activo       boolean not null default true,
  created_at   timestamptz not null default now()
);

-- La orden. Ojo con las columnas derivadas: subtotal, total y saldo_pendiente
-- los calcula un disparador a partir de las líneas y de los pagos. Escribirlas
-- a mano no sirve de nada, se recalculan igual.
create table if not exists public.orden (
  id                integer generated always as identity primary key,
  numero_orden      text,
  empresa_id        integer not null references public.empresa(id) on delete restrict,
  cliente_id        integer not null references public.cliente(id) on delete restrict,
  tecnico_id        integer not null references public.tecnico(id) on delete restrict,
  estado            text not null default 'pendiente'
                    check (estado in ('pendiente', 'diagnostico', 'en_progreso',
                                      'listo', 'entregado', 'cancelado',
                                      'sin_reparacion')),
  prioridad         text not null default 'normal'
                    check (prioridad in ('baja', 'normal', 'alta', 'urgente')),
  descuento         numeric(10,2) not null default 0 check (descuento >= 0),
  subtotal          numeric(10,2) not null default 0,
  total             numeric(10,2) not null default 0,
  saldo_pendiente   numeric(10,2) not null default 0,
  contrasena_equipo text,
  fecha_prometida   date,
  observaciones     text,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),

  -- El número es único dentro de la empresa, no en toda la base: dos talleres
  -- distintos pueden tener cada uno su ORD-0001.
  constraint orden_numero_por_empresa unique (empresa_id, numero_orden)
);

create table if not exists public.equipo (
  id                  integer generated always as identity primary key,
  orden_id            integer not null unique references public.orden(id) on delete cascade,
  tipo                text not null default 'otro'
                      check (tipo in ('laptop', 'computadora', 'impresora',
                                      'fotocopiadora', 'tablet', 'celular',
                                      'parlante', 'otro')),
  marca               text,
  modelo              text,
  numero_serie        text,
  desperfecto         text,
  descripcion_general text,
  accesorios          text,
  created_at          timestamptz not null default now()
);

create table if not exists public.orden_servicio (
  id              integer generated always as identity primary key,
  orden_id        integer not null references public.orden(id) on delete cascade,
  servicio_id     integer not null references public.servicio_catalogo(id) on delete restrict,
  precio_unitario numeric(10,2) not null default 0 check (precio_unitario >= 0),
  cantidad        integer not null default 1 check (cantidad > 0),
  subtotal        numeric(10,2) generated always as (precio_unitario * cantidad) stored
);

create table if not exists public.pago (
  id          bigint generated always as identity primary key,
  orden_id    integer not null references public.orden(id) on delete cascade,
  monto       numeric(10,2) not null check (monto > 0),
  metodo      text not null
              check (metodo in ('efectivo', 'yape', 'plin', 'transferencia', 'tarjeta')),
  nota        text,
  created_at  timestamptz not null default now()
);

create table if not exists public.historial_estado (
  id           bigint generated always as identity primary key,
  orden_id     integer not null references public.orden(id) on delete cascade,
  estado_prev  text,
  estado_nuevo text not null,
  tecnico_id   integer references public.tecnico(id) on delete set null,
  created_at   timestamptz not null default now()
);

-- ───────────────────────────────────────────────────────────────────────────
-- 2. ÍNDICES
--
-- Postgres no indexa las claves foráneas por su cuenta, y la app pide todas
-- las órdenes de una empresa con sus relaciones en cada carga del panel.
-- ───────────────────────────────────────────────────────────────────────────

create index if not exists idx_tecnico_empresa           on public.tecnico(empresa_id);
create index if not exists idx_cliente_empresa           on public.cliente(empresa_id);
create index if not exists idx_servicio_empresa          on public.servicio_catalogo(empresa_id);
create index if not exists idx_orden_empresa_estado      on public.orden(empresa_id, estado);
create index if not exists idx_orden_cliente             on public.orden(cliente_id);
create index if not exists idx_orden_tecnico             on public.orden(tecnico_id);
create index if not exists idx_orden_fecha_prometida     on public.orden(fecha_prometida);
create index if not exists idx_orden_servicio_orden      on public.orden_servicio(orden_id);
create index if not exists idx_orden_servicio_servicio   on public.orden_servicio(servicio_id);
create index if not exists idx_pago_orden                on public.pago(orden_id);
create index if not exists idx_historial_orden           on public.historial_estado(orden_id);

-- Un mismo documento o un mismo teléfono no pueden repetirse dentro de una
-- empresa. Sin esto, el asistente de nueva orden crea clientes duplicados.
create unique index if not exists idx_cliente_dni_unico
  on public.cliente(empresa_id, dni)
  where dni is not null and dni <> '';

create unique index if not exists idx_cliente_telefono_unico
  on public.cliente(empresa_id, telefono)
  where telefono <> '';

-- ───────────────────────────────────────────────────────────────────────────
-- 3. NUMERACIÓN DE ÓRDENES
--
-- Correlativo por empresa con el formato ORD-0001. Si dos órdenes se crean en
-- el mismo instante, la restricción única de arriba hace que una falle y se
-- reintente, que es preferible a repetir un número.
-- ───────────────────────────────────────────────────────────────────────────

create or replace function public.asignar_numero_orden()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_siguiente integer;
begin
  if new.numero_orden is null or new.numero_orden = '' then
    select coalesce(max(nullif(regexp_replace(numero_orden, '\D', '', 'g'), '')::integer), 0) + 1
      into v_siguiente
      from orden
     where empresa_id = new.empresa_id;

    new.numero_orden := 'ORD-' || lpad(v_siguiente::text, 4, '0');
  end if;

  return new;
end $$;

drop trigger if exists trg_orden_numero on public.orden;
create trigger trg_orden_numero
  before insert on public.orden
  for each row execute function public.asignar_numero_orden();

-- ───────────────────────────────────────────────────────────────────────────
-- 4. IMPORTES DERIVADOS
--
-- Una orden vale lo que suman sus líneas de servicio, menos su descuento, y
-- debe lo que aún no se le ha pagado. Se recalcula en cada escritura, así que
-- da igual por dónde entre el cambio.
-- ───────────────────────────────────────────────────────────────────────────

create or replace function public.orden_recalcular_importes()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_subtotal numeric(10,2);
  v_pagado   numeric(10,2);
begin
  select coalesce(sum(precio_unitario * cantidad), 0)
    into v_subtotal
    from orden_servicio
   where orden_id = new.id;

  select coalesce(sum(monto), 0)
    into v_pagado
    from pago
   where orden_id = new.id;

  new.subtotal        := v_subtotal;
  new.total           := greatest(v_subtotal - new.descuento, 0);
  new.saldo_pendiente := new.total - v_pagado;
  new.updated_at      := now();

  return new;
end $$;

drop trigger if exists trg_orden_importes on public.orden;
create trigger trg_orden_importes
  before insert or update on public.orden
  for each row execute function public.orden_recalcular_importes();

-- Cualquier cambio en las líneas o en los pagos empuja a la orden a
-- recalcularse. El toque no escribe importes: los pone el disparador de
-- arriba, que es el único que sabe la fórmula.
create or replace function public.tocar_orden()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_orden_id integer;
begin
  -- En un DELETE la fila NEW no existe, así que no se puede mirar sin más.
  if tg_op = 'DELETE' then
    v_orden_id := old.orden_id;
  else
    v_orden_id := new.orden_id;
  end if;

  update orden set updated_at = now() where id = v_orden_id;

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end $$;

drop trigger if exists trg_servicio_tocar_orden on public.orden_servicio;
create trigger trg_servicio_tocar_orden
  after insert or update or delete on public.orden_servicio
  for each row execute function public.tocar_orden();

drop trigger if exists trg_pago_tocar_orden on public.pago;
create trigger trg_pago_tocar_orden
  after insert or update or delete on public.pago
  for each row execute function public.tocar_orden();

-- ───────────────────────────────────────────────────────────────────────────
-- 5. NO SE PUEDE COBRAR DE MÁS
--
-- Un cobro por encima del saldo dejaba la orden con saldo negativo, y en el
-- panel aparecía un importe en rojo que nadie sabía explicar.
-- ───────────────────────────────────────────────────────────────────────────

create or replace function public.validar_pago()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_total  numeric(10,2);
  v_pagado numeric(10,2);
begin
  select total into v_total from orden where id = new.orden_id;

  select coalesce(sum(monto), 0)
    into v_pagado
    from pago
   where orden_id = new.orden_id
     and id is distinct from new.id;

  if v_pagado + new.monto > v_total + 0.005 then
    raise exception
      'El cobro de % supera el saldo de la orden %: total %, ya pagado %',
      new.monto, new.orden_id, v_total, v_pagado
      using errcode = 'check_violation';
  end if;

  return new;
end $$;

drop trigger if exists trg_pago_validar on public.pago;
create trigger trg_pago_validar
  before insert or update on public.pago
  for each row execute function public.validar_pago();

-- ───────────────────────────────────────────────────────────────────────────
-- 6. HISTORIAL DE ESTADOS
--
-- Cada salto queda registrado con quién lo hizo. Es lo que permite saber
-- cuántos días lleva un equipo esperando a que lo recojan, en vez de deducirlo
-- de la fecha de actualización de la orden.
-- ───────────────────────────────────────────────────────────────────────────

create or replace function public.registrar_historial_estado()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_tecnico_id integer;
  v_previo     text := null;
begin
  -- OLD sólo existe en el UPDATE, así que se mira dentro de su propia rama.
  if tg_op = 'UPDATE' then
    if old.estado is not distinct from new.estado then
      return new;
    end if;
    v_previo := old.estado;
  end if;

  select id into v_tecnico_id from tecnico where auth_user_id = auth.uid() limit 1;

  insert into historial_estado (orden_id, estado_prev, estado_nuevo, tecnico_id)
  values (new.id, v_previo, new.estado, coalesce(v_tecnico_id, new.tecnico_id));

  return new;
end $$;

drop trigger if exists trg_orden_historial on public.orden;
create trigger trg_orden_historial
  after insert or update of estado on public.orden
  for each row execute function public.registrar_historial_estado();

-- ───────────────────────────────────────────────────────────────────────────
-- 7. SEGURIDAD POR FILA
--
-- Cada técnico ve y toca sólo lo de su empresa. La función va como SECURITY
-- DEFINER a propósito: si consultara la tabla tecnico con RLS activa, la
-- política de tecnico se llamaría a sí misma.
-- ───────────────────────────────────────────────────────────────────────────

-- Nota de arranque: en una base recién creada no hay ningún técnico, así que
-- empresa_actual() devuelve null y la app no ve nada. La primera empresa y el
-- primer técnico se crean desde el editor SQL de Supabase, que no pasa por
-- estas políticas. Para eso está db/datos_de_prueba.sql.

create or replace function public.empresa_actual()
returns integer language sql stable security definer set search_path = public as $$
  select empresa_id
    from tecnico
   where auth_user_id = auth.uid()
     and activo
   limit 1
$$;

revoke execute on function public.empresa_actual() from public;
grant execute on function public.empresa_actual() to authenticated;

alter table public.empresa           enable row level security;
alter table public.tecnico           enable row level security;
alter table public.cliente           enable row level security;
alter table public.servicio_catalogo enable row level security;
alter table public.orden             enable row level security;
alter table public.equipo            enable row level security;
alter table public.orden_servicio    enable row level security;
alter table public.pago              enable row level security;
alter table public.historial_estado  enable row level security;

-- La empresa propia sólo se lee.
drop policy if exists empresa_propia on public.empresa;
create policy empresa_propia on public.empresa
  for select to authenticated
  using (id = public.empresa_actual());

-- El resto de tablas con empresa_id siguen el mismo patrón.
do $$
declare
  t text;
begin
  foreach t in array array['tecnico', 'cliente', 'servicio_catalogo', 'orden'] loop
    execute format('drop policy if exists %1$s_de_mi_empresa on public.%1$I', t);
    execute format($f$
      create policy %1$s_de_mi_empresa on public.%1$I
        for all to authenticated
        using (empresa_id = public.empresa_actual())
        with check (empresa_id = public.empresa_actual())
    $f$, t);
  end loop;
end $$;

-- Las tablas hijas heredan la empresa a través de su orden.
do $$
declare
  t text;
begin
  foreach t in array array['equipo', 'orden_servicio', 'pago', 'historial_estado'] loop
    execute format('drop policy if exists %1$s_de_mi_empresa on public.%1$I', t);
    execute format($f$
      create policy %1$s_de_mi_empresa on public.%1$I
        for all to authenticated
        using (exists (
          select 1 from public.orden o
           where o.id = %1$I.orden_id
             and o.empresa_id = public.empresa_actual()))
        with check (exists (
          select 1 from public.orden o
           where o.id = %1$I.orden_id
             and o.empresa_id = public.empresa_actual()))
    $f$, t);
  end loop;
end $$;

-- ───────────────────────────────────────────────────────────────────────────
-- 8. CREAR UNA ORDEN COMPLETA
--
-- Cliente, orden, equipo, líneas de servicio y adelanto en una transacción. Si
-- algo falla no queda nada suelto: antes el cliente se guardaba en una llamada
-- aparte y sobrevivía aunque la orden fallara después.
--
-- SECURITY INVOKER a propósito: corre con los permisos de quien la llama, así
-- que las políticas de arriba se aplican igual que en una escritura directa.
-- ───────────────────────────────────────────────────────────────────────────

create or replace function public.crear_orden_completa(
  p_cliente   jsonb,
  p_orden     jsonb,
  p_equipo    jsonb,
  p_servicios jsonb
)
returns integer
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_empresa_id integer := (p_orden->>'empresa_id')::integer;
  v_cliente_id integer := nullif(p_cliente->>'id', '')::integer;
  v_orden_id   integer;
  v_adelanto   numeric(10,2) := coalesce((p_orden->>'adelanto')::numeric, 0);
begin
  if p_orden is null or p_equipo is null or p_cliente is null then
    raise exception 'crear_orden_completa necesita cliente, orden y equipo';
  end if;

  -- 1. El cliente: se actualiza si ya existía, se crea si no.
  if v_cliente_id is null then
    insert into cliente (empresa_id, nombre, apellido, dni, telefono, email)
    values (
      v_empresa_id,
      p_cliente->>'nombre',
      p_cliente->>'apellido',
      nullif(p_cliente->>'dni', ''),
      coalesce(nullif(p_cliente->>'telefono', ''), 'sin telefono'),
      nullif(p_cliente->>'email', '')
    )
    returning id into v_cliente_id;
  else
    update cliente
       set nombre   = coalesce(nullif(p_cliente->>'nombre', ''), nombre),
           apellido = coalesce(nullif(p_cliente->>'apellido', ''), apellido),
           dni      = coalesce(nullif(p_cliente->>'dni', ''), dni),
           telefono = coalesce(nullif(p_cliente->>'telefono', ''), telefono),
           email    = coalesce(nullif(p_cliente->>'email', ''), email)
     where id = v_cliente_id;
  end if;

  -- 2. La orden. Los importes los pone el disparador, no lo que mande la app.
  insert into orden (
    empresa_id, cliente_id, tecnico_id, estado, prioridad,
    descuento, contrasena_equipo, fecha_prometida, observaciones
  )
  values (
    v_empresa_id,
    v_cliente_id,
    (p_orden->>'tecnico_id')::integer,
    coalesce(p_orden->>'estado', 'pendiente'),
    coalesce(p_orden->>'prioridad', 'normal'),
    coalesce((p_orden->>'descuento')::numeric, 0),
    nullif(p_orden->>'contrasena_equipo', ''),
    nullif(p_orden->>'fecha_prometida', '')::date,
    nullif(p_orden->>'observaciones', '')
  )
  returning id into v_orden_id;

  -- 3. El equipo que se recibe.
  insert into equipo (
    orden_id, tipo, marca, modelo, numero_serie,
    desperfecto, descripcion_general, accesorios
  )
  values (
    v_orden_id,
    coalesce(p_equipo->>'tipo', 'otro'),
    nullif(p_equipo->>'marca', ''),
    nullif(p_equipo->>'modelo', ''),
    nullif(p_equipo->>'numero_serie', ''),
    nullif(p_equipo->>'desperfecto', ''),
    nullif(p_equipo->>'descripcion_general', ''),
    nullif(p_equipo->>'accesorios', '')
  );

  -- 4. Las líneas de servicio, si las hay. Al insertarlas se recalcula el
  --    total de la orden, que es lo que valida el adelanto del paso siguiente.
  insert into orden_servicio (orden_id, servicio_id, cantidad, precio_unitario)
  select
    v_orden_id,
    (elem->>'servicio_id')::integer,
    coalesce((elem->>'cantidad')::integer, 1),
    (elem->>'precio_unitario')::numeric
  from jsonb_array_elements(coalesce(p_servicios, '[]'::jsonb)) as elem;

  -- 5. El adelanto, registrado como el primer pago. Si supera el total, el
  --    disparador de pagos aborta toda la transacción.
  if v_adelanto > 0 then
    insert into pago (orden_id, monto, metodo, nota)
    values (
      v_orden_id,
      v_adelanto,
      coalesce(nullif(p_orden->>'metodo_adelanto', ''), 'efectivo'),
      'Adelanto inicial al crear la orden'
    );
  end if;

  return v_orden_id;
end $$;

revoke execute on function public.crear_orden_completa(jsonb, jsonb, jsonb, jsonb) from public;
grant execute on function public.crear_orden_completa(jsonb, jsonb, jsonb, jsonb) to authenticated;
