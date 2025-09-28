-- Script para testar igrejas de uma região específica

-- 1. Verificar se há igrejas na região "Planalto"
SELECT 
    i.id,
    i.nome as igreja_nome,
    i.endereco,
    i.regiao_id,
    r.nome as regiao_nome,
    b.nome as bloco_nome
FROM igrejas i
LEFT JOIN regioes r ON i.regiao_id = r.id
LEFT JOIN blocos b ON r.bloco_id = b.id
WHERE r.nome = 'Planalto' AND r.bloco_id = 'c546d361-8ad2-4eaa-b2bd-f2e18e5af12d'
ORDER BY i.nome;

-- 2. Verificar todas as igrejas do bloco Uberlândia
SELECT 
    i.id,
    i.nome as igreja_nome,
    i.endereco,
    i.regiao_id,
    r.nome as regiao_nome
FROM igrejas i
LEFT JOIN regioes r ON i.regiao_id = r.id
LEFT JOIN blocos b ON r.bloco_id = b.id
WHERE b.id = 'c546d361-8ad2-4eaa-b2bd-f2e18e5af12d'
ORDER BY r.nome, i.nome;

-- 3. Contar igrejas por região
SELECT 
    r.nome as regiao_nome,
    COUNT(i.id) as total_igrejas
FROM regioes r
LEFT JOIN igrejas i ON r.id = i.regiao_id
WHERE r.bloco_id = 'c546d361-8ad2-4eaa-b2bd-f2e18e5af12d'
GROUP BY r.id, r.nome
ORDER BY total_igrejas DESC;

-- 4. Verificar se há policies RLS bloqueando igrejas
SELECT 
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'igrejas' AND cmd = 'SELECT'
ORDER BY policyname;
