-- =====================================================
-- DIAGNÓSTICO ESPECÍFICO DO ERRO RLS
-- =====================================================
-- Data: 2024-12-19
-- Objetivo: Identificar exatamente qual operação está falhando

-- =====================================================
-- 1. VERIFICAR POLÍTICAS DE INSERT POR TABELA
-- =====================================================

SELECT 
  'INSERT POLICIES' as status,
  tablename as tabela,
  policyname as politica,
  cmd as operacao,
  permissive as permissiva
FROM pg_policies 
WHERE schemaname = 'public' 
  AND (cmd = 'INSERT' OR cmd = 'ALL')
ORDER BY tablename, policyname;

-- =====================================================
-- 2. VERIFICAR SE HÁ POLÍTICAS RESTRITIVAS
-- =====================================================

SELECT 
  'RESTRICTIVE POLICIES' as status,
  tablename as tabela,
  policyname as politica,
  cmd as operacao,
  permissive as permissiva
FROM pg_policies 
WHERE schemaname = 'public' 
  AND permissive = false
ORDER BY tablename, policyname;

-- =====================================================
-- 3. VERIFICAR FUNÇÕES AUXILIARES
-- =====================================================

SELECT 
  'FUNCTIONS STATUS' as status,
  proname as nome_funcao,
  prosecdef as security_definer,
  proisstrict as is_strict,
  prokind as tipo_funcao
FROM pg_proc 
WHERE proname IN ('is_admin_user', 'has_role', 'can_access_jovem', 'criar_log_auditoria', 'recalcular_idade')
ORDER BY proname;

-- =====================================================
-- 4. VERIFICAR USUÁRIO ATUAL E ROLES
-- =====================================================

-- Esta query vai falhar se não estiver logado, mas é importante
SELECT 
  'CURRENT USER' as status,
  auth.uid() as user_id,
  current_user as current_user,
  session_user as session_user;

-- =====================================================
-- 5. VERIFICAR ROLES DO USUÁRIO ATUAL
-- =====================================================

-- Esta query também pode falhar se não estiver logado
SELECT 
  'USER ROLES' as status,
  u.id as usuario_id,
  u.nome as usuario_nome,
  r.slug as role_slug,
  ur.ativo as role_ativo
FROM usuarios u
JOIN user_roles ur ON ur.user_id = u.id
JOIN roles r ON r.id = ur.role_id
WHERE u.id_auth = auth.uid()
ORDER BY r.slug;

-- =====================================================
-- 6. VERIFICAR POLÍTICAS DE STORAGE
-- =====================================================

SELECT 
  'STORAGE POLICIES' as status,
  policyname as politica,
  cmd as operacao
FROM pg_policies 
WHERE schemaname = 'storage'
ORDER BY policyname;

-- =====================================================
-- 7. VERIFICAR BUCKETS DE STORAGE
-- =====================================================

SELECT 
  'STORAGE BUCKETS' as status,
  name as bucket_name,
  public as is_public,
  created_at
FROM storage.buckets
ORDER BY name;

-- =====================================================
-- 8. TESTAR POLÍTICAS CRÍTICAS
-- =====================================================

-- Verificar se as políticas principais estão funcionando
SELECT 
  'POLICY TEST' as status,
  'is_admin_user()' as funcao,
  is_admin_user() as resultado;

SELECT 
  'POLICY TEST' as status,
  'has_role(administrador)' as funcao,
  has_role('administrador') as resultado;

-- =====================================================
-- 9. VERIFICAR TABELAS SEM POLÍTICAS DE INSERT
-- =====================================================

WITH tabelas_principais AS (
  SELECT unnest(ARRAY['usuarios', 'jovens', 'avaliacoes', 'edicoes', 'roles', 'user_roles', 'logs_historico', 'notificacoes', 'logs_auditoria', 'configuracoes_sistema', 'sessoes_usuario']) as tabela
),
politicas_insert AS (
  SELECT DISTINCT tablename
  FROM pg_policies 
  WHERE schemaname = 'public' 
    AND (cmd = 'INSERT' OR cmd = 'ALL')
)
SELECT 
  'MISSING INSERT' as status,
  tp.tabela,
  CASE 
    WHEN pi.tablename IS NULL THEN '❌ SEM POLÍTICA INSERT'
    ELSE '✅ TEM POLÍTICA INSERT'
  END as status_politica
FROM tabelas_principais tp
LEFT JOIN politicas_insert pi ON tp.tabela = pi.tablename
ORDER BY tp.tabela;
