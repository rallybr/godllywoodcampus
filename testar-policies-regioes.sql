-- Script para testar policies RLS da tabela regioes

-- 1. Verificar policies RLS ativas
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

-- 2. Testar consulta direta (como admin)
SELECT 
    r.id,
    r.nome,
    r.bloco_id,
    b.nome as bloco_nome
FROM regioes r
LEFT JOIN blocos b ON r.bloco_id = b.id
WHERE r.bloco_id = 'c546d361-8ad2-4eaa-b2bd-f2e18e5af12d'
ORDER BY r.nome;

-- 3. Verificar se há restrições de usuário
SELECT 
    current_user,
    session_user,
    current_database();

-- 4. Testar consulta com contexto de usuário
SELECT 
    r.*,
    b.nome as bloco_nome
FROM regioes r
LEFT JOIN blocos b ON r.bloco_id = b.id
WHERE r.bloco_id = 'c546d361-8ad2-4eaa-b2bd-f2e18e5af12d'
ORDER BY r.nome;

-- 5. Verificar se há problemas de permissão
SELECT 
    COUNT(*) as total_regioes_bloco
FROM regioes 
WHERE bloco_id = 'c546d361-8ad2-4eaa-b2bd-f2e18e5af12d';
