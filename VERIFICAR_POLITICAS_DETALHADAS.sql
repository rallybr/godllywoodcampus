-- =====================================================
-- VERIFICAÇÃO DETALHADA DAS POLÍTICAS RLS ESPECÍFICAS
-- =====================================================
-- Data: 2024-12-19
-- Objetivo: Verificar políticas específicas por tabela

-- =====================================================
-- 1. POLÍTICAS DA TABELA USUARIOS
-- =====================================================

SELECT 
  'USUARIOS' as tabela,
  policyname as politica,
  cmd as operacao,
  permissive as permissiva
FROM pg_policies 
WHERE schemaname = 'public' AND tablename = 'usuarios'
ORDER BY policyname;

-- =====================================================
-- 2. POLÍTICAS DA TABELA JOVENS
-- =====================================================

SELECT 
  'JOVENS' as tabela,
  policyname as politica,
  cmd as operacao,
  permissive as permissiva
FROM pg_policies 
WHERE schemaname = 'public' AND tablename = 'jovens'
ORDER BY policyname;

-- =====================================================
-- 3. POLÍTICAS DA TABELA AVALIACOES
-- =====================================================

SELECT 
  'AVALIACOES' as tabela,
  policyname as politica,
  cmd as operacao,
  permissive as permissiva
FROM pg_policies 
WHERE schemaname = 'public' AND tablename = 'avaliacoes'
ORDER BY policyname;

-- =====================================================
-- 4. POLÍTICAS DA TABELA NOTIFICACOES
-- =====================================================

SELECT 
  'NOTIFICACOES' as tabela,
  policyname as politica,
  cmd as operacao,
  permissive as permissiva
FROM pg_policies 
WHERE schemaname = 'public' AND tablename = 'notificacoes'
ORDER BY policyname;

-- =====================================================
-- 5. POLÍTICAS DE STORAGE
-- =====================================================

SELECT 
  'STORAGE' as tipo,
  policyname as politica,
  cmd as operacao
FROM pg_policies 
WHERE schemaname = 'storage'
ORDER BY policyname;

-- =====================================================
-- 6. VERIFICAR FUNÇÕES AUXILIARES
-- =====================================================

SELECT 
  'FUNCOES' as tipo,
  proname as nome_funcao,
  prokind as tipo_funcao,
  prosecdef as security_definer
FROM pg_proc 
WHERE proname IN ('is_admin_user', 'has_role', 'can_access_jovem', 'criar_log_auditoria', 'recalcular_idade')
ORDER BY proname;

-- =====================================================
-- 7. VERIFICAR BUCKETS DE STORAGE
-- =====================================================

SELECT 
  'BUCKETS' as tipo,
  name as bucket_name,
  public as is_public
FROM storage.buckets
ORDER BY name;

-- =====================================================
-- 8. RESUMO DE POLÍTICAS CRÍTICAS
-- =====================================================

-- Verificar se as políticas mais importantes existem
SELECT 
  'POLÍTICAS CRÍTICAS' as status,
  tablename,
  policyname,
  cmd,
  CASE 
    WHEN policyname LIKE '%admin%' THEN '🔑 ADMIN'
    WHEN policyname LIKE '%self%' THEN '👤 SELF'
    WHEN policyname LIKE '%hierarchy%' THEN '🏢 HIERARCHY'
    WHEN policyname LIKE '%system%' THEN '⚙️ SYSTEM'
    WHEN policyname LIKE '%colab%' THEN '👥 COLAB'
    WHEN policyname LIKE '%lider%' THEN '👑 LIDER'
    ELSE '📋 OTHER'
  END as categoria
FROM pg_policies 
WHERE schemaname = 'public'
  AND (
    policyname LIKE '%admin%' OR
    policyname LIKE '%self%' OR
    policyname LIKE '%hierarchy%' OR
    policyname LIKE '%system%' OR
    policyname LIKE '%colab%' OR
    policyname LIKE '%lider%'
  )
ORDER BY tablename, categoria, policyname;
