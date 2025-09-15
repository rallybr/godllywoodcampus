-- =====================================================
-- CRIAR FUNÇÃO RPC PARA BUSCAR USUÁRIO POR AUTH_ID
-- =====================================================

-- Criar função que bypassa RLS
CREATE OR REPLACE FUNCTION get_user_by_auth_id(auth_id uuid)
RETURNS TABLE(id uuid, nome text, id_auth uuid)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT u.id, u.nome, u.id_auth
  FROM usuarios u
  WHERE u.id_auth = auth_id;
END;
$$;

-- Dar permissão para a função
GRANT EXECUTE ON FUNCTION get_user_by_auth_id(uuid) TO public;

-- Testar a função
SELECT * FROM get_user_by_auth_id('4075ce47-aea6-4fca-92fc-305e5af6bdf1');
