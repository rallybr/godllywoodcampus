-- =====================================================
-- VERIFICAR E CORRIGIR POLÍTICAS RLS
-- =====================================================

-- 1. VERIFICAR STATUS DO RLS
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_habilitado
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('jovens', 'estados', 'blocos', 'regioes', 'igrejas', 'usuarios', 'roles', 'user_roles', 'edicoes')
ORDER BY tablename;

-- 2. VERIFICAR POLÍTICAS EXISTENTES
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'public'
AND tablename IN ('jovens', 'estados', 'blocos', 'regioes', 'igrejas', 'usuarios', 'roles', 'user_roles', 'edicoes')
ORDER BY tablename, policyname;

-- 3. VERIFICAR SE EXISTEM DADOS (SEM RLS)
-- Desabilitar RLS temporariamente para verificar dados
ALTER TABLE public.jovens DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.estados DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.blocos DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.regioes DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.igrejas DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.usuarios DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.edicoes DISABLE ROW LEVEL SECURITY;

-- 4. VERIFICAR CONTAGEM DE DADOS
SELECT 'Jovens' as tabela, COUNT(*) as total FROM public.jovens
UNION ALL
SELECT 'Estados' as tabela, COUNT(*) as total FROM public.estados
UNION ALL
SELECT 'Blocos' as tabela, COUNT(*) as total FROM public.blocos
UNION ALL
SELECT 'Regiões' as tabela, COUNT(*) as total FROM public.regioes
UNION ALL
SELECT 'Igrejas' as tabela, COUNT(*) as total FROM public.igrejas
UNION ALL
SELECT 'Usuários' as tabela, COUNT(*) as total FROM public.usuarios
UNION ALL
SELECT 'Roles' as tabela, COUNT(*) as total FROM public.roles
UNION ALL
SELECT 'User Roles' as tabela, COUNT(*) as total FROM public.user_roles
UNION ALL
SELECT 'Edições' as tabela, COUNT(*) as total FROM public.edicoes;

-- 5. TESTAR CONSULTA ESPECÍFICA DO JOVEM
SELECT 
    j.nome_completo,
    e.nome as estado,
    b.nome as bloco,
    r.nome as regiao,
    i.nome as igreja,
    ed.nome as edicao
FROM public.jovens j
LEFT JOIN public.estados e ON e.id = j.estado_id
LEFT JOIN public.blocos b ON b.id = j.bloco_id
LEFT JOIN public.regioes r ON r.id = j.regiao_id
LEFT JOIN public.igrejas i ON i.id = j.igreja_id
LEFT JOIN public.edicoes ed ON ed.id = j.edicao_id
WHERE j.id = '0e1bc378-2cd2-476b-9551-d11d444bf499';

-- 6. REABILITAR RLS
ALTER TABLE public.jovens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.estados ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blocos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.regioes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.igrejas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.edicoes ENABLE ROW LEVEL SECURITY;
