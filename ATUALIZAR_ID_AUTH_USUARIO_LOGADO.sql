-- =====================================================
-- ATUALIZAR ID_AUTH DO USUÁRIO LOGADO
-- =====================================================

-- Atualizar o id_auth do usuário admin para o id_auth atual do usuário logado
UPDATE usuarios 
SET id_auth = '346d397f-1a05-4e17-8bed-f94274b78fe0'
WHERE id = 'f2b0d1aa-92b9-4eb7-aa27-0ff9865ffbde';

-- Verificar se foi atualizado
SELECT 
    id,
    nome,
    id_auth,
    CASE 
        WHEN id_auth = '346d397f-1a05-4e17-8bed-f94274b78fe0' THEN 'ATUALIZADO - USUÁRIO ATUAL'
        WHEN id_auth = '4075ce47-aea6-4fca-92fc-305e5af6bdf1' THEN 'ADMIN ORIGINAL'
        ELSE 'OUTRO'
    END as status
FROM usuarios;
