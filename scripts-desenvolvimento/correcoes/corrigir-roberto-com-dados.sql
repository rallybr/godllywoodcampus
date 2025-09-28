-- CORRIGIR ROBERTO GUERRA COM DADOS REAIS
-- Este script corrige os dados geográficos do Roberto Guerra com estados que têm jovens

-- 1. Verificar estados que têm jovens
SELECT 
    'Estados com jovens:' as info,
    e.nome as estado,
    COUNT(j.id) as total_jovens
FROM public.estados e
LEFT JOIN public.jovens j ON j.estado_id = e.id
GROUP BY e.id, e.nome
HAVING COUNT(j.id) > 0
ORDER BY total_jovens DESC
LIMIT 5;

-- 2. Verificar Roberto Guerra antes da correção
SELECT 
    'ANTES DA CORREÇÃO:' as info,
    u.nome,
    u.nivel,
    u.estado_id,
    u.bloco_id,
    u.regiao_id,
    u.igreja_id
FROM public.usuarios u
WHERE u.id = 'e745720c-e9f7-4562-978b-72ba32387420';

-- 3. Atualizar Roberto Guerra com dados de um estado que tem jovens
-- Vamos usar o estado com mais jovens
UPDATE public.usuarios 
SET 
    estado_id = (
        SELECT e.id 
        FROM public.estados e
        LEFT JOIN public.jovens j ON j.estado_id = e.id
        GROUP BY e.id, e.nome
        HAVING COUNT(j.id) > 0
        ORDER BY COUNT(j.id) DESC
        LIMIT 1
    ),
    bloco_id = (
        SELECT b.id 
        FROM public.blocos b
        LEFT JOIN public.jovens j ON j.bloco_id = b.id
        GROUP BY b.id, b.nome
        HAVING COUNT(j.id) > 0
        ORDER BY COUNT(j.id) DESC
        LIMIT 1
    ),
    regiao_id = (
        SELECT r.id 
        FROM public.regioes r
        LEFT JOIN public.jovens j ON j.regiao_id = r.id
        GROUP BY r.id, r.nome
        HAVING COUNT(j.id) > 0
        ORDER BY COUNT(j.id) DESC
        LIMIT 1
    ),
    igreja_id = (
        SELECT i.id 
        FROM public.igrejas i
        LEFT JOIN public.jovens j ON j.igreja_id = i.id
        GROUP BY i.id, i.nome
        HAVING COUNT(j.id) > 0
        ORDER BY COUNT(j.id) DESC
        LIMIT 1
    )
WHERE id = 'e745720c-e9f7-4562-978b-72ba32387420';

-- 4. Verificar Roberto Guerra após a correção
SELECT 
    'APÓS A CORREÇÃO:' as info,
    u.nome,
    u.nivel,
    u.estado_id,
    u.bloco_id,
    u.regiao_id,
    u.igreja_id,
    e.nome as estado,
    b.nome as bloco,
    r.nome as regiao,
    i.nome as igreja
FROM public.usuarios u
LEFT JOIN public.estados e ON e.id = u.estado_id
LEFT JOIN public.blocos b ON b.id = u.bloco_id
LEFT JOIN public.regioes r ON r.id = u.regiao_id
LEFT JOIN public.igrejas i ON i.id = u.igreja_id
WHERE u.id = 'e745720c-e9f7-4562-978b-72ba32387420';

-- 5. Verificar jovens do estado do Roberto
SELECT 
    'Jovens do estado do Roberto:' as info,
    COUNT(j.id) as total_jovens,
    COUNT(DISTINCT j.estado_id) as estados_diferentes
FROM public.jovens j
WHERE j.estado_id = (
    SELECT estado_id FROM public.usuarios WHERE id = 'e745720c-e9f7-4562-978b-72ba32387420'
);

-- 6. Testar a função após a correção
SELECT 
    'Teste da função após correção:' as info,
    estado_id,
    total
FROM public.get_jovens_por_estado_count(NULL)
LIMIT 5;
