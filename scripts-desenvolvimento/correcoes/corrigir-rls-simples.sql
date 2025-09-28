-- Script simples para corrigir RLS sem loops complexos

-- 1. Desabilitar RLS em todas as tabelas principais
ALTER TABLE public.usuarios DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.jovens DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.avaliacoes DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.estados DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.blocos DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.regioes DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.igrejas DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.edicoes DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.dados_viagem DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.notificacoes DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.logs_auditoria DISABLE ROW LEVEL SECURITY;

-- 2. Remover políticas específicas conhecidas
DROP POLICY IF EXISTS "usuarios_select_own" ON public.usuarios;
DROP POLICY IF EXISTS "usuarios_select_admin" ON public.usuarios;
DROP POLICY IF EXISTS "usuarios_update_own" ON public.usuarios;
DROP POLICY IF EXISTS "usuarios_update_admin" ON public.usuarios;
DROP POLICY IF EXISTS "Usuários podem ver seu próprio último acesso" ON public.usuarios;
DROP POLICY IF EXISTS "Administradores podem ver todos os acessos" ON public.usuarios;
DROP POLICY IF EXISTS "Usuários podem ver seu próprio perfil" ON public.usuarios;
DROP POLICY IF EXISTS "Administradores podem ver todos os usuários" ON public.usuarios;
DROP POLICY IF EXISTS "Administradores podem ver dados de acesso" ON public.usuarios;
DROP POLICY IF EXISTS "Sistema pode atualizar último acesso" ON public.usuarios;

-- 3. Verificar se RLS está desabilitado
SELECT 
    schemaname, 
    tablename, 
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('usuarios', 'jovens', 'avaliacoes', 'user_roles', 'roles')
ORDER BY tablename;

-- 4. Verificar se não há políticas restantes
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
