-- Corrigir função RPC get_jovens_por_estado_count
-- Baseado na estrutura real das tabelas

-- Primeiro, dropar a função existente se houver
DROP FUNCTION IF EXISTS public.get_jovens_por_estado_count(uuid);

-- Criar a função corrigida baseada na estrutura real
CREATE OR REPLACE FUNCTION public.get_jovens_por_estado_count(p_edicao_id uuid DEFAULT NULL)
RETURNS TABLE (
  estado_id uuid,
  total bigint
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    j.estado_id,
    COUNT(*) as total
  FROM public.jovens j
  WHERE j.estado_id IS NOT NULL
    AND (p_edicao_id IS NULL OR j.edicao_id = p_edicao_id)
  GROUP BY j.estado_id;
END;
$$;

-- Testar a função
SELECT 'Testando função sem parâmetros:' as teste;
SELECT * FROM public.get_jovens_por_estado_count();

SELECT 'Testando função com NULL:' as teste;
SELECT * FROM public.get_jovens_por_estado_count(NULL);

-- Verificar se a função foi criada
SELECT 
  routine_name, 
  routine_type, 
  data_type
FROM information_schema.routines 
WHERE routine_name = 'get_jovens_por_estado_count'
AND routine_schema = 'public';
