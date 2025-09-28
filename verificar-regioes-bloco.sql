-- Script para verificar regiões do bloco Uberlândia

-- 1. Verificar o bloco Uberlândia
SELECT 
    b.id,
    b.nome as bloco_nome,
    e.nome as estado_nome
FROM blocos b
LEFT JOIN estados e ON b.estado_id = e.id
WHERE b.nome ILIKE '%uberlândia%' OR b.nome ILIKE '%uberlandia%';

-- 2. Verificar todas as regiões deste bloco
SELECT 
    r.id,
    r.nome,
    r.bloco_id,
    b.nome as bloco_nome
FROM regioes r
LEFT JOIN blocos b ON r.bloco_id = b.id
WHERE r.bloco_id = 'c546d361-8ad2-4eaa-b2bd-f2e18e5af12d'
ORDER BY r.nome;

-- 3. Verificar se há regiões "Planalto" em outros blocos
SELECT 
    r.id,
    r.nome,
    r.bloco_id,
    b.nome as bloco_nome,
    e.nome as estado_nome
FROM regioes r
LEFT JOIN blocos b ON r.bloco_id = b.id
LEFT JOIN estados e ON b.estado_id = e.id
WHERE r.nome ILIKE '%planalto%'
ORDER BY b.nome, r.nome;

-- 4. Contar regiões por bloco
SELECT 
    b.nome as bloco_nome,
    e.nome as estado_nome,
    COUNT(r.id) as total_regioes
FROM blocos b
LEFT JOIN estados e ON b.estado_id = e.id
LEFT JOIN regioes r ON b.id = r.bloco_id
GROUP BY b.id, b.nome, e.nome
ORDER BY total_regioes DESC;
