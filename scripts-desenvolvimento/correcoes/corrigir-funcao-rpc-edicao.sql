-- Corrigir a função RPC para filtrar corretamente por edição
CREATE OR REPLACE FUNCTION public.get_jovens_por_estado_count(p_edicao_id uuid DEFAULT NULL)
RETURNS TABLE(estado_id uuid, total bigint)
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

-- Testar a função corrigida
SELECT 'Teste - Todas as edições' as teste, COUNT(*) as total FROM public.get_jovens_por_estado_count(NULL);
SELECT 'Teste - 3ª Edição' as teste, COUNT(*) as total FROM public.get_jovens_por_estado_count('27717445-8ad1-4c7a-ad1d-55621011f7b4');
SELECT 'Teste - 2ª Edição' as teste, COUNT(*) as total FROM public.get_jovens_por_estado_count('c6512ce8-7ad6-49fa-8a4e-632eff239b4e');
