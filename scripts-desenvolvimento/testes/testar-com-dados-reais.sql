-- TESTAR COM DADOS REAIS
-- Este script testa a função com dados que sabemos que existem

-- 1. Verificar se há usuário autenticado
SELECT 
    'Status de autenticação:' as info,
    CASE 
        WHEN auth.uid() IS NULL THEN '❌ NÃO AUTENTICADO'
        ELSE '✅ AUTENTICADO - ID: ' || auth.uid()
    END as status;

-- 2. Verificar usuário atual
SELECT 
    'Usuário atual:' as info,
    u.nome,
    u.nivel,
    CASE 
        WHEN u.id IS NULL THEN '❌ NÃO ENCONTRADO'
        ELSE '✅ ENCONTRADO'
    END as status
FROM public.usuarios u
WHERE u.id_auth = auth.uid();

-- 3. Testar com Rafael Cardoso (que tem 8 jovens)
-- Simular o que aconteceria se Rafael estivesse logado
SELECT 
    'Simulação - Rafael Cardoso:' as info,
    'Se Rafael estivesse logado, veria:' as resultado,
    COUNT(DISTINCT j.estado_id) as estados_diferentes,
    COUNT(*) as total_jovens
FROM public.jovens j
WHERE j.usuario_id = (
    SELECT id FROM public.usuarios WHERE nome = 'Rafael Cardoso'
);

-- 4. Mostrar estados que Rafael deveria ver
SELECT 
    'Estados que Rafael deveria ver:' as info,
    e.nome as estado,
    COUNT(j.id) as total_jovens
FROM public.jovens j
JOIN public.estados e ON e.id = j.estado_id
WHERE j.usuario_id = (
    SELECT id FROM public.usuarios WHERE nome = 'Rafael Cardoso'
)
GROUP BY e.id, e.nome
ORDER BY total_jovens DESC;

-- 5. Verificar se o problema é de nível
SELECT 
    'Nível do usuário atual:' as info,
    u.nivel,
    CASE 
        WHEN u.nivel = 'jovem' THEN '❌ Jovem não deveria ver este card'
        WHEN u.nivel = 'colaborador' THEN '✅ Colaborador deveria ver apenas seus jovens'
        WHEN u.nivel = 'administrador' THEN '✅ Administrador deveria ver todos'
        WHEN u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') THEN '✅ Líder estadual deveria ver seu estado'
        ELSE '❓ Nível: ' || u.nivel
    END as comportamento_esperado
FROM public.usuarios u
WHERE u.id_auth = auth.uid();
