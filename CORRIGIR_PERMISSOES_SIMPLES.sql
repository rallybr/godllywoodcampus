-- =====================================================
-- CORRIGIR PERMISSÕES DO USUÁRIO - VERSÃO SIMPLES
-- =====================================================
-- Data: 2024-12-19
-- Objetivo: Corrigir permissões do usuário atual

-- =====================================================
-- 1. VERIFICAR USUÁRIO ATUAL
-- =====================================================

SELECT 
  'USUÁRIO ATUAL' as status,
  auth.uid() as user_id,
  current_user as current_user;

-- =====================================================
-- 2. VERIFICAR DADOS DO USUÁRIO
-- =====================================================

SELECT 
  'DADOS USUÁRIO' as status,
  u.id,
  u.nome,
  u.email,
  u.id_auth
FROM usuarios u
WHERE u.id_auth = auth.uid();

-- =====================================================
-- 3. VERIFICAR ROLES EXISTENTES
-- =====================================================

SELECT 
  'ROLES EXISTENTES' as status,
  slug,
  nome,
  descricao
FROM roles
ORDER BY slug;

-- =====================================================
-- 4. CRIAR ROLES SE NÃO EXISTIREM
-- =====================================================

-- Criar role de administrador
INSERT INTO roles (id, slug, nome, descricao, created_at, updated_at)
SELECT 
  gen_random_uuid(),
  'administrador',
  'Administrador',
  'Administrador do sistema',
  now(),
  now()
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE slug = 'administrador');

-- Criar role de colaborador
INSERT INTO roles (id, slug, nome, descricao, created_at, updated_at)
SELECT 
  gen_random_uuid(),
  'colaborador',
  'Colaborador',
  'Colaborador do sistema',
  now(),
  now()
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE slug = 'colaborador');

-- =====================================================
-- 5. ATRIBUIR ROLE DE ADMINISTRADOR AO USUÁRIO
-- =====================================================

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
-- 6. VERIFICAR PERMISSÕES APÓS CORREÇÃO
-- =====================================================

SELECT 
  'PERMISSÕES FINAIS' as status,
  u.nome as usuario_nome,
  r.slug as role_slug,
  r.nome as role_nome,
  ur.ativo as role_ativo
FROM usuarios u
JOIN user_roles ur ON ur.user_id = u.id
JOIN roles r ON r.id = ur.role_id
WHERE u.id_auth = auth.uid()
ORDER BY r.slug;
