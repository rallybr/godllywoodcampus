-- =====================================================
-- VERIFICAR ESTRUTURA DA TABELA JOVENS
-- =====================================================
-- Data: 2024-12-19
-- Objetivo: Verificar estrutura real da tabela jovens

-- =====================================================
-- 1. VERIFICAR ESTRUTURA DA TABELA JOVENS
-- =====================================================

SELECT 
  'ESTRUTURA JOVENS' as status,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'jovens'
ORDER BY ordinal_position;

-- =====================================================
-- 2. VERIFICAR DADOS ATUAIS DA TABELA JOVENS
-- =====================================================

SELECT 
  'DADOS JOVENS' as status,
  *
FROM jovens
LIMIT 3;

-- =====================================================
-- 3. VERIFICAR SE EXISTEM OUTRAS TABELAS RELACIONADAS
-- =====================================================

SELECT 
  'TABELAS RELACIONADAS' as status,
  table_name,
  table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name LIKE '%jovem%'
ORDER BY table_name;
