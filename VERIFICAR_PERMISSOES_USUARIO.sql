-- =====================================================
-- VERIFICAR E CORRIGIR PERMISSÕES DO USUÁRIO
-- =====================================================
-- Data: 2024-12-19
-- Objetivo: Verificar e corrigir permissões do usuário atual

-- =====================================================
-- 1. VERIFICAR USUÁRIO ATUAL
-- =====================================================

SELECT 
  'USUÁRIO ATUAL' as status,
  auth.uid() as user_id,
  current_user as current_user;

-- =====================================================
-- 2. VERIFICAR DADOS DO USUÁRIO NA TABELA USUARIOS
-- =====================================================

SELECT 
  'DADOS USUÁRIO' as status,
  u.id,
  u.nome,
  u.email,
  u.id_auth,
  u.ativo
FROM usuarios u
WHERE u.id_auth = auth.uid();

-- =====================================================
-- 3. VERIFICAR ROLES DO USUÁRIO
-- =====================================================

SELECT 
  'ROLES USUÁRIO' as status,
  u.nome as usuario_nome,
  r.slug as role_slug,
  r.nome as role_nome,
  ur.ativo as role_ativo,
  ur.estado_id,
  ur.bloco_id,
  ur.regiao_id,
  ur.igreja_id
FROM usuarios u
JOIN user_roles ur ON ur.user_id = u.id
JOIN roles r ON r.id = ur.role_id
WHERE u.id_auth = auth.uid()
ORDER BY r.slug;

-- =====================================================
-- 4. VERIFICAR SE EXISTE ROLE DE ADMINISTRADOR
-- =====================================================

SELECT 
  'ROLE ADMINISTRADOR' as status,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM usuarios u
      JOIN user_roles ur ON ur.user_id = u.id
      JOIN roles r ON r.id = ur.role_id
      WHERE u.id_auth = auth.uid()
      AND r.slug = 'administrador'
      AND ur.ativo = true
    ) THEN '✅ TEM ROLE ADMINISTRADOR'
    ELSE '❌ NÃO TEM ROLE ADMINISTRADOR'
  END as status_admin;

-- =====================================================
-- 5. VERIFICAR SE EXISTE ROLE DE COLABORADOR
-- =====================================================

SELECT 
  'ROLE COLABORADOR' as status,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM usuarios u
      JOIN user_roles ur ON ur.user_id = u.id
      JOIN roles r ON r.id = ur.role_id
      WHERE u.id_auth = auth.uid()
      AND r.slug = 'colaborador'
      AND ur.ativo = true
    ) THEN '✅ TEM ROLE COLABORADOR'
    ELSE '❌ NÃO TEM ROLE COLABORADOR'
  END as status_colaborador;

-- =====================================================
-- 6. VERIFICAR TODAS AS ROLES DISPONÍVEIS
-- =====================================================

SELECT 
  'ROLES DISPONÍVEIS' as status,
  slug,
  nome,
  descricao
FROM roles
ORDER BY slug;

-- =====================================================
-- 7. CRIAR ROLE DE ADMINISTRADOR SE NÃO EXISTIR
-- =====================================================

INSERT INTO roles (id, slug, nome, descricao, created_at, updated_at)
SELECT 
  gen_random_uuid(),
  'administrador',
  'Administrador',
  'Administrador do sistema com acesso total',
  now(),
  now()
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE slug = 'administrador');

-- =====================================================
-- 8. CRIAR ROLE DE COLABORADOR SE NÃO EXISTIR
-- =====================================================

INSERT INTO roles (id, slug, nome, descricao, created_at, updated_at)
SELECT 
  gen_random_uuid(),
  'colaborador',
  'Colaborador',
  'Colaborador com permissões de cadastro',
  now(),
  now()
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE slug = 'colaborador');

-- =====================================================
-- 9. ATRIBUIR ROLE DE ADMINISTRADOR AO USUÁRIO ATUAL
-- =====================================================

-- Primeiro, verificar se o usuário já tem alguma role
DO $$
DECLARE
  usuario_id uuid;
  admin_role_id uuid;
BEGIN
  -- Buscar ID do usuário
  SELECT id INTO usuario_id FROM usuarios WHERE id_auth = auth.uid();
  
  IF usuario_id IS NULL THEN
    RAISE NOTICE 'Usuário não encontrado na tabela usuarios';
    RETURN;
  END IF;
  
  -- Buscar ID da role de administrador
  SELECT id INTO admin_role_id FROM roles WHERE slug = 'administrador';
  
  IF admin_role_id IS NULL THEN
    RAISE NOTICE 'Role de administrador não encontrada';
    RETURN;
  END IF;
  
  -- Verificar se já tem a role
  IF NOT EXISTS (
    SELECT 1 FROM user_roles 
    WHERE user_id = usuario_id AND role_id = admin_role_id
  ) THEN
    -- Atribuir role de administrador
    INSERT INTO user_roles (id, user_id, role_id, ativo, created_at, updated_at)
    VALUES (gen_random_uuid(), usuario_id, admin_role_id, true, now(), now());
    
    RAISE NOTICE 'Role de administrador atribuída ao usuário';
  ELSE
    RAISE NOTICE 'Usuário já possui role de administrador';
  END IF;
END $$;

-- =====================================================
-- 10. VERIFICAR PERMISSÕES APÓS CORREÇÃO
-- =====================================================

SELECT 
  'PERMISSÕES APÓS CORREÇÃO' as status,
  u.nome as usuario_nome,
  r.slug as role_slug,
  r.nome as role_nome,
  ur.ativo as role_ativo
FROM usuarios u
JOIN user_roles ur ON ur.user_id = u.id
JOIN roles r ON r.id = ur.role_id
WHERE u.id_auth = auth.uid()
ORDER BY r.slug;
