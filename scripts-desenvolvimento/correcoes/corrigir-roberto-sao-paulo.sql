-- CORRIGIR ROBERTO GUERRA COM SÃO PAULO
-- Este script corrige os dados geográficos do Roberto Guerra com São Paulo

-- 1. Verificar Roberto Guerra antes da correção
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

-- 2. Verificar dados de São Paulo
SELECT 
    'Dados de São Paulo:' as info,
    e.nome as estado,
    COUNT(j.id) as total_jovens
FROM public.estados e
LEFT JOIN public.jovens j ON j.estado_id = e.id
WHERE e.nome = 'São Paulo'
GROUP BY e.id, e.nome;

-- 3. Verificar blocos de São Paulo
SELECT 
    'Blocos de São Paulo:' as info,
    b.nome as bloco,
    COUNT(j.id) as total_jovens
FROM public.blocos b
LEFT JOIN public.estados e ON e.id = b.estado_id
LEFT JOIN public.jovens j ON j.bloco_id = b.id
WHERE e.nome = 'São Paulo'
GROUP BY b.id, b.nome
HAVING COUNT(j.id) > 0
ORDER BY total_jovens DESC
LIMIT 5;

-- 4. Verificar regiões de São Paulo
SELECT 
    'Regiões de São Paulo:' as info,
    r.nome as regiao,
    COUNT(j.id) as total_jovens
FROM public.regioes r
LEFT JOIN public.blocos b ON b.id = r.bloco_id
LEFT JOIN public.estados e ON e.id = b.estado_id
LEFT JOIN public.jovens j ON j.regiao_id = r.id
WHERE e.nome = 'São Paulo'
GROUP BY r.id, r.nome
HAVING COUNT(j.id) > 0
ORDER BY total_jovens DESC
LIMIT 5;

-- 5. Verificar igrejas de São Paulo
SELECT 
    'Igrejas de São Paulo:' as info,
    i.nome as igreja,
    COUNT(j.id) as total_jovens
FROM public.igrejas i
LEFT JOIN public.regioes r ON r.id = i.regiao_id
LEFT JOIN public.blocos b ON b.id = r.bloco_id
LEFT JOIN public.estados e ON e.id = b.estado_id
LEFT JOIN public.jovens j ON j.igreja_id = i.id
WHERE e.nome = 'São Paulo'
GROUP BY i.id, i.nome
HAVING COUNT(j.id) > 0
ORDER BY total_jovens DESC
LIMIT 5;

-- 6. Atualizar Roberto Guerra com dados de São Paulo
UPDATE public.usuarios 
SET 
    estado_id = (SELECT id FROM public.estados WHERE nome = 'São Paulo' LIMIT 1),
    bloco_id = (
        SELECT b.id 
        FROM public.blocos b
        LEFT JOIN public.estados e ON e.id = b.estado_id
        LEFT JOIN public.jovens j ON j.bloco_id = b.id
        WHERE e.nome = 'São Paulo'
        GROUP BY b.id, b.nome
        HAVING COUNT(j.id) > 0
        ORDER BY COUNT(j.id) DESC
        LIMIT 1
    ),
    regiao_id = (
        SELECT r.id 
        FROM public.regioes r
        LEFT JOIN public.blocos b ON b.id = r.bloco_id
        LEFT JOIN public.estados e ON e.id = b.estado_id
        LEFT JOIN public.jovens j ON j.regiao_id = r.id
        WHERE e.nome = 'São Paulo'
        GROUP BY r.id, r.nome
        HAVING COUNT(j.id) > 0
        ORDER BY COUNT(j.id) DESC
        LIMIT 1
    ),
    igreja_id = (
        SELECT i.id 
        FROM public.igrejas i
        LEFT JOIN public.regioes r ON r.id = i.regiao_id
        LEFT JOIN public.blocos b ON b.id = r.bloco_id
        LEFT JOIN public.estados e ON e.id = b.estado_id
        LEFT JOIN public.jovens j ON j.igreja_id = i.id
        WHERE e.nome = 'São Paulo'
        GROUP BY i.id, i.nome
        HAVING COUNT(j.id) > 0
        ORDER BY COUNT(j.id) DESC
        LIMIT 1
    )
WHERE id = 'e745720c-e9f7-4562-978b-72ba32387420';

-- 7. Verificar Roberto Guerra após a correção
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

-- 8. Testar a função após a correção
SELECT 
    'Teste da função após correção:' as info,
    estado_id,
    total
FROM public.get_jovens_por_estado_count(NULL)
LIMIT 5;
