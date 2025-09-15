-- =====================================================
-- CORRIGIR RELAÇÃO ENTRE AUTH.UID E USUARIOS.ID_AUTH
-- =====================================================

-- Verificar dados atuais
SELECT 
    id,
    id_auth,
    nome,
    email,
    CASE 
        WHEN id_auth IS NOT NULL THEN 'OK'
        ELSE 'PROBLEMA: id_auth NULL'
    END as status
FROM usuarios;

-- Atualizar id_auth para o usuário admin (se estiver NULL)
UPDATE usuarios 
SET id_auth = '4075ce47-aea6-4fca-92fc-305e5af6bdf1'
WHERE id = 'f2b0d1aa-92b9-4eb7-aa27-0ff9865ffbde' 
AND id_auth IS NULL;

-- Verificar se foi atualizado
SELECT 
    id,
    id_auth,
    nome,
    CASE 
        WHEN id_auth = '4075ce47-aea6-4fca-92fc-305e5af6bdf1' THEN 'CORRIGIDO'
        WHEN id_auth IS NOT NULL THEN 'OK'
        ELSE 'PROBLEMA'
    END as status
FROM usuarios;
