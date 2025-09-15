-- =====================================================
-- HABILITAR RLS EM TODAS AS TABELAS
-- =====================================================
-- Data: 2024-12-19
-- Objetivo: Habilitar RLS em todas as tabelas principais

-- =====================================================
-- 1. HABILITAR RLS EM TODAS AS TABELAS
-- =====================================================

-- Tabelas principais
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE jovens ENABLE ROW LEVEL SECURITY;
ALTER TABLE avaliacoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE edicoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE logs_historico ENABLE ROW LEVEL SECURITY;
ALTER TABLE notificacoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE logs_auditoria ENABLE ROW LEVEL SECURITY;
ALTER TABLE configuracoes_sistema ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessoes_usuario ENABLE ROW LEVEL SECURITY;

-- Tabelas geográficas
ALTER TABLE estados ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocos ENABLE ROW LEVEL SECURITY;
ALTER TABLE regioes ENABLE ROW LEVEL SECURITY;
ALTER TABLE igrejas ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 2. VERIFICAR STATUS APÓS HABILITAÇÃO
-- =====================================================

SELECT 
  'RLS APÓS HABILITAÇÃO' as status,
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
-- 3. VERIFICAR POLÍTICAS EXISTENTES
-- =====================================================

SELECT 
  'POLÍTICAS EXISTENTES' as status,
  tablename as tabela,
  count(*) as total_politicas,
  string_agg(policyname, ', ' ORDER BY policyname) as politicas
FROM pg_policies 
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;

-- =====================================================
-- 4. RESUMO FINAL
-- =====================================================

SELECT 
  'RESUMO FINAL' as status,
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
  'RESUMO FINAL' as status,
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
  'RESUMO FINAL' as status,
  'Total de políticas RLS' as tipo,
  count(*) as total
FROM pg_policies 
WHERE schemaname = 'public';
