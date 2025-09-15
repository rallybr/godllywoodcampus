-- =====================================================
-- DESABILITAR RLS TEMPORARIAMENTE PARA TESTE
-- =====================================================
-- Data: 2024-12-19
-- Objetivo: Desabilitar RLS temporariamente para identificar o problema

-- =====================================================
-- 1. DESABILITAR RLS NAS TABELAS PRINCIPAIS
-- =====================================================

-- Desabilitar RLS temporariamente
ALTER TABLE usuarios DISABLE ROW LEVEL SECURITY;
ALTER TABLE jovens DISABLE ROW LEVEL SECURITY;
ALTER TABLE avaliacoes DISABLE ROW LEVEL SECURITY;
ALTER TABLE edicoes DISABLE ROW LEVEL SECURITY;
ALTER TABLE roles DISABLE ROW LEVEL SECURITY;
ALTER TABLE user_roles DISABLE ROW LEVEL SECURITY;
ALTER TABLE logs_historico DISABLE ROW LEVEL SECURITY;
ALTER TABLE notificacoes DISABLE ROW LEVEL SECURITY;
ALTER TABLE logs_auditoria DISABLE ROW LEVEL SECURITY;
ALTER TABLE configuracoes_sistema DISABLE ROW LEVEL SECURITY;
ALTER TABLE sessoes_usuario DISABLE ROW LEVEL SECURITY;
ALTER TABLE estados DISABLE ROW LEVEL SECURITY;
ALTER TABLE blocos DISABLE ROW LEVEL SECURITY;
ALTER TABLE regioes DISABLE ROW LEVEL SECURITY;
ALTER TABLE igrejas DISABLE ROW LEVEL SECURITY;

-- =====================================================
-- 2. VERIFICAR STATUS DO RLS
-- =====================================================

SELECT 
  'RLS STATUS' as status,
  schemaname,
  tablename,
  rowsecurity as rls_habilitado
FROM pg_tables 
WHERE schemaname = 'public'
  AND tablename IN ('usuarios', 'jovens', 'avaliacoes', 'edicoes', 'roles', 'user_roles', 'logs_historico', 'notificacoes', 'logs_auditoria', 'configuracoes_sistema', 'sessoes_usuario', 'estados', 'blocos', 'regioes', 'igrejas')
ORDER BY tablename;

-- =====================================================
-- 3. MENSAGEM DE CONFIRMAÇÃO
-- =====================================================

SELECT 
  'RLS DESABILITADO' as status,
  'Teste o cadastro de jovens agora' as mensagem,
  'Se funcionar, o problema está nas políticas RLS' as observacao;
