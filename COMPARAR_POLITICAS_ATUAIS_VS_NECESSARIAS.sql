-- =====================================================
-- COMPARAÇÃO: POLÍTICAS ATUAIS VS NECESSÁRIAS
-- =====================================================
-- Data: 2024-12-19
-- Objetivo: Verificar quais políticas estão implementadas e quais faltam

-- =====================================================
-- 1. VERIFICAR POLÍTICAS ATUAIS NO BANCO
-- =====================================================

SELECT 
  'POLÍTICAS ATUAIS' as status,
  schemaname,
  tablename,
  policyname,
  cmd,
  permissive
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- =====================================================
-- 2. VERIFICAR FUNÇÕES AUXILIARES EXISTENTES
-- =====================================================

SELECT 
  'FUNÇÕES AUXILIARES' as status,
  proname as nome_funcao,
  CASE 
    WHEN proname = 'is_admin_user' THEN '✅ NECESSÁRIA'
    WHEN proname = 'has_role' THEN '✅ NECESSÁRIA' 
    WHEN proname = 'can_access_jovem' THEN '✅ NECESSÁRIA'
    ELSE '❓ VERIFICAR'
  END as status_funcao
FROM pg_proc 
WHERE proname IN ('is_admin_user', 'has_role', 'can_access_jovem', 'criar_log_auditoria', 'recalcular_idade')
ORDER BY proname;

-- =====================================================
-- 3. VERIFICAR BUCKETS DE STORAGE
-- =====================================================

SELECT 
  'BUCKETS STORAGE' as status,
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
-- 4. VERIFICAR POLÍTICAS DE STORAGE
-- =====================================================

SELECT 
  'POLÍTICAS STORAGE' as status,
  schemaname,
  tablename,
  policyname,
  cmd
FROM pg_policies 
WHERE schemaname = 'storage'
ORDER BY tablename, policyname;

-- =====================================================
-- 5. RESUMO DE POLÍTICAS POR TABELA
-- =====================================================

SELECT 
  tablename,
  count(*) as total_politicas,
  string_agg(policyname, ', ' ORDER BY policyname) as politicas
FROM pg_policies 
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;

-- =====================================================
-- 6. VERIFICAR SE AS POLÍTICAS NECESSÁRIAS ESTÃO IMPLEMENTADAS
-- =====================================================

-- Políticas necessárias para cada tabela
WITH politicas_necessarias AS (
  SELECT 'usuarios' as tabela, 'usuarios_admin_full' as politica
  UNION ALL SELECT 'usuarios', 'usuarios_self_select'
  UNION ALL SELECT 'usuarios', 'usuarios_self_update'
  UNION ALL SELECT 'usuarios', 'usuarios_colaborador_select'
  
  UNION ALL SELECT 'jovens', 'jovens_admin_colab'
  UNION ALL SELECT 'jovens', 'jovens_lider_estadual'
  UNION ALL SELECT 'jovens', 'jovens_lider_bloco'
  UNION ALL SELECT 'jovens', 'jovens_lider_regional'
  UNION ALL SELECT 'jovens', 'jovens_lider_igreja'
  
  UNION ALL SELECT 'avaliacoes', 'avaliacoes_admin_colab'
  UNION ALL SELECT 'avaliacoes', 'avaliacoes_by_jovem_access'
  UNION ALL SELECT 'avaliacoes', 'avaliacoes_insert_by_jovem_access'
  UNION ALL SELECT 'avaliacoes', 'avaliacoes_self_update'
  UNION ALL SELECT 'avaliacoes', 'avaliacoes_self_delete'
  
  UNION ALL SELECT 'edicoes', 'edicoes_select_all'
  UNION ALL SELECT 'edicoes', 'edicoes_admin_modify'
  
  UNION ALL SELECT 'roles', 'roles_select_all'
  UNION ALL SELECT 'roles', 'roles_admin_modify'
  
  UNION ALL SELECT 'user_roles', 'user_roles_admin_colab'
  UNION ALL SELECT 'user_roles', 'user_roles_self_select'
  
  UNION ALL SELECT 'logs_historico', 'logs_historico_admin_colab'
  UNION ALL SELECT 'logs_historico', 'logs_historico_by_jovem_access'
  UNION ALL SELECT 'logs_historico', 'logs_historico_system_insert'
  
  UNION ALL SELECT 'notificacoes', 'notificacoes_self'
  UNION ALL SELECT 'notificacoes', 'notificacoes_system_insert'
  
  UNION ALL SELECT 'logs_auditoria', 'logs_auditoria_admin'
  UNION ALL SELECT 'logs_auditoria', 'logs_auditoria_system_insert'
  
  UNION ALL SELECT 'configuracoes_sistema', 'configuracoes_select_all'
  UNION ALL SELECT 'configuracoes_sistema', 'configuracoes_admin_modify'
  
  UNION ALL SELECT 'sessoes_usuario', 'sessoes_self'
  UNION ALL SELECT 'sessoes_usuario', 'sessoes_system_insert'
  
  UNION ALL SELECT 'estados', 'estados_select_all'
  UNION ALL SELECT 'estados', 'estados_admin_modify'
  
  UNION ALL SELECT 'blocos', 'blocos_select_all'
  UNION ALL SELECT 'blocos', 'blocos_admin_modify'
  
  UNION ALL SELECT 'regioes', 'regioes_select_all'
  UNION ALL SELECT 'regioes', 'regioes_admin_modify'
  
  UNION ALL SELECT 'igrejas', 'igrejas_select_all'
  UNION ALL SELECT 'igrejas', 'igrejas_admin_modify'
),
politicas_atuais AS (
  SELECT tablename, policyname
  FROM pg_policies 
  WHERE schemaname = 'public'
)
SELECT 
  pn.tabela,
  pn.politica,
  CASE 
    WHEN pa.policyname IS NOT NULL THEN '✅ IMPLEMENTADA'
    ELSE '❌ FALTANDO'
  END as status
FROM politicas_necessarias pn
LEFT JOIN politicas_atuais pa ON pn.tabela = pa.tablename AND pn.politica = pa.policyname
ORDER BY pn.tabela, pn.politica;

-- =====================================================
-- 7. VERIFICAR POLÍTICAS DE STORAGE NECESSÁRIAS
-- =====================================================

WITH storage_necessarias AS (
  SELECT 'fotos_usuarios_self' as politica
  UNION ALL SELECT 'fotos_jovens_hierarchy'
  UNION ALL SELECT 'documentos_hierarchy'
  UNION ALL SELECT 'backups_admin'
  UNION ALL SELECT 'temp_authenticated'
),
storage_atuais AS (
  SELECT policyname
  FROM pg_policies 
  WHERE schemaname = 'storage'
)
SELECT 
  sn.politica,
  CASE 
    WHEN sa.policyname IS NOT NULL THEN '✅ IMPLEMENTADA'
    ELSE '❌ FALTANDO'
  END as status
FROM storage_necessarias sn
LEFT JOIN storage_atuais sa ON sn.politica = sa.policyname
ORDER BY sn.politica;
