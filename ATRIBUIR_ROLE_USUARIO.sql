-- =====================================================
-- ATRIBUIR ROLE DE ADMINISTRADOR AO USUÁRIO ATUAL
-- =====================================================
-- Data: 2024-12-19
-- Objetivo: Atribuir role de administrador ao usuário atual

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
-- 3. VERIFICAR ROLES ATUAIS DO USUÁRIO
-- =====================================================

SELECT 
  'ROLES ATUAIS' as status,
  u.nome as usuario_nome,
  r.slug as role_slug,
  r.nome as role_nome,
  ur.ativo as role_ativo
FROM usuarios u
JOIN user_roles ur ON ur.user_id = u.id
JOIN roles r ON r.id = ur.role_id
WHERE u.id_auth = auth.uid()
ORDER BY r.slug;

-- =====================================================
-- 4. ATRIBUIR ROLE DE ADMINISTRADOR
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
  
  RAISE NOTICE 'Usuário encontrado: %', usuario_id;
  
  -- Buscar ID da role de administrador
  SELECT id INTO admin_role_id FROM roles WHERE slug = 'administrador';
  
  IF admin_role_id IS NULL THEN
    RAISE NOTICE 'Role de administrador não encontrada';
    RETURN;
  END IF;
  
  RAISE NOTICE 'Role de administrador encontrada: %', admin_role_id;
  
  -- Verificar se já tem a role
  IF NOT EXISTS (
    SELECT 1 FROM user_roles 
    WHERE user_id = usuario_id AND role_id = admin_role_id
  ) THEN
    -- Atribuir role de administrador
    INSERT INTO user_roles (id, user_id, role_id, ativo)
    VALUES (gen_random_uuid(), usuario_id, admin_role_id, true);
    
    RAISE NOTICE 'Role de administrador atribuída ao usuário';
  ELSE
    RAISE NOTICE 'Usuário já possui role de administrador';
  END IF;
END $$;

-- =====================================================
-- 5. VERIFICAR PERMISSÕES APÓS ATRIBUIÇÃO
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
