-- SOLUÇÃO DIRETA - ATRIBUIR ADMIN A TODOS OS USUÁRIOS
-- Execute este script no Supabase SQL Editor

-- 1. Verificar usuários existentes
SELECT 'USUÁRIOS' as status, id, email, nome FROM usuarios WHERE ativo = true;

-- 2. Verificar roles existentes  
SELECT 'ROLES' as status, id, slug, nome FROM roles;

-- 3. Atribuir role administrador a TODOS os usuários ativos
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
AND u.ativo = true
AND NOT EXISTS (
    SELECT 1 FROM user_roles ur2 
    WHERE ur2.user_id = u.id 
    AND ur2.role_id = r.id
);

-- 4. Verificar se funcionou
SELECT 'RESULTADO' as status, 
    is_admin_user() as is_admin,
    has_role('administrador') as has_admin_role;
