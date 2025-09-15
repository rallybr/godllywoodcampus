-- =====================================================
-- VERIFICAR SE RLS ESTÁ HABILITADO
-- =====================================================
-- Data: 2024-12-19
-- Objetivo: Verificar se RLS está habilitado nas tabelas

-- =====================================================
-- 1. VERIFICAR STATUS DO RLS POR TABELA
-- =====================================================

SELECT 
  'RLS STATUS' as status,
  schemaname,
  tablename,
  rowsecurity as rls_habilitado,
  CASE 
    WHEN rowsecurity = true THEN '✅ HABILITADO'
    WHEN rowsecurity = false THEN '❌ DESABILITADO'
    ELSE '❓ DESCONHECIDO'
  END as status_texto
FROM pg_tables 
WHERE schemaname = 'public'
  AND tablename IN (
    'usuarios', 'jovens', 'avaliacoes', 'edicoes', 'roles', 'user_roles', 
    'logs_historico', 'notificacoes', 'logs_auditoria', 'configuracoes_sistema', 
    'sessoes_usuario', 'estados', 'blocos', 'regioes', 'igrejas'
  )
ORDER BY tablename;

-- =====================================================
-- 2. VERIFICAR POLÍTICAS EXISTENTES
-- =====================================================

SELECT 
  'POLÍTICAS EXISTENTES' as status,
  schemaname,
  tablename,
  policyname,
  cmd as operacao,
  permissive as permissiva
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- =====================================================
-- 3. CONTAR POLÍTICAS POR TABELA
-- =====================================================

SELECT 
  'CONTAGEM POLÍTICAS' as status,
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

-- =====================================================
-- 4. VERIFICAR TABELAS SEM RLS
-- =====================================================

SELECT 
  'TABELAS SEM RLS' as status,
  tablename,
  '❌ RLS DESABILITADO' as status_rls
FROM pg_tables 
WHERE schemaname = 'public'
  AND tablename IN (
    'usuarios', 'jovens', 'avaliacoes', 'edicoes', 'roles', 'user_roles', 
    'logs_historico', 'notificacoes', 'logs_auditoria', 'configuracoes_sistema', 
    'sessoes_usuario', 'estados', 'blocos', 'regioes', 'igrejas'
  )
  AND rowsecurity = false
ORDER BY tablename;

-- =====================================================
-- 5. VERIFICAR TABELAS SEM POLÍTICAS
-- =====================================================

WITH tabelas_principais AS (
  SELECT unnest(ARRAY[
    'usuarios', 'jovens', 'avaliacoes', 'edicoes', 'roles', 'user_roles', 
    'logs_historico', 'notificacoes', 'logs_auditoria', 'configuracoes_sistema', 
    'sessoes_usuario', 'estados', 'blocos', 'regioes', 'igrejas'
  ]) as tabela
),
tabelas_com_politicas AS (
  SELECT DISTINCT tablename
  FROM pg_policies 
  WHERE schemaname = 'public'
)
SELECT 
  'TABELAS SEM POLÍTICAS' as status,
  tp.tabela,
  CASE 
    WHEN tcp.tablename IS NULL THEN '❌ SEM POLÍTICAS'
    ELSE '✅ TEM POLÍTICAS'
  END as status_politicas
FROM tabelas_principais tp
LEFT JOIN tabelas_com_politicas tcp ON tp.tabela = tcp.tablename
ORDER BY tp.tabela;

-- =====================================================
-- 6. RESUMO GERAL
-- =====================================================

SELECT 
  'RESUMO GERAL' as status,
  'Tabelas com RLS habilitado' as tipo,
  count(*) as total
FROM pg_tables 
WHERE schemaname = 'public'
  AND tablename IN (
    'usuarios', 'jovens', 'avaliacoes', 'edicoes', 'roles', 'user_roles', 
    'logs_historico', 'notificacoes', 'logs_auditoria', 'configuracoes_sistema', 
    'sessoes_usuario', 'estados', 'blocos', 'regioes', 'igrejas'
  )
  AND rowsecurity = true

UNION ALL

SELECT 
  'RESUMO GERAL' as status,
  'Tabelas com RLS desabilitado' as tipo,
  count(*) as total
FROM pg_tables 
WHERE schemaname = 'public'
  AND tablename IN (
    'usuarios', 'jovens', 'avaliacoes', 'edicoes', 'roles', 'user_roles', 
    'logs_historico', 'notificacoes', 'logs_auditoria', 'configuracoes_sistema', 
    'sessoes_usuario', 'estados', 'blocos', 'regioes', 'igrejas'
  )
  AND rowsecurity = false

UNION ALL

SELECT 
  'RESUMO GERAL' as status,
  'Total de políticas RLS' as tipo,
  count(*) as total
FROM pg_policies 
WHERE schemaname = 'public';
