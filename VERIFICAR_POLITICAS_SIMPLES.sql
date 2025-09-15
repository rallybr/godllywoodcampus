-- =====================================================
-- VERIFICAÇÃO SIMPLES DAS POLÍTICAS RLS ATUAIS
-- =====================================================
-- Data: 2024-12-19
-- Objetivo: Verificar de forma simples quais políticas existem

-- =====================================================
-- 1. POLÍTICAS ATUAIS POR TABELA
-- =====================================================

SELECT 
  'POLÍTICAS ATUAIS' as status,
  tablename as tabela,
  policyname as politica,
  cmd as operacao
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- =====================================================
-- 2. CONTAGEM DE POLÍTICAS POR TABELA
-- =====================================================

SELECT 
  'CONTAGEM' as status,
  tablename as tabela,
  count(*) as total_politicas,
  string_agg(policyname, ', ' ORDER BY policyname) as politicas
FROM pg_policies 
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;

-- =====================================================
-- 3. FUNÇÕES AUXILIARES EXISTENTES
-- =====================================================

SELECT 
  'FUNÇÕES' as status,
  proname as nome_funcao,
  CASE 
    WHEN proname = 'is_admin_user' THEN '✅ NECESSÁRIA'
    WHEN proname = 'has_role' THEN '✅ NECESSÁRIA' 
    WHEN proname = 'can_access_jovem' THEN '✅ NECESSÁRIA'
    WHEN proname = 'criar_log_auditoria' THEN '✅ NECESSÁRIA'
    WHEN proname = 'recalcular_idade' THEN '✅ NECESSÁRIA'
    ELSE '❓ VERIFICAR'
  END as status_funcao
FROM pg_proc 
WHERE proname IN ('is_admin_user', 'has_role', 'can_access_jovem', 'criar_log_auditoria', 'recalcular_idade')
ORDER BY proname;

-- =====================================================
-- 4. BUCKETS DE STORAGE
-- =====================================================

SELECT 
  'BUCKETS' as status,
  name as bucket_name,
  public as is_public,
  CASE 
    WHEN name = 'fotos_usuarios' THEN '✅ NECESSÁRIO'
    WHEN name = 'fotos_jovens' THEN '✅ NECESSÁRIO'
    WHEN name = 'documentos' THEN '✅ NECESSÁRIO'
    WHEN name = 'backups' THEN '✅ NECESSÁRIO'
    WHEN name = 'temp' THEN '✅ NECESSÁRIO'
    ELSE '❓ VERIFICAR'
  END as status_bucket
FROM storage.buckets
ORDER BY name;

-- =====================================================
-- 5. POLÍTICAS DE STORAGE
-- =====================================================

SELECT 
  'STORAGE' as status,
  tablename as tabela,
  policyname as politica,
  cmd as operacao
FROM pg_policies 
WHERE schemaname = 'storage'
ORDER BY tablename, policyname;

-- =====================================================
-- 6. RESUMO GERAL
-- =====================================================

SELECT 
  'RESUMO GERAL' as status,
  'Políticas RLS' as tipo,
  count(*) as total
FROM pg_policies 
WHERE schemaname = 'public'

UNION ALL

SELECT 
  'RESUMO GERAL' as status,
  'Políticas Storage' as tipo,
  count(*) as total
FROM pg_policies 
WHERE schemaname = 'storage'

UNION ALL

SELECT 
  'RESUMO GERAL' as status,
  'Funções Auxiliares' as tipo,
  count(*) as total
FROM pg_proc 
WHERE proname IN ('is_admin_user', 'has_role', 'can_access_jovem', 'criar_log_auditoria', 'recalcular_idade')

UNION ALL

SELECT 
  'RESUMO GERAL' as status,
  'Buckets Storage' as tipo,
  count(*) as total
FROM storage.buckets;
