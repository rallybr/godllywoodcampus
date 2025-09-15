-- =====================================================
-- VERIFICAÇÃO DETALHADA DAS POLÍTICAS RLS
-- =====================================================
-- Data: 2024-12-19
-- Objetivo: Ver detalhes específicos das políticas implementadas

-- =====================================================
-- 1. POLÍTICAS POR TABELA (DETALHADO)
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
-- 2. POLÍTICAS DE STORAGE (DETALHADO)
-- =====================================================

SELECT 
  tablename as tabela,
  policyname as politica,
  cmd as operacao
FROM pg_policies 
WHERE schemaname = 'storage'
ORDER BY tablename, policyname;

-- =====================================================
-- 3. FUNÇÕES AUXILIARES (DETALHADO)
-- =====================================================

SELECT 
  proname as nome_funcao,
  prokind as tipo_funcao,
  prosecdef as security_definer,
  proisstrict as is_strict
FROM pg_proc 
WHERE proname IN ('is_admin_user', 'has_role', 'can_access_jovem', 'criar_log_auditoria', 'recalcular_idade')
ORDER BY proname;

-- =====================================================
-- 4. BUCKETS DE STORAGE (DETALHADO)
-- =====================================================

SELECT 
  name as bucket_name,
  public as is_public,
  created_at,
  updated_at
FROM storage.buckets
ORDER BY name;

-- =====================================================
-- 5. VERIFICAR POLÍTICAS CRÍTICAS ESPECÍFICAS
-- =====================================================

-- Verificar se as políticas mais importantes existem
SELECT 
  'POLÍTICAS CRÍTICAS' as status,
  tablename,
  policyname,
  CASE 
    WHEN policyname LIKE '%admin%' THEN '🔑 ADMIN'
    WHEN policyname LIKE '%self%' THEN '👤 SELF'
    WHEN policyname LIKE '%hierarchy%' THEN '🏢 HIERARCHY'
    WHEN policyname LIKE '%system%' THEN '⚙️ SYSTEM'
    ELSE '📋 OTHER'
  END as categoria
FROM pg_policies 
WHERE schemaname = 'public'
  AND (
    policyname LIKE '%admin%' OR
    policyname LIKE '%self%' OR
    policyname LIKE '%hierarchy%' OR
    policyname LIKE '%system%' OR
    policyname LIKE '%colab%'
  )
ORDER BY tablename, categoria, policyname;

-- =====================================================
-- 6. CONTAGEM POR CATEGORIA DE POLÍTICA
-- =====================================================

SELECT 
  'CATEGORIAS' as status,
  CASE 
    WHEN policyname LIKE '%admin%' THEN 'Admin'
    WHEN policyname LIKE '%self%' THEN 'Self'
    WHEN policyname LIKE '%hierarchy%' THEN 'Hierarchy'
    WHEN policyname LIKE '%system%' THEN 'System'
    WHEN policyname LIKE '%colab%' THEN 'Colaborador'
    ELSE 'Outras'
  END as categoria,
  count(*) as total
FROM pg_policies 
WHERE schemaname = 'public'
GROUP BY 
  CASE 
    WHEN policyname LIKE '%admin%' THEN 'Admin'
    WHEN policyname LIKE '%self%' THEN 'Self'
    WHEN policyname LIKE '%hierarchy%' THEN 'Hierarchy'
    WHEN policyname LIKE '%system%' THEN 'System'
    WHEN policyname LIKE '%colab%' THEN 'Colaborador'
    ELSE 'Outras'
  END
ORDER BY total DESC;
