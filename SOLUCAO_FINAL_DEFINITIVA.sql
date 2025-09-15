-- SOLUÇÃO FINAL DEFINITIVA
-- Execute este script no Supabase SQL Editor

-- 1. Verificar usuários existentes
SELECT 'USUÁRIOS' as status, id, email, nome FROM usuarios WHERE ativo = true;

-- 2. Verificar roles existentes  
SELECT 'ROLES' as status, id, slug, nome FROM roles;

-- 3. Verificar user_roles atuais
SELECT 'USER_ROLES ATUAL' as status, 
    ur.id, 
    ur.user_id, 
    ur.role_id, 
    r.slug, 
    ur.ativo
FROM user_roles ur
JOIN roles r ON r.id = ur.role_id
ORDER BY ur.user_id;

-- 4. Atribuir role administrador a TODOS os usuários ativos (forçar)
DELETE FROM user_roles WHERE role_id = (SELECT id FROM roles WHERE slug = 'administrador');

INSERT INTO user_roles (user_id, role_id, ativo, estado_id, bloco_id, regiao_id, igreja_id)
SELECT 
    u.id,
    r.id,
    true,
    u.estado_id,
    u.bloco_id,
    u.regiao_id,
    u.igreja_id
FROM usuarios u
CROSS JOIN roles r
WHERE r.slug = 'administrador'
AND u.ativo = true;

-- 5. Verificar se foi inserido
SELECT 'APÓS INSERÇÃO' as status, 
    ur.id, 
    ur.user_id, 
    ur.role_id, 
    r.slug, 
    ur.ativo
FROM user_roles ur
JOIN roles r ON r.id = ur.role_id
WHERE r.slug = 'administrador'
ORDER BY ur.user_id;

-- 6. Testar com usuário específico (substitua pelo seu ID)
SELECT 'TESTE ESPECÍFICO' as status,
    u.id as user_id,
    u.email,
    EXISTS(
        SELECT 1 FROM user_roles ur2
        JOIN roles r2 ON r2.id = ur2.role_id
        WHERE ur2.user_id = u.id
        AND r2.slug = 'administrador'
        AND ur2.ativo = true
    ) as tem_admin_role
FROM usuarios u
WHERE u.email = 'bpguerrafju@gmail.com';
