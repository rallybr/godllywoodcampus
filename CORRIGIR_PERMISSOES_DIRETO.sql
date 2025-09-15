-- =====================================================
-- CORRIGIR PERMISSÕES DIRETAMENTE
-- =====================================================
-- Data: 2024-12-19
-- Objetivo: Corrigir permissões sem depender de auth.uid()

-- =====================================================
-- 1. VERIFICAR USUÁRIOS EXISTENTES
-- =====================================================

SELECT 
  'USUÁRIOS EXISTENTES' as status,
  id,
  nome,
  email,
  id_auth,
  ativo
FROM usuarios
ORDER BY nome;

-- =====================================================
-- 2. VERIFICAR ROLES EXISTENTES
-- =====================================================

SELECT 
  'ROLES EXISTENTES' as status,
  id,
  slug,
  nome,
  descricao
FROM roles
ORDER BY slug;

-- =====================================================
-- 3. VERIFICAR USER_ROLES EXISTENTES
-- =====================================================

SELECT 
  'USER_ROLES EXISTENTES' as status,
  ur.id,
  u.nome as usuario_nome,
  r.slug as role_slug,
  r.nome as role_nome,
  ur.ativo
FROM user_roles ur
JOIN usuarios u ON u.id = ur.user_id
JOIN roles r ON r.id = ur.role_id
ORDER BY u.nome, r.slug;

-- =====================================================
-- 4. ATRIBUIR ROLE DE ADMINISTRADOR A TODOS OS USUÁRIOS
-- =====================================================

-- Primeiro, obter o ID da role de administrador
DO $$
DECLARE
  admin_role_id uuid;
  usuario_record RECORD;
BEGIN
  -- Buscar ID da role de administrador
  SELECT id INTO admin_role_id FROM roles WHERE slug = 'administrador';
  
  IF admin_role_id IS NULL THEN
    RAISE NOTICE 'Role de administrador não encontrada';
    RETURN;
  END IF;
  
  RAISE NOTICE 'Role de administrador encontrada: %', admin_role_id;
  
  -- Atribuir role de administrador a todos os usuários que não têm
  FOR usuario_record IN 
    SELECT id, nome FROM usuarios WHERE ativo = true
  LOOP
    -- Verificar se já tem a role
    IF NOT EXISTS (
      SELECT 1 FROM user_roles 
      WHERE user_id = usuario_record.id AND role_id = admin_role_id
    ) THEN
      -- Atribuir role de administrador
      INSERT INTO user_roles (id, user_id, role_id, ativo)
      VALUES (gen_random_uuid(), usuario_record.id, admin_role_id, true);
      
      RAISE NOTICE 'Role de administrador atribuída ao usuário: %', usuario_record.nome;
    ELSE
      RAISE NOTICE 'Usuário % já possui role de administrador', usuario_record.nome;
    END IF;
  END LOOP;
END $$;

-- =====================================================
-- 5. VERIFICAR PERMISSÕES APÓS CORREÇÃO
-- =====================================================

SELECT 
  'PERMISSÕES FINAIS' as status,
  u.nome as usuario_nome,
  u.email as usuario_email,
  r.slug as role_slug,
  r.nome as role_nome,
  ur.ativo as role_ativo
FROM usuarios u
JOIN user_roles ur ON ur.user_id = u.id
JOIN roles r ON r.id = ur.role_id
WHERE u.ativo = true
ORDER BY u.nome, r.slug;
