-- =====================================================
-- SCRIPT PARA DESABILITAR POLÍTICAS RLS
-- Execute este script no SQL Editor do Supabase
-- =====================================================

-- Desabilitar RLS em todas as tabelas
ALTER TABLE public.jovens DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.estados DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.blocos DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.regioes DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.igrejas DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.usuarios DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.edicoes DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.aprovacoes_jovens DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.avaliacoes DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.dados_viagem DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.logs_auditoria DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.notificacoes DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessoes_usuario DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.configuracoes_sistema DISABLE ROW LEVEL SECURITY;

-- Remover todas as políticas existentes
DROP POLICY IF EXISTS "allow_read_all_roles" ON public.roles;
DROP POLICY IF EXISTS "allow_read_own_user_data" ON public.usuarios;
DROP POLICY IF EXISTS "allow_read_own_user_roles" ON public.user_roles;
DROP POLICY IF EXISTS "allow_read_all_estados" ON public.estados;
DROP POLICY IF EXISTS "allow_read_all_blocos" ON public.blocos;
DROP POLICY IF EXISTS "allow_read_all_regioes" ON public.regioes;
DROP POLICY IF EXISTS "allow_read_all_igrejas" ON public.igrejas;
DROP POLICY IF EXISTS "allow_read_all_edicoes" ON public.edicoes;
DROP POLICY IF EXISTS "allow_read_own_jovem_profile" ON public.jovens;
DROP POLICY IF EXISTS "allow_read_all_jovens" ON public.jovens;

-- Verificar status
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
    AND tablename IN (
        'jovens', 'estados', 'blocos', 'regioes', 'igrejas', 
        'usuarios', 'roles', 'user_roles', 'edicoes',
        'aprovacoes_jovens', 'avaliacoes', 'dados_viagem',
        'logs_auditoria', 'notificacoes', 'sessoes_usuario', 'configuracoes_sistema'
    )
ORDER BY tablename;
