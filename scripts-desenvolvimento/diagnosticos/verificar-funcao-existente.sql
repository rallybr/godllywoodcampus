-- Verificar se a função buscar_usuarios_com_ultimo_acesso já existe no banco
SELECT 
  routine_name, 
  routine_type,
  routine_definition
FROM information_schema.routines 
WHERE routine_name = 'buscar_usuarios_com_ultimo_acesso' 
AND routine_schema = 'public';

-- Testar a função se ela existir
SELECT * FROM public.buscar_usuarios_com_ultimo_acesso() LIMIT 1;
