-- Verificar se a coluna foto existe na tabela usuarios
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'usuarios' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Testar a função buscar_usuarios_com_ultimo_acesso
SELECT * FROM public.buscar_usuarios_com_ultimo_acesso() LIMIT 1;