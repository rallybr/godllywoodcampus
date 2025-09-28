-- Script para diagnosticar problema de exclusão de regiões

-- 1. Verificar policies RLS existentes para DELETE
SELECT 
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'regioes' AND cmd = 'DELETE'
ORDER BY policyname;

-- 2. Verificar se há dependências (igrejas) que impedem exclusão
SELECT 
    r.id as regiao_id,
    r.nome as regiao_nome,
    COUNT(i.id) as total_igrejas
FROM regioes r
LEFT JOIN igrejas i ON i.regiao_id = r.id
WHERE r.nome = 'Planalto' AND r.bloco_id = 'c546d361-8ad2-4eaa-b2bd-f2e18e5af12d'
GROUP BY r.id, r.nome
ORDER BY total_igrejas DESC;

-- 3. Verificar se há jovens vinculados às regiões
SELECT 
    r.id as regiao_id,
    r.nome as regiao_nome,
    COUNT(j.id) as total_jovens
FROM regioes r
LEFT JOIN jovens j ON j.regiao_id = r.id
WHERE r.nome = 'Planalto' AND r.bloco_id = 'c546d361-8ad2-4eaa-b2bd-f2e18e5af12d'
GROUP BY r.id, r.nome
ORDER BY total_jovens DESC;

-- 4. Testar exclusão de uma região específica (substitua o ID)
-- DELETE FROM regioes WHERE id = 'ID_DA_REGIAO_PLANALTO' RETURNING *;

-- 5. Verificar permissões do usuário atual
SELECT 
    current_user,
    session_user,
    current_database(),
    has_table_privilege('regioes', 'DELETE') as pode_deletar;
