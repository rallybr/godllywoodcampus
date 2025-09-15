-- =====================================================
-- CORRIGIR AVALIAÇÕES COM USER_ID NULL
-- =====================================================

-- Atualizar avaliações com user_id NULL para o ID do usuário admin
UPDATE avaliacoes 
SET user_id = 'f2b0d1aa-92b9-4eb7-aa27-0ff9865ffbde'
WHERE user_id IS NULL;

-- Verificar se foi corrigido
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
