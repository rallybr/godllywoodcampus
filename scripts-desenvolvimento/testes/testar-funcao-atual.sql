-- Testar a função atual buscar_usuarios_com_ultimo_acesso
-- para verificar se está retornando a coluna foto

-- 1. Verificar se a função existe
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_name = 'buscar_usuarios_com_ultimo_acesso' 
AND routine_schema = 'public';

-- 2. Testar a função
SELECT id, nome, foto, ultimo_acesso 
FROM public.buscar_usuarios_com_ultimo_acesso() 
LIMIT 1;

-- 3. Verificar se a coluna foto existe na tabela usuarios
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'usuarios' 
AND table_schema = 'public'
AND column_name = 'foto';
