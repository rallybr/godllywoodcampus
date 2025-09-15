-- =====================================================
-- VERIFICAR AVALIAÇÕES COM USER_ID NULL
-- =====================================================

-- Ver todas as avaliações e seus user_id
SELECT 
    id,
    jovem_id,
    user_id,
    espirito,
    caractere,
    disposicao,
    criado_em,
    CASE 
        WHEN user_id IS NULL THEN 'PROBLEMA: user_id NULL'
        ELSE 'OK: user_id preenchido'
    END as status
FROM avaliacoes 
ORDER BY criado_em DESC;

-- Contar quantas têm user_id NULL
SELECT 
    COUNT(*) as total_avaliacoes,
    COUNT(user_id) as com_user_id,
    COUNT(*) - COUNT(user_id) as sem_user_id
FROM avaliacoes;
