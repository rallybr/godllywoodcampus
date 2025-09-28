-- Corrigir a função buscar_usuarios_com_ultimo_acesso
-- Primeiro remove a função existente e depois cria a nova

-- 1. Remover a função existente
DROP FUNCTION IF EXISTS public.buscar_usuarios_com_ultimo_acesso();

-- 2. Criar a função corrigida
CREATE OR REPLACE FUNCTION public.buscar_usuarios_com_ultimo_acesso()
RETURNS TABLE (
  id uuid,
  nome text,
  email text,
  nivel text,
  ativo boolean,
  foto text,
  sexo text,
  criado_em TIMESTAMP WITH TIME ZONE,
  estado_id uuid,
  bloco_id uuid,
  regiao_id uuid,
  igreja_id uuid,
  estado_bandeira text,
  ultimo_acesso TIMESTAMP WITH TIME ZONE,
  dias_sem_acesso INTEGER,
  status_acesso text
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.id,
    u.nome,
    u.email,
    u.nivel,
    u.ativo,
    u.foto,
    u.sexo,
    u.criado_em,
    u.estado_id,
    u.bloco_id,
    u.regiao_id,
    u.igreja_id,
    u.estado_bandeira,
    u.ultimo_acesso,
    CASE 
      WHEN u.ultimo_acesso IS NULL THEN NULL
      ELSE EXTRACT(DAY FROM (NOW() - u.ultimo_acesso))::INTEGER
    END as dias_sem_acesso,
    CASE 
      WHEN u.ultimo_acesso IS NULL THEN 'Nunca acessou'
      WHEN u.ultimo_acesso > NOW() - INTERVAL '1 day' THEN 'Ativo (últimas 24h)'
      WHEN u.ultimo_acesso > NOW() - INTERVAL '7 days' THEN 'Ativo (última semana)'
      WHEN u.ultimo_acesso > NOW() - INTERVAL '30 days' THEN 'Inativo (último mês)'
      ELSE 'Muito inativo'
    END as status_acesso
  FROM public.usuarios u
  ORDER BY u.ultimo_acesso DESC NULLS LAST;
END;
$$;
