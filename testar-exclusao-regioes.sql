-- Script para testar exclusão de regiões

-- 1. Verificar policies RLS para DELETE na tabela regioes
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
WHERE tablename = 'regioes' AND cmd = 'DELETE'
ORDER BY policyname;

-- 2. Testar exclusão direta (como admin)
DELETE FROM regioes 
WHERE nome = 'Planalto' AND bloco_id = 'c546d361-8ad2-4eaa-b2bd-f2e18e5af12d'
RETURNING *;

-- 3. Verificar se há restrições de foreign key
SELECT 
    conname as constraint_name,
    contype as constraint_type,
    pg_get_constraintdef(oid) as definition
FROM pg_constraint 
WHERE conrelid = 'regioes'::regclass;

-- 4. Verificar se há dependências (igrejas que dependem das regiões)
SELECT 
    i.id,
    i.nome as igreja_nome,
    i.regiao_id,
    r.nome as regiao_nome
FROM igrejas i
LEFT JOIN regioes r ON i.regiao_id = r.id
WHERE r.nome = 'Planalto' AND r.bloco_id = 'c546d361-8ad2-4eaa-b2bd-f2e18e5af12d';
