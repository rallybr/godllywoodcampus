-- TESTAR COM USUÁRIO ESPECÍFICO
-- Vamos testar com Rafael Cardoso que tem 8 jovens

-- 1. Verificar dados do Rafael Cardoso
SELECT 
    'Dados do Rafael Cardoso:' as info,
    u.id,
    u.nome,
    u.nivel,
    u.estado_id,
    u.bloco_id,
    u.regiao_id,
    u.igreja_id
FROM public.usuarios u
WHERE u.nome = 'Rafael Cardoso';

-- 2. Verificar jovens do Rafael Cardoso
SELECT 
    'Jovens do Rafael:' as info,
    j.id,
    j.nome_completo,
    j.estado_id,
    j.bloco_id,
    j.regiao_id,
    j.igreja_id,
    j.usuario_id
FROM public.jovens j
WHERE j.usuario_id = (
    SELECT id FROM public.usuarios WHERE nome = 'Rafael Cardoso'
)
LIMIT 5;

-- 3. Verificar estados dos jovens do Rafael
SELECT 
    'Estados dos jovens do Rafael:' as info,
    e.nome as estado,
    COUNT(j.id) as total
FROM public.jovens j
JOIN public.estados e ON e.id = j.estado_id
WHERE j.usuario_id = (
    SELECT id FROM public.usuarios WHERE nome = 'Rafael Cardoso'
)
GROUP BY e.id, e.nome;

-- 4. Testar a função como se fosse o Rafael (simulação)
-- NOTA: Este teste não funcionará porque não podemos simular auth.uid()
-- Mas mostra o que deveria acontecer
SELECT 
    'Teste simulado:' as info,
    'Se Rafael estivesse logado, deveria ver:' as resultado,
    COUNT(*) as total_estados
FROM (
    SELECT DISTINCT j.estado_id
    FROM public.jovens j
    WHERE j.usuario_id = (
        SELECT id FROM public.usuarios WHERE nome = 'Rafael Cardoso'
    )
) as estados_rafael;
