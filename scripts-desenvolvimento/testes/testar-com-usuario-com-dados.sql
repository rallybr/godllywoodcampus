-- TESTAR COM USUÁRIO QUE TEM DADOS
-- Este script testa com Rafael Cardoso que tem 8 jovens

-- 1. Dados do Rafael Cardoso
SELECT 
    'Rafael Cardoso:' as info,
    u.id,
    u.nome,
    u.nivel,
    u.estado_id,
    u.bloco_id,
    u.regiao_id,
    u.igreja_id
FROM public.usuarios u
WHERE u.nome = 'Rafael Cardoso';

-- 2. Jovens do Rafael
SELECT 
    'Jovens do Rafael:' as info,
    COUNT(*) as total,
    COUNT(DISTINCT estado_id) as estados_diferentes
FROM public.jovens j
WHERE j.usuario_id = (
    SELECT id FROM public.usuarios WHERE nome = 'Rafael Cardoso'
);

-- 3. Estados dos jovens do Rafael
SELECT 
    'Estados dos jovens do Rafael:' as info,
    e.nome as estado,
    COUNT(j.id) as total_jovens
FROM public.jovens j
JOIN public.estados e ON e.id = j.estado_id
WHERE j.usuario_id = (
    SELECT id FROM public.usuarios WHERE nome = 'Rafael Cardoso'
)
GROUP BY e.id, e.nome
ORDER BY total_jovens DESC;

-- 4. O que Rafael deveria ver (simulação)
SELECT 
    'O que Rafael deveria ver:' as info,
    j.estado_id,
    COUNT(*) as total
FROM public.jovens j
WHERE j.usuario_id = (
    SELECT id FROM public.usuarios WHERE nome = 'Rafael Cardoso'
)
GROUP BY j.estado_id
ORDER BY total DESC;
