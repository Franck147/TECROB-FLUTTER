-- ═══════════════════════════════════════════════════════════════════════════
--  TecrobSys · Taller ficticio para probar la app
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Crea una empresa, un catálogo de servicios, seis clientes y ocho órdenes,
-- una en cada punto del recorrido: recién ingresada, en diagnóstico, en
-- reparación, lista y pagada, lista y por cobrar, entregada, cancelada y sin
-- reparación posible. Sirve para recorrer la app entera sin inventar datos a
-- mano.
--
-- Requisitos: ejecutar antes db/esquema.sql, y tener ya creado en Supabase el
-- usuario de autenticación con el que vas a entrar.
--
-- Ejecutar en el editor SQL de Supabase, que corre sin las políticas de fila.
--
-- ⚠ Sólo para una base de pruebas. No lo ejecutes sobre datos reales.

do $$
declare
  -- ── Cambia esto por el correo de tu usuario de Supabase ──────────────────
  v_email_tecnico text := 'tecrobsys@gmail.com';

  v_auth_id    uuid;
  v_empresa_id integer;
  v_tecnico_id integer;
  v_orden_id   integer;

  v_diag  integer;
  v_mant  integer;
  v_soft  integer;
  v_rep   integer;

  v_cli   integer[];
begin
  select id into v_auth_id from auth.users where email = v_email_tecnico;
  if v_auth_id is null then
    raise exception
      'No existe el usuario % en auth.users. Créalo primero en Supabase.',
      v_email_tecnico;
  end if;

  -- 1. Empresa y técnico ────────────────────────────────────────────────────
  insert into empresa (nombre, ruc, telefono, email, direccion)
  values ('MULTISERVICIOS TECROB SYS E.I.R.L.', '20600000001', '999888777',
          v_email_tecnico, 'Av. Siempre Viva 742')
  returning id into v_empresa_id;

  insert into tecnico (empresa_id, auth_user_id, nombre, apellido, email, rol)
  values (v_empresa_id, v_auth_id, 'Adler', 'Bautista', v_email_tecnico, 'administrador')
  returning id into v_tecnico_id;

  -- 2. Catálogo de servicios ────────────────────────────────────────────────
  insert into servicio_catalogo (empresa_id, nombre, precio_base, categoria) values
    (v_empresa_id, 'Diagnóstico general',        30,  'diagnostico'),
    (v_empresa_id, 'Mantenimiento preventivo',   80,  'mantenimiento'),
    (v_empresa_id, 'Instalación de sistema',     70,  'software'),
    (v_empresa_id, 'Cambio de pantalla',        250,  'reparacion'),
    (v_empresa_id, 'Cambio de teclado',         120,  'repuesto'),
    (v_empresa_id, 'Limpieza de cabezales',      60,  'mantenimiento');

  select id into v_diag from servicio_catalogo
   where empresa_id = v_empresa_id and nombre = 'Diagnóstico general';
  select id into v_mant from servicio_catalogo
   where empresa_id = v_empresa_id and nombre = 'Mantenimiento preventivo';
  select id into v_soft from servicio_catalogo
   where empresa_id = v_empresa_id and nombre = 'Instalación de sistema';
  select id into v_rep  from servicio_catalogo
   where empresa_id = v_empresa_id and nombre = 'Cambio de pantalla';

  -- 3. Clientes ─────────────────────────────────────────────────────────────
  insert into cliente (empresa_id, nombre, apellido, telefono, dni) values
    (v_empresa_id, 'Javier',   'Curo Huarcaya',   '987111222', '41258963'),
    (v_empresa_id, 'Fredy',    'Bautista',        '987222333', '45896321'),
    (v_empresa_id, 'Gina',     'Pullo Quispe',    '987333444', '70125896'),
    (v_empresa_id, 'Jhonatan', 'Sauñe Pichardo',  '987444555', '72589631'),
    (v_empresa_id, 'Cristian', 'Adco',            '987555666', '75896321'),
    (v_empresa_id, 'Eduardo',  'Ramos',           '987666777', '48521963');

  select array_agg(id order by id) into v_cli
    from cliente where empresa_id = v_empresa_id;

  -- 4. Las ocho órdenes ─────────────────────────────────────────────────────
  --
  -- Se usa la función real de la app, así que los importes y el historial los
  -- calculan los mismos disparadores que en producción.

  -- 4.1 Recién ingresada, con plazo por delante.
  v_orden_id := crear_orden_completa(
    jsonb_build_object('id', v_cli[1]),
    jsonb_build_object('empresa_id', v_empresa_id, 'tecnico_id', v_tecnico_id,
                       'prioridad', 'normal',
                       'fecha_prometida', (current_date + 3)::text),
    jsonb_build_object('tipo', 'laptop', 'marca', 'HP', 'modelo', '250 G7',
                       'desperfecto', 'No enciende'),
    jsonb_build_array(jsonb_build_object('servicio_id', v_diag,
                                         'cantidad', 1, 'precio_unitario', 30))
  );

  -- 4.2 En diagnóstico, con adelanto y ya fuera de plazo.
  v_orden_id := crear_orden_completa(
    jsonb_build_object('id', v_cli[2]),
    jsonb_build_object('empresa_id', v_empresa_id, 'tecnico_id', v_tecnico_id,
                       'prioridad', 'alta', 'adelanto', 50,
                       'metodo_adelanto', 'yape',
                       'fecha_prometida', (current_date - 3)::text),
    jsonb_build_object('tipo', 'computadora', 'marca', 'Dell', 'modelo', 'Optiplex',
                       'desperfecto', 'Reinicios aleatorios'),
    jsonb_build_array(jsonb_build_object('servicio_id', v_rep,
                                         'cantidad', 1, 'precio_unitario', 250))
  );
  update orden set estado = 'diagnostico' where id = v_orden_id;

  -- 4.3 En reparación, con descuento aplicado después.
  v_orden_id := crear_orden_completa(
    jsonb_build_object('id', v_cli[3]),
    jsonb_build_object('empresa_id', v_empresa_id, 'tecnico_id', v_tecnico_id,
                       'prioridad', 'urgente', 'adelanto', 100,
                       'fecha_prometida', (current_date + 1)::text),
    jsonb_build_object('tipo', 'impresora', 'marca', 'Epson', 'modelo', 'L3250',
                       'desperfecto', 'No imprime en color'),
    jsonb_build_array(
      jsonb_build_object('servicio_id', v_mant, 'cantidad', 1, 'precio_unitario', 80),
      jsonb_build_object('servicio_id', v_rep,  'cantidad', 1, 'precio_unitario', 250))
  );
  update orden set estado = 'en_progreso', descuento = 30 where id = v_orden_id;

  -- 4.4 Lista y pagada del todo, esperando desde hace días.
  v_orden_id := crear_orden_completa(
    jsonb_build_object('id', v_cli[4]),
    jsonb_build_object('empresa_id', v_empresa_id, 'tecnico_id', v_tecnico_id,
                       'adelanto', 150, 'metodo_adelanto', 'efectivo'),
    jsonb_build_object('tipo', 'laptop', 'marca', 'Lenovo', 'modelo', 'ThinkPad',
                       'desperfecto', 'Cambio de teclado'),
    jsonb_build_array(
      jsonb_build_object('servicio_id', v_mant, 'cantidad', 1, 'precio_unitario', 80),
      jsonb_build_object('servicio_id', v_soft, 'cantidad', 1, 'precio_unitario', 70))
  );
  update orden set estado = 'listo' where id = v_orden_id;
  -- El historial se atrasa a mano para ver la insignia de días del panel.
  update historial_estado
     set created_at = now() - interval '8 days'
   where orden_id = v_orden_id and estado_nuevo = 'listo';

  -- 4.5 Lista pero sin pagar: hay que cobrar al entregar.
  v_orden_id := crear_orden_completa(
    jsonb_build_object('id', v_cli[5]),
    jsonb_build_object('empresa_id', v_empresa_id, 'tecnico_id', v_tecnico_id,
                       'fecha_prometida', (current_date - 1)::text),
    jsonb_build_object('tipo', 'celular', 'marca', 'Samsung', 'modelo', 'A54',
                       'desperfecto', 'Pantalla rota'),
    jsonb_build_array(jsonb_build_object('servicio_id', v_rep,
                                         'cantidad', 1, 'precio_unitario', 250))
  );
  update orden set estado = 'listo' where id = v_orden_id;

  -- 4.6 Entregada y cobrada.
  v_orden_id := crear_orden_completa(
    jsonb_build_object('id', v_cli[6]),
    jsonb_build_object('empresa_id', v_empresa_id, 'tecnico_id', v_tecnico_id,
                       'adelanto', 80, 'metodo_adelanto', 'plin',
                       'fecha_prometida', (current_date - 9)::text),
    jsonb_build_object('tipo', 'fotocopiadora', 'marca', 'Ricoh', 'modelo', 'MP2014',
                       'desperfecto', 'Atasco de papel'),
    jsonb_build_array(jsonb_build_object('servicio_id', v_mant,
                                         'cantidad', 1, 'precio_unitario', 80))
  );
  update orden set estado = 'entregado' where id = v_orden_id;

  -- 4.7 Cancelada por el cliente.
  v_orden_id := crear_orden_completa(
    jsonb_build_object('id', v_cli[1]),
    jsonb_build_object('empresa_id', v_empresa_id, 'tecnico_id', v_tecnico_id,
                       'fecha_prometida', (current_date - 5)::text),
    jsonb_build_object('tipo', 'parlante', 'marca', 'JBL', 'modelo', 'Charge 4',
                       'desperfecto', 'No carga'),
    jsonb_build_array(jsonb_build_object('servicio_id', v_diag,
                                         'cantidad', 1, 'precio_unitario', 30))
  );
  update orden set estado = 'cancelado' where id = v_orden_id;

  -- 4.8 Sin reparación posible: se cobra el diagnóstico y se devuelve.
  v_orden_id := crear_orden_completa(
    jsonb_build_object('id', v_cli[2]),
    jsonb_build_object('empresa_id', v_empresa_id, 'tecnico_id', v_tecnico_id,
                       'adelanto', 30, 'metodo_adelanto', 'efectivo',
                       'fecha_prometida', (current_date - 4)::text),
    jsonb_build_object('tipo', 'tablet', 'marca', 'Huawei', 'modelo', 'MatePad',
                       'desperfecto', 'Placa quemada'),
    jsonb_build_array(jsonb_build_object('servicio_id', v_diag,
                                         'cantidad', 1, 'precio_unitario', 30))
  );
  update orden set estado = 'sin_reparacion' where id = v_orden_id;

  raise notice 'Taller de prueba creado: empresa %, técnico %', v_empresa_id, v_tecnico_id;
end $$;

-- Comprobación rápida de que los importes cuadran.
select numero_orden, estado, subtotal, descuento, total, saldo_pendiente,
       (select coalesce(sum(monto), 0) from pago p where p.orden_id = o.id) as pagado
  from orden o
 order by id;
