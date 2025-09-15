-- =====================================================
-- VERIFICAR ESTATÍSTICAS DO USUÁRIO
-- =====================================================

-- 1. Verificar usuários cadastrados
SELECT 
    id,
    id_auth,
    nome,
    email,
    ativo
FROM usuarios
ORDER BY criado_em DESC;

-- 2. Verificar jovens cadastrados
SELECT 
    id,
    nome_completo,
    data_cadastro,
    aprovado
FROM jovens
ORDER BY data_cadastro DESC;

-- 3. Verificar avaliações
SELECT 
    id,
    jovem_id,
    user_id,
    nota,
    criado_em
FROM avaliacoes
ORDER BY criado_em DESC;

-- 4. Verificar se há relação entre usuários e avaliações
SELECT 
    u.id as usuario_id,
    u.nome as usuario_nome,
    COUNT(a.id) as total_avaliacoes,
    AVG(a.nota) as media_notas
FROM usuarios u
LEFT JOIN avaliacoes a ON u.id = a.user_id
GROUP BY u.id, u.nome
ORDER BY total_avaliacoes DESC;

-- 5. Verificar total de jovens por usuário (se houver campo criado_por)
SELECT 
    COUNT(*) as total_jovens,
    'Sistema' as criado_por
FROM jovens;

-- 6. Verificar se o usuário atual tem dados
SELECT 
    'Usuários na tabela' as tipo,
    COUNT(*) as total
FROM usuarios
UNION ALL
SELECT 
    'Jovens cadastrados' as tipo,
    COUNT(*) as total
FROM jovens
UNION ALL
SELECT 
    'Avaliações feitas' as tipo,
    COUNT(*) as total
FROM avaliacoes;
