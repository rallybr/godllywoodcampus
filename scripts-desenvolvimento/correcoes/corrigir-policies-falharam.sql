-- =====================================================
-- Script para corrigir as duas policies que falharam
-- =====================================================

-- 1. Remover a policy problemática de user_roles
DROP POLICY IF EXISTS "allow_read_own_user_roles" ON public.user_roles;

-- 2. Criar a policy corrigida para user_roles
CREATE POLICY "allow_read_own_user_roles" ON public.user_roles
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.usuarios u 
      WHERE u.id_auth = auth.uid() 
      AND u.id = user_roles.user_id
    )
  );

-- 3. Verificar se a policy foi criada corretamente
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd,
  qual
FROM pg_policies 
WHERE schemaname = 'public'
  AND tablename = 'user_roles'
ORDER BY policyname;

-- 4. Verificar status das tabelas
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

-- 5. Verificar todas as policies criadas
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
