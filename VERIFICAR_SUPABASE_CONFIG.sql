-- =====================================================
-- VERIFICAR CONFIGURAÇÃO DO SUPABASE
-- =====================================================
-- Data: 2024-12-19
-- Objetivo: Verificar se há problemas de configuração do Supabase

-- =====================================================
-- 1. VERIFICAR EXTENSÕES INSTALADAS
-- =====================================================

SELECT 
  'EXTENSIONS' as status,
  extname as nome_extensao,
  extversion as versao,
  extrelocatable as relocatable
FROM pg_extension
ORDER BY extname;

-- =====================================================
-- 2. VERIFICAR CONFIGURAÇÕES DO SUPABASE
-- =====================================================

-- Verificar se o Supabase está configurado corretamente
SELECT 
  'SUPABASE CONFIG' as status,
  'auth.uid()' as funcao,
  auth.uid() as valor_atual;

-- =====================================================
-- 3. VERIFICAR SE HÁ POLÍTICAS GLOBAIS
-- =====================================================

-- Verificar se há políticas globais que podem estar causando o problema
SELECT 
  'GLOBAL POLICIES' as status,
  schemaname,
  tablename,
  policyname,
  cmd,
  permissive,
  roles
FROM pg_policies 
WHERE schemaname IN ('auth', 'storage', 'public')
ORDER BY schemaname, tablename, policyname;

-- =====================================================
-- 4. VERIFICAR SE HÁ POLÍTICAS EM TABELAS DO SISTEMA
-- =====================================================

-- Verificar políticas em tabelas do sistema que podem estar interferindo
SELECT 
  'SYSTEM POLICIES' as status,
  schemaname,
  tablename,
  policyname,
  cmd
FROM pg_policies 
WHERE schemaname IN ('auth', 'storage')
  AND tablename IN ('users', 'objects', 'buckets')
ORDER BY schemaname, tablename, policyname;

-- =====================================================
-- 5. VERIFICAR SE HÁ POLÍTICAS EM TABELAS OCULTAS
-- =====================================================

-- Verificar se há políticas em tabelas que não aparecem na consulta normal
SELECT 
  'HIDDEN TABLES' as status,
  schemaname,
  tablename,
  policyname,
  cmd
FROM pg_policies 
WHERE schemaname = 'public'
  AND tablename NOT IN ('usuarios', 'jovens', 'avaliacoes', 'edicoes', 'roles', 'user_roles', 'logs_historico', 'notificacoes', 'logs_auditoria', 'configuracoes_sistema', 'sessoes_usuario', 'estados', 'blocos', 'regioes', 'igrejas')
ORDER BY tablename, policyname;

-- =====================================================
-- 6. VERIFICAR SE HÁ POLÍTICAS EM TABELAS DE AUDITORIA
-- =====================================================

-- Verificar se há políticas em tabelas de auditoria que podem estar causando o problema
SELECT 
  'AUDIT TABLES' as status,
  schemaname,
  tablename,
  policyname,
  cmd
FROM pg_policies 
WHERE schemaname = 'public'
  AND (tablename LIKE '%audit%' OR tablename LIKE '%log%' OR tablename LIKE '%history%')
ORDER BY tablename, policyname;

-- =====================================================
-- 7. VERIFICAR SE HÁ POLÍTICAS EM TABELAS DE CONFIGURAÇÃO
-- =====================================================

-- Verificar se há políticas em tabelas de configuração
SELECT 
  'CONFIG TABLES' as status,
  schemaname,
  tablename,
  policyname,
  cmd
FROM pg_policies 
WHERE schemaname = 'public'
  AND (tablename LIKE '%config%' OR tablename LIKE '%setting%' OR tablename LIKE '%preference%')
ORDER BY tablename, policyname;

-- =====================================================
-- 8. VERIFICAR SE HÁ POLÍTICAS EM TABELAS DE SESSÃO
-- =====================================================

-- Verificar se há políticas em tabelas de sessão
SELECT 
  'SESSION TABLES' as status,
  schemaname,
  tablename,
  policyname,
  cmd
FROM pg_policies 
WHERE schemaname = 'public'
  AND (tablename LIKE '%session%' OR tablename LIKE '%login%' OR tablename LIKE '%auth%')
ORDER BY tablename, policyname;

-- =====================================================
-- 9. VERIFICAR SE HÁ POLÍTICAS EM TABELAS DE NOTIFICAÇÃO
-- =====================================================

-- Verificar se há políticas em tabelas de notificação
SELECT 
  'NOTIFICATION TABLES' as status,
  schemaname,
  tablename,
  policyname,
  cmd
FROM pg_policies 
WHERE schemaname = 'public'
  AND (tablename LIKE '%notification%' OR tablename LIKE '%alert%' OR tablename LIKE '%message%')
ORDER BY tablename, policyname;

-- =====================================================
-- 10. VERIFICAR SE HÁ POLÍTICAS EM TABELAS DE ARQUIVO
-- =====================================================

-- Verificar se há políticas em tabelas de arquivo
SELECT 
  'FILE TABLES' as status,
  schemaname,
  tablename,
  policyname,
  cmd
FROM pg_policies 
WHERE schemaname = 'public'
  AND (tablename LIKE '%file%' OR tablename LIKE '%document%' OR tablename LIKE '%attachment%')
ORDER BY tablename, policyname;
