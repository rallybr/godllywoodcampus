-- TESTAR COM USUÁRIO QUE TEM DADOS GEOGRÁFICOS
-- Este script testa com um usuário que tem dados geográficos

-- 1. Verificar usuários com dados geográficos
SELECT 
    'Usuários com dados geográficos:' as info,
    u.nome,
    u.nivel,
    e.nome as estado,
    b.nome as bloco,
    r.nome as regiao,
    i.nome as igreja
FROM public.usuarios u
LEFT JOIN public.estados e ON e.id = u.estado_id
LEFT JOIN public.blocos b ON b.id = u.bloco_id
LEFT JOIN public.regioes r ON r.id = u.regiao_id
LEFT JOIN public.igrejas i ON i.id = u.igreja_id
WHERE u.nivel IN (
    'lider_estadual_iurd', 'lider_estadual_fju',
    'lider_bloco_iurd', 'lider_bloco_fju',
    'lider_regional_iurd', 'lider_igreja_iurd'
)
AND u.estado_id IS NOT NULL
ORDER BY u.nivel, u.nome
LIMIT 10;

-- 2. Verificar jovens por estado
SELECT 
    'Jovens por estado:' as info,
    e.nome as estado,
    COUNT(j.id) as total_jovens
FROM public.estados e
LEFT JOIN public.jovens j ON j.estado_id = e.id
GROUP BY e.id, e.nome
HAVING COUNT(j.id) > 0
ORDER BY total_jovens DESC
LIMIT 10;

-- 3. Verificar jovens por bloco
SELECT 
    'Jovens por bloco:' as info,
    b.nome as bloco,
    e.nome as estado,
    COUNT(j.id) as total_jovens
FROM public.blocos b
LEFT JOIN public.estados e ON e.id = b.estado_id
LEFT JOIN public.jovens j ON j.bloco_id = b.id
GROUP BY b.id, b.nome, e.nome
HAVING COUNT(j.id) > 0
ORDER BY total_jovens DESC
LIMIT 10;

-- 4. Verificar jovens por região
SELECT 
    'Jovens por região:' as info,
    r.nome as regiao,
    b.nome as bloco,
    e.nome as estado,
    COUNT(j.id) as total_jovens
FROM public.regioes r
LEFT JOIN public.blocos b ON b.id = r.bloco_id
LEFT JOIN public.estados e ON e.id = b.estado_id
LEFT JOIN public.jovens j ON j.regiao_id = r.id
GROUP BY r.id, r.nome, b.nome, e.nome
HAVING COUNT(j.id) > 0
ORDER BY total_jovens DESC
LIMIT 10;

-- 5. Verificar jovens por igreja
SELECT 
    'Jovens por igreja:' as info,
    i.nome as igreja,
    r.nome as regiao,
    b.nome as bloco,
    e.nome as estado,
    COUNT(j.id) as total_jovens
FROM public.igrejas i
LEFT JOIN public.regioes r ON r.id = i.regiao_id
LEFT JOIN public.blocos b ON b.id = r.bloco_id
LEFT JOIN public.estados e ON e.id = b.estado_id
LEFT JOIN public.jovens j ON j.igreja_id = i.id
GROUP BY i.id, i.nome, r.nome, b.nome, e.nome
HAVING COUNT(j.id) > 0
ORDER BY total_jovens DESC
LIMIT 10;
