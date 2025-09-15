-- =====================================================
-- VERIFICAR ID_AUTH ATUAL DO USUÁRIO LOGADO
-- =====================================================

-- Verificar todos os usuários e seus id_auth
SELECT 
    id,
    nome,
    id_auth,
    email,
    CASE 
        WHEN id_auth = '346d397f-1a05-4e17-8bed-f94274b78fe0' THEN 'USUÁRIO ATUAL'
        WHEN id_auth = '4075ce47-aea6-4fca-92fc-305e5af6bdf1' THEN 'ADMIN ORIGINAL'
        ELSE 'OUTRO'
    END as status
FROM usuarios
ORDER BY criado_em DESC;

-- Verificar se existe usuário com o id_auth atual
SELECT 
    COUNT(*) as total,
    COUNT(CASE WHEN id_auth = '346d397f-1a05-4e17-8bed-f94274b78fe0' THEN 1 END) as com_id_atual,
    COUNT(CASE WHEN id_auth = '4075ce47-aea6-4fca-92fc-305e5af6bdf1' THEN 1 END) as com_id_admin
FROM usuarios;
