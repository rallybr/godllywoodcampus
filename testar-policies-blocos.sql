-- =====================================================
-- TESTE DAS POLICIES DA TABELA BLOCOS
-- =====================================================

-- 1. Verificar se o usuário atual está autenticado
SELECT 
    'Usuário atual' as info,
    auth.uid() as auth_id,
    u.id as user_id,
    u.nome,
    u.nivel,
    u.estado_id,
    u.bloco_id,
    u.regiao_id,
    u.igreja_id
FROM public.usuarios u
WHERE u.id_auth = auth.uid();

-- 2. Verificar policies ativas da tabela blocos
SELECT 
    'Policies ativas' as info,
    policyname,
    cmd,
    permissive,
    roles,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'blocos'
ORDER BY policyname;

-- 3. Testar SELECT (deve funcionar para todos)
SELECT 
    'Teste SELECT' as info,
    COUNT(*) as total_blocos
FROM public.blocos;

-- 4. Verificar se RLS está habilitado
SELECT 
    'RLS Status' as info,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'blocos';

-- 5. Testar INSERT (pode falhar se não for admin/líder)
-- Este teste deve ser executado apenas se o usuário tiver permissão
DO $$
DECLARE
    test_result text;
BEGIN
    BEGIN
        INSERT INTO public.blocos (nome, estado_id) 
        VALUES ('TESTE_BLOCO_' || extract(epoch from now()), 
                (SELECT id FROM public.estados LIMIT 1));
        
        test_result := 'INSERT funcionou - usuário tem permissão';
        
        -- Limpar o teste
        DELETE FROM public.blocos WHERE nome LIKE 'TESTE_BLOCO_%';
        
    EXCEPTION
        WHEN OTHERS THEN
            test_result := 'INSERT falhou: ' || SQLERRM;
    END;
    
    RAISE NOTICE 'Resultado do teste INSERT: %', test_result;
END $$;

-- 6. Verificar permissões específicas do usuário
SELECT 
    'Permissões do usuário' as info,
    CASE 
        WHEN u.nivel = 'administrador' THEN 'ADMIN - Acesso total'
        WHEN u.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju') THEN 'LÍDER NACIONAL - Acesso nacional'
        WHEN u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') THEN 'LÍDER ESTADUAL - Acesso ao estado: ' || e.nome
        WHEN u.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') THEN 'LÍDER DE BLOCO - Acesso ao bloco: ' || b.nome
        WHEN u.nivel = 'lider_regional_iurd' THEN 'LÍDER REGIONAL - Acesso à região: ' || r.nome
        WHEN u.nivel = 'lider_igreja_iurd' THEN 'LÍDER DE IGREJA - Acesso à igreja: ' || i.nome
        WHEN u.nivel = 'colaborador' THEN 'COLABORADOR - Acesso limitado'
        WHEN u.nivel = 'jovem' THEN 'JOVEM - Acesso apenas aos próprios dados'
        ELSE 'NÍVEL DESCONHECIDO: ' || u.nivel
    END as permissao
FROM public.usuarios u
LEFT JOIN public.estados e ON e.id = u.estado_id
LEFT JOIN public.blocos b ON b.id = u.bloco_id
LEFT JOIN public.regioes r ON r.id = u.regiao_id
LEFT JOIN public.igrejas i ON i.id = u.igreja_id
WHERE u.id_auth = auth.uid();
