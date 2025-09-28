-- =====================================================
-- Script para verificar se as policies estão funcionando
-- =====================================================

-- 1. Verificar se RLS está habilitado nas tabelas
SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN (
    'usuarios', 'roles', 'user_roles', 'estados', 'blocos', 'regioes', 'igrejas', 
    'edicoes', 'jovens', 'avaliacoes', 'aprovacoes_jovens', 'dados_viagem', 
    'logs_auditoria', 'notificacoes', 'sessoes_usuario', 'configuracoes_sistema'
  )
ORDER BY tablename;

-- 2. Verificar todas as policies criadas
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- 3. Contar quantas policies foram criadas por tabela
SELECT 
  tablename,
  COUNT(*) as total_policies
FROM pg_policies 
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;
