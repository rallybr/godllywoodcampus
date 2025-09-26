-- Script para criar função RPC que contorna RLS para estatísticas por estado
-- Execute este script no Supabase SQL Editor

-- ============================================
-- 1. CRIAR FUNÇÃO RPC PARA CONTAGEM DE JOVENS POR ESTADO
-- ============================================

CREATE OR REPLACE FUNCTION get_jovens_por_estado_count(edicao_id uuid DEFAULT NULL)
RETURNS TABLE (
  estado_id uuid,
  total bigint
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Esta função contorna RLS para permitir que líderes vejam estatísticas
  -- mesmo quando as políticas RLS limitam o acesso direto à tabela jovens
  
  RETURN QUERY
  SELECT 
    j.estado_id,
    COUNT(*) as total
  FROM public.jovens j
  WHERE j.estado_id IS NOT NULL
    AND (get_jovens_por_estado_count.edicao_id IS NULL OR j.edicao_id = get_jovens_por_estado_count.edicao_id)
  GROUP BY j.estado_id;
END;
$$;

-- ============================================
-- 2. CONCEDER PERMISSÕES
-- ============================================

GRANT EXECUTE ON FUNCTION get_jovens_por_estado_count(uuid) TO authenticated;

-- ============================================
-- 3. TESTAR A FUNÇÃO
-- ============================================

-- Teste básico
SELECT * FROM get_jovens_por_estado_count();

-- Teste com edição específica (se houver)
-- SELECT * FROM get_jovens_por_estado_count('id-da-edicao-aqui');
