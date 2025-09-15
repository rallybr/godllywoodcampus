-- =====================================================
-- VERIFICAÇÃO ESPECÍFICA DAS POLÍTICAS RLS
-- =====================================================
-- Data: 2024-12-19
-- Objetivo: Verificar políticas específicas por tabela

-- =====================================================
-- 1. POLÍTICAS POR TABELA (COMPLETO)
-- =====================================================

SELECT 
  tablename as tabela,
  policyname as politica,
  cmd as operacao,
  permissive as permissiva
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- =====================================================
-- 2. VERIFICAR POLÍTICAS CRÍTICAS POR TABELA
-- =====================================================

-- Usuários
SELECT 
  'USUARIOS' as tabela,
  policyname as politica,
  cmd as operacao,
  CASE 
    WHEN policyname LIKE '%admin%' THEN '🔑 ADMIN'
    WHEN policyname LIKE '%self%' THEN '👤 SELF'
    WHEN policyname LIKE '%colab%' THEN '👥 COLAB'
    ELSE '📋 OTHER'
  END as tipo
FROM pg_policies 
WHERE schemaname = 'public' AND tablename = 'usuarios'
ORDER BY policyname;

-- Jovens
SELECT 
  'JOVENS' as tabela,
  policyname as politica,
  cmd as operacao,
  CASE 
    WHEN policyname LIKE '%admin%' THEN '🔑 ADMIN'
    WHEN policyname LIKE '%lider%' THEN '🏢 LIDER'
    WHEN policyname LIKE '%hierarchy%' THEN '🏢 HIERARCHY'
    ELSE '📋 OTHER'
  END as tipo
FROM pg_policies 
WHERE schemaname = 'public' AND tablename = 'jovens'
ORDER BY policyname;

-- Avaliações
SELECT 
  'AVALIACOES' as tabela,
  policyname as politica,
  cmd as operacao,
  CASE 
    WHEN policyname LIKE '%admin%' THEN '🔑 ADMIN'
    WHEN policyname LIKE '%self%' THEN '👤 SELF'
    WHEN policyname LIKE '%jovem%' THEN '👥 JOVEM'
    ELSE '📋 OTHER'
  END as tipo
FROM pg_policies 
WHERE schemaname = 'public' AND tablename = 'avaliacoes'
ORDER BY policyname;

-- =====================================================
-- 3. VERIFICAR POLÍTICAS DE STORAGE
-- =====================================================

SELECT 
  'STORAGE' as tipo,
  policyname as politica,
  cmd as operacao,
  CASE 
    WHEN policyname LIKE '%usuarios%' THEN '👤 USUARIOS'
    WHEN policyname LIKE '%jovens%' THEN '👥 JOVENS'
    WHEN policyname LIKE '%documentos%' THEN '📄 DOCUMENTOS'
    WHEN policyname LIKE '%backups%' THEN '💾 BACKUPS'
    WHEN policyname LIKE '%temp%' THEN '🗂️ TEMP'
    ELSE '📋 OTHER'
  END as categoria
FROM pg_policies 
WHERE schemaname = 'storage'
ORDER BY policyname;

-- =====================================================
-- 4. VERIFICAR FUNÇÕES AUXILIARES
-- =====================================================

SELECT 
  'FUNCOES' as tipo,
  proname as nome_funcao,
  prokind as tipo_funcao,
  prosecdef as security_definer,
  proisstrict as is_strict
FROM pg_proc 
WHERE proname IN ('is_admin_user', 'has_role', 'can_access_jovem', 'criar_log_auditoria', 'recalcular_idade')
ORDER BY proname;

-- =====================================================
-- 5. VERIFICAR BUCKETS DE STORAGE
-- =====================================================

SELECT 
  'BUCKETS' as tipo,
  name as bucket_name,
  public as is_public,
  created_at,
  updated_at
FROM storage.buckets
ORDER BY name;

-- =====================================================
-- 6. RESUMO POR TABELA
-- =====================================================

SELECT 
  tablename as tabela,
  count(*) as total_politicas,
  count(CASE WHEN cmd = 'SELECT' THEN 1 END) as select_policies,
  count(CASE WHEN cmd = 'INSERT' THEN 1 END) as insert_policies,
  count(CASE WHEN cmd = 'UPDATE' THEN 1 END) as update_policies,
  count(CASE WHEN cmd = 'DELETE' THEN 1 END) as delete_policies,
  count(CASE WHEN cmd = 'ALL' THEN 1 END) as all_policies
FROM pg_policies 
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;
