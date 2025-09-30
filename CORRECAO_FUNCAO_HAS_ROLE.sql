-- =====================================================
-- CORREÇÃO DA FUNÇÃO has_role
-- =====================================================
-- Problema: A função has_role está verificando user_roles, 
-- mas o sistema original usa o campo nivel da tabela usuarios

-- ============================================
-- 1. CORRIGIR FUNÇÃO has_role
-- ============================================

-- Substituir a função has_role para usar o campo nivel da tabela usuarios
CREATE OR REPLACE FUNCTION public.has_role(role_slug text)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.usuarios u
    WHERE u.id_auth = auth.uid()
    AND u.nivel = role_slug
    AND u.ativo = true
  );
$$;

-- ============================================
-- 2. VERIFICAR SE A CORREÇÃO FUNCIONOU
-- ============================================

-- Testar a função corrigida
SELECT 
  'Teste da função has_role corrigida:' as status,
  has_role('administrador') as is_admin,
  has_role('jovem') as is_jovem,
  has_role('colaborador') as is_colaborador;

-- ============================================
-- 3. VERIFICAR DADOS DO USUÁRIO ATUAL
-- ============================================

-- Mostrar dados do usuário atual para verificação
SELECT 
  'Dados do usuário atual:' as status,
  u.id,
  u.nome,
  u.email,
  u.nivel,
  u.ativo,
  u.id_auth
FROM public.usuarios u
WHERE u.id_auth = auth.uid();

-- ============================================
-- 4. CONFIRMAÇÃO
-- ============================================

SELECT 'Função has_role corrigida com sucesso!' as status;
