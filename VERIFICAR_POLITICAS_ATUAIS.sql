-- =====================================================
-- VERIFICAÇÃO DAS POLÍTICAS RLS ATUAIS NO BANCO
-- =====================================================
-- Data: 2024-12-19
-- Objetivo: Verificar quais políticas RLS estão ativas no banco

-- =====================================================
-- 1. VERIFICAR STATUS DO RLS EM TODAS AS TABELAS
-- =====================================================

SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_habilitado
FROM pg_tables 
WHERE schemaname = 'public' 
ORDER BY tablename;

-- =====================================================
-- 2. VERIFICAR POLÍTICAS EXISTENTES
-- =====================================================

SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- =====================================================
-- 3. VERIFICAR FUNÇÕES AUXILIARES
-- =====================================================

SELECT 
  proname as nome_funcao,
  prosrc as codigo_funcao
FROM pg_proc 
WHERE proname IN ('is_admin_user', 'criar_log_auditoria', 'recalcular_idade')
ORDER BY proname;

-- =====================================================
-- 4. VERIFICAR BUCKETS DE STORAGE
-- =====================================================

SELECT 
  name as bucket_name,
  public as is_public,
  created_at
FROM storage.buckets
ORDER BY name;

-- =====================================================
-- 5. VERIFICAR POLÍTICAS DE STORAGE
-- =====================================================

SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies 
WHERE schemaname = 'storage'
ORDER BY tablename, policyname;

-- =====================================================
-- 6. VERIFICAR ÍNDICES IMPORTANTES
-- =====================================================

SELECT 
  indexname,
  tablename,
  indexdef
FROM pg_indexes 
WHERE schemaname = 'public' 
AND indexname LIKE 'idx_%'
ORDER BY tablename, indexname;

-- =====================================================
-- 7. VERIFICAR TRIGGERS
-- =====================================================

SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table, trigger_name;

-- =====================================================
-- 8. VERIFICAR CONSTRAINTS IMPORTANTES
-- =====================================================

SELECT 
  tc.table_name,
  tc.constraint_name,
  tc.constraint_type,
  kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
  ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_schema = 'public'
AND tc.constraint_type IN ('PRIMARY KEY', 'FOREIGN KEY', 'UNIQUE', 'CHECK')
ORDER BY tc.table_name, tc.constraint_type;

-- =====================================================
-- 9. VERIFICAR VIEWS
-- =====================================================

SELECT 
  table_name as view_name,
  view_definition
FROM information_schema.views
WHERE table_schema = 'public'
ORDER BY table_name;

-- =====================================================
-- 10. VERIFICAR DADOS DE TESTE
-- =====================================================

-- Contar registros em cada tabela principal
SELECT 'usuarios' as tabela, count(*) as total FROM usuarios
UNION ALL
SELECT 'jovens' as tabela, count(*) as total FROM jovens
UNION ALL
SELECT 'avaliacoes' as tabela, count(*) as total FROM avaliacoes
UNION ALL
SELECT 'roles' as tabela, count(*) as total FROM roles
UNION ALL
SELECT 'user_roles' as tabela, count(*) as total FROM user_roles
UNION ALL
SELECT 'notificacoes' as tabela, count(*) as total FROM notificacoes
UNION ALL
SELECT 'logs_historico' as tabela, count(*) as total FROM logs_historico
UNION ALL
SELECT 'logs_auditoria' as tabela, count(*) as total FROM logs_auditoria
ORDER BY tabela;
