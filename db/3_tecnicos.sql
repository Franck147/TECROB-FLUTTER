-- ═══════════════════════════════════════════════════════════════════════════
--  TecrobSys · Paso 3 · Dar acceso a tus usuarios
-- ═══════════════════════════════════════════════════════════════════════════
--
-- La app sólo deja entrar a quien tiene una fila activa en tecnico ligada a su
-- usuario de Supabase. Una base recién creada no tiene ninguna, así que sin
-- este paso inicias sesión y la app no te muestra nada.
--
-- Requisitos: haber ejecutado db/2_esquema.sql, y que los usuarios existan en
-- Authentication > Users. Este archivo no crea usuarios ni contraseñas.
--
-- Se puede ejecutar las veces que haga falta: si el técnico ya existe, lo
-- actualiza y lo reactiva. Si ninguno de los correos existe, se detiene y te
-- dice qué usuarios hay en Supabase.

do $$
declare
  -- ── Cambia esto por tus usuarios ─────────────────────────────────────────
  --    Cada fila: correo, nombre, rol ('administrador' o 'tecnico').
  v_usuarios constant text[] := array[
    ['adleradmin@tecrob.com', 'Adler', 'administrador'],
    ['adler@tecrob.com',      'Adler', 'tecnico']
  ];

  v_fila    text[];
  v_auth_id uuid;
  v_creados integer := 0;
  v_faltan  text[] := '{}';
  v_existen text;
begin
  foreach v_fila slice 1 in array v_usuarios loop
    select id into v_auth_id
      from auth.users
     where lower(email) = lower(v_fila[1]);

    if v_auth_id is null then
      v_faltan := array_append(v_faltan, v_fila[1]);
      continue;
    end if;

    insert into tecnico (auth_user_id, nombre, email, rol)
    values (v_auth_id, v_fila[2], v_fila[1], v_fila[3])
    on conflict (auth_user_id) do update
       set nombre = excluded.nombre,
           email  = excluded.email,
           rol    = excluded.rol,
           activo = true;

    v_creados := v_creados + 1;
  end loop;

  if v_creados = 0 then
    select string_agg(email, ', ' order by email) into v_existen from auth.users;
    raise exception
      'Ninguno de estos correos existe en Supabase: %. Los que sí existen son: %. Cambia los correos al inicio de este archivo.',
      array_to_string(v_faltan, ', '),
      coalesce(v_existen, 'ninguno, créalos en Authentication > Users');
  end if;

  if cardinality(v_faltan) > 0 then
    raise notice 'Se saltaron porque no existen en Supabase: %',
      array_to_string(v_faltan, ', ');
  end if;
end $$;

-- Quién tiene acceso ahora.
select id, nombre, email, rol, activo
  from tecnico
 order by id;
