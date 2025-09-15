-- =====================================================
-- VERIFICAR SE USUÁRIO É ADMIN
-- =====================================================

-- Verificar se a função is_admin_user() funciona
SELECT is_admin_user() as is_admin;

-- Verificar se o usuário tem role de administrador
SELECT 
    u.id,
    u.nome,
    u.id_auth,
    r.slug as role_slug,
    r.nome as role_nome
FROM usuarios u
LEFT JOIN user_roles ur ON u.id = ur.user_id
LEFT JOIN roles r ON ur.role_id = r.id
WHERE u.id_auth = '4075ce47-aea6-4fca-92fc-305e5af6bdf1';

-- Verificar todas as roles do usuário
SELECT 
    u.nome,
    r.slug,
    r.nome as role_nome
FROM usuarios u
JOIN user_roles ur ON u.id = ur.user_id
JOIN roles r ON ur.role_id = r.id
WHERE u.id_auth = '4075ce47-aea6-4fca-92fc-305e5af6bdf1';
