CREATE OR REPLACE FUNCTION public.can_access_jovem(
  jovem_estado_id uuid,
  jovem_bloco_id uuid,
  jovem_regiao_id uuid,
  jovem_igreja_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_user_id uuid;
  user_info record;
BEGIN
  current_user_id := (SELECT id FROM public.usuarios WHERE id_auth = auth.uid());
  IF current_user_id IS NULL THEN RETURN false; END IF;

  SELECT 
    id,
    nivel,
    estado_id,
    bloco_id,
    regiao_id,
    igreja_id
  INTO user_info
  FROM public.usuarios
  WHERE id = current_user_id;

  IF user_info IS NULL THEN RETURN false; END IF;

  IF user_info.nivel = 'administrador' THEN RETURN true; END IF;

  IF user_info.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju') THEN RETURN true; END IF;

  IF user_info.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') THEN
    RETURN user_info.estado_id = jovem_estado_id;
  END IF;

  IF user_info.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') THEN
    RETURN user_info.bloco_id = jovem_bloco_id;
  END IF;

  IF user_info.nivel = 'lider_regional_iurd' THEN
    RETURN user_info.regiao_id = jovem_regiao_id;
  END IF;

  IF user_info.nivel = 'lider_igreja_iurd' THEN
    RETURN user_info.igreja_id = jovem_igreja_id;
  END IF;

  IF user_info.nivel = 'colaborador' THEN
    RETURN EXISTS (
      SELECT 1 FROM public.jovens j
      WHERE j.estado_id = jovem_estado_id
        AND j.bloco_id = jovem_bloco_id
        AND j.regiao_id = jovem_regiao_id
        AND j.igreja_id = jovem_igreja_id
        AND j.usuario_id = current_user_id
    );
  END IF;

  IF user_info.nivel = 'jovem' THEN
    RETURN EXISTS (
      SELECT 1 FROM public.jovens j
      WHERE j.estado_id = jovem_estado_id
        AND j.bloco_id = jovem_bloco_id
        AND j.regiao_id = jovem_regiao_id
        AND j.igreja_id = jovem_igreja_id
        AND j.usuario_id = current_user_id
    );
  END IF;

  RETURN false;
END;
$$;
