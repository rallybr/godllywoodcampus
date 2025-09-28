-- CORREÇÃO SIMPLES - Manter a assinatura original com p_edicao_id
-- Apenas corrigir o conflito de nomes na query

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
