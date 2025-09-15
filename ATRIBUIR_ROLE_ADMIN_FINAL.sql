-- =====================================================
-- ATRIBUIR ROLE ADMINISTRADOR AO USUÁRIO ATUAL
-- =====================================================
-- Data: 2024-12-19
-- Objetivo: Atribuir role administrador ao usuário atual

-- =====================================================
-- 1. VERIFICAR USUÁRIO ATUAL
-- =====================================================

SELECT 
    'USUÁRIO ATUAL' as status,
    auth.uid() as user_id_auth,
    u.id as user_id_table,
    u.email,
    u.nome
FROM usuarios u
WHERE u.id_auth = auth.uid();

-- =====================================================
-- 2. VERIFICAR ROLES EXISTENTES
-- =====================================================

SELECT 
    'ROLES EXISTENTES' as status,
    id,
    slug,
    nome
FROM roles
ORDER BY slug;

-- =====================================================
-- 3. VERIFICAR USER_ROLES ATUAL
-- =====================================================

SELECT 
    'USER_ROLES ATUAL' as status,
    ur.id,
    ur.user_id,
    ur.role_id,
    r.slug,
    r.nome,
    ur.ativo
FROM user_roles ur
JOIN roles r ON r.id = ur.role_id
WHERE ur.user_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid());

-- =====================================================
-- 4. ATRIBUIR ROLE ADMINISTRADOR
-- =====================================================

-- Primeiro, vamos atribuir a TODOS os usuários ativos
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

-- =====================================================
-- 5. VERIFICAR APÓS ATRIBUIÇÃO
-- =====================================================

SELECT 
    'APÓS ATRIBUIÇÃO' as status,
    ur.id,
    ur.user_id,
    ur.role_id,
    r.slug,
    r.nome,
    ur.ativo
FROM user_roles ur
JOIN roles r ON r.id = ur.role_id
WHERE ur.user_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid());

-- =====================================================
-- 6. TESTAR FUNÇÕES AUXILIARES
-- =====================================================

SELECT 
    'TESTE FUNÇÕES' as status,
    is_admin_user() as is_admin,
    has_role('administrador') as has_admin_role,
    can_access_jovem(
        'c20e70c2-92e6-4c50-96a5-177822095a25'::uuid,
        'b0cb2a8a-5b89-478b-95a9-a5bb8e84f06d'::uuid,
        '84cff91c-3afa-49da-b211-24f50f7cb2ab'::uuid,
        'd3301078-fc09-4131-b9e8-03c78570a774'::uuid
    ) as can_access;
