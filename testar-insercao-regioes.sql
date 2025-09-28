-- Script para testar inserção de regiões e identificar problemas

-- 1. Verificar policies RLS da tabela regioes
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
WHERE tablename = 'regioes'
ORDER BY policyname;

-- 2. Verificar se há restrições de unicidade
SELECT 
    conname as constraint_name,
    contype as constraint_type,
    pg_get_constraintdef(oid) as definition
FROM pg_constraint 
WHERE conrelid = 'regioes'::regclass;

-- 3. Verificar dados existentes na tabela regioes
SELECT 
    r.id,
    r.nome,
    r.bloco_id,
    b.nome as bloco_nome,
    e.nome as estado_nome
FROM regioes r
LEFT JOIN blocos b ON r.bloco_id = b.id
LEFT JOIN estados e ON b.estado_id = e.id
ORDER BY e.nome, b.nome, r.nome;

-- 4. Verificar se há problemas de permissão para o usuário atual
SELECT 
    current_user,
    session_user,
    current_database();

-- 5. Testar inserção de uma região de teste
-- (Execute apenas se necessário)
/*
INSERT INTO regioes (nome, bloco_id) 
VALUES ('Região Teste', (SELECT id FROM blocos LIMIT 1))
RETURNING *;
*/
