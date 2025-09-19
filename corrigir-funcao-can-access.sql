-- Script para corrigir a função can_access_jovem com todos os níveis de acesso
-- Execute este script no Supabase SQL Editor

-- ============================================
-- 1. ATUALIZAR FUNÇÃO EXISTENTE
-- ============================================

CREATE OR REPLACE FUNCTION can_access_jovem(
  jovem_estado_id uuid,
  jovem_bloco_id uuid,
  jovem_regiao_id uuid,
  jovem_igreja_id uuid
) RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_user_id uuid;
  user_role_slug text;
  user_estado_id uuid;
  user_bloco_id uuid;
  user_regiao_id uuid;
  user_igreja_id uuid;
BEGIN
  -- Obter o ID do usuário atual
  current_user_id := (SELECT id FROM public.usuarios WHERE id_auth = auth.uid());
  
  IF current_user_id IS NULL THEN
    RETURN false;
  END IF;
  
  -- Obter dados do usuário atual
  SELECT u.estado_id, u.bloco_id, u.regiao_id, u.igreja_id
  INTO user_estado_id, user_bloco_id, user_regiao_id, user_igreja_id
  FROM public.usuarios u
  WHERE u.id = current_user_id;
  
  -- Verificar se é administrador (acesso total)
  SELECT r.slug INTO user_role_slug
  FROM public.user_roles ur
  JOIN public.roles r ON r.id = ur.role_id
  WHERE ur.user_id = current_user_id
    AND ur.ativo = true
    AND r.slug = 'administrador';
  
  IF user_role_slug IS NOT NULL THEN
    RETURN true;
  END IF;
  
  -- Verificar líderes nacionais (acesso total)
  SELECT r.slug INTO user_role_slug
  FROM public.user_roles ur
  JOIN public.roles r ON r.id = ur.role_id
  WHERE ur.user_id = current_user_id
    AND ur.ativo = true
    AND r.slug IN ('lider_nacional_iurd', 'lider_nacional_fju');
  
  IF user_role_slug IS NOT NULL THEN
    RETURN true;
  END IF;
  
  -- Verificar líderes estaduais (acesso a nível estadual)
  SELECT r.slug INTO user_role_slug
  FROM public.user_roles ur
  JOIN public.roles r ON r.id = ur.role_id
  WHERE ur.user_id = current_user_id
    AND ur.ativo = true
    AND r.slug IN ('lider_estadual_iurd', 'lider_estadual_fju')
    AND ur.estado_id = jovem_estado_id;
  
  IF user_role_slug IS NOT NULL THEN
    RETURN true;
  END IF;
  
  -- Verificar líderes de bloco (acesso a nível de bloco)
  SELECT r.slug INTO user_role_slug
  FROM public.user_roles ur
  JOIN public.roles r ON r.id = ur.role_id
  WHERE ur.user_id = current_user_id
    AND ur.ativo = true
    AND r.slug IN ('lider_bloco_iurd', 'lider_bloco_fju')
    AND ur.bloco_id = jovem_bloco_id;
  
  IF user_role_slug IS NOT NULL THEN
    RETURN true;
  END IF;
  
  -- Verificar líder regional (acesso a nível de região)
  SELECT r.slug INTO user_role_slug
  FROM public.user_roles ur
  JOIN public.roles r ON r.id = ur.role_id
  WHERE ur.user_id = current_user_id
    AND ur.ativo = true
    AND r.slug = 'lider_regional_iurd'
    AND ur.regiao_id = jovem_regiao_id;
  
  IF user_role_slug IS NOT NULL THEN
    RETURN true;
  END IF;
  
  -- Verificar líder de igreja (acesso a nível de igreja)
  SELECT r.slug INTO user_role_slug
  FROM public.user_roles ur
  JOIN public.roles r ON r.id = ur.role_id
  WHERE ur.user_id = current_user_id
    AND ur.ativo = true
    AND r.slug = 'lider_igreja_iurd'
    AND ur.igreja_id = jovem_igreja_id;
  
  IF user_role_slug IS NOT NULL THEN
    RETURN true;
  END IF;
  
  -- Verificar colaborador (acesso a nível que ele mesmo criou)
  SELECT r.slug INTO user_role_slug
  FROM public.user_roles ur
  JOIN public.roles r ON r.id = ur.role_id
  WHERE ur.user_id = current_user_id
    AND ur.ativo = true
    AND r.slug = 'colaborador';
  
  IF user_role_slug IS NOT NULL THEN
    RETURN true;
  END IF;
  
  -- Se chegou até aqui, não tem permissão
  RETURN false;
END;
$$;

-- ============================================
-- 3. VERIFICAÇÃO
-- ============================================

-- Verificar se a função foi criada
SELECT 
  'Função can_access_jovem criada:' as status,
  EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' AND p.proname = 'can_access_jovem'
  ) as existe;

-- ============================================
-- 4. TESTE DA FUNÇÃO
-- ============================================

-- Testar a função com os UUIDs do jovem Roberto Araújo
SELECT can_access_jovem(
  '3373645f-f666-5b4e-a0b0-3556f45a0cc2',  -- estado_id
  '06197858-a185-59c0-aa20-ded00fff6b2f',  -- bloco_id
  'fe26979e-d3c9-52e9-8058-4c09a917f61b',  -- regiao_id
  '9afae78a-ee75-5aad-82d9-64e058c9ea5c'   -- igreja_id
) as resultado_teste;
