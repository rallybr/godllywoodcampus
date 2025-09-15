-- =====================================================
-- TESTAR RELAÇÃO ENTRE AVALIACOES E USUARIOS
-- =====================================================

-- 1. Verificar se existem avaliações
SELECT COUNT(*) as total_avaliacoes FROM avaliacoes;

-- 2. Verificar dados das avaliações
SELECT 
    id,
    jovem_id,
    user_id,
    espirito,
    caractere,
    disposicao,
    criado_em
FROM avaliacoes 
ORDER BY criado_em DESC 
LIMIT 3;

-- 3. Testar a relação com JOIN manual
SELECT 
    a.id as avaliacao_id,
    a.user_id,
    u.nome as avaliador_nome,
    u.email as avaliador_email,
    a.espirito,
    a.caractere,
    a.disposicao,
    a.criado_em
FROM avaliacoes a
LEFT JOIN usuarios u ON a.user_id = u.id
ORDER BY a.criado_em DESC
LIMIT 3;

-- 4. Verificar se o user_id das avaliações existe na tabela usuarios
SELECT 
    a.user_id,
    u.nome,
    u.email,
    CASE 
        WHEN u.id IS NULL THEN 'USUÁRIO NÃO ENCONTRADO'
        ELSE 'USUÁRIO ENCONTRADO'
    END as status
FROM avaliacoes a
LEFT JOIN usuarios u ON a.user_id = u.id
ORDER BY a.criado_em DESC
LIMIT 3;
