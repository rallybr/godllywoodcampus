-- =====================================================
-- VERIFICAR ESTRUTURA DA TABELA ROLES
-- =====================================================
-- Data: 2024-12-19
-- Objetivo: Verificar estrutura da tabela roles

-- =====================================================
-- 1. VERIFICAR ESTRUTURA DA TABELA ROLES
-- =====================================================

SELECT 
  'ESTRUTURA ROLES' as status,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'roles'
ORDER BY ordinal_position;

-- =====================================================
-- 2. VERIFICAR DADOS ATUAIS DA TABELA ROLES
-- =====================================================

SELECT 
  'DADOS ROLES' as status,
  *
FROM roles
LIMIT 5;

-- =====================================================
-- 3. VERIFICAR ESTRUTURA DA TABELA USER_ROLES
-- =====================================================

SELECT 
  'ESTRUTURA USER_ROLES' as status,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'user_roles'
ORDER BY ordinal_position;
