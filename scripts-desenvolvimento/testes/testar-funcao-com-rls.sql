-- Testar a função buscar_usuarios_com_ultimo_acesso
-- considerando que as políticas RLS foram desabilitadas

-- 1. Verificar se a função existe e está funcionando
SELECT 
  routine_name, 
  routine_type,
  security_type
FROM information_schema.routines 
WHERE routine_name = 'buscar_usuarios_com_ultimo_acesso' 
AND routine_schema = 'public';

-- 2. Testar a função diretamente
SELECT 
  id, 
  nome, 
  foto, 
  ultimo_acesso,
  dias_sem_acesso,
  status_acesso
FROM public.buscar_usuarios_com_ultimo_acesso() 
LIMIT 3;

-- 3. Verificar se há usuários com foto
SELECT 
  COUNT(*) as total_usuarios,
  COUNT(foto) as usuarios_com_foto,
  COUNT(CASE WHEN foto IS NOT NULL AND foto != '' THEN 1 END) as fotos_validas
FROM public.usuarios;

-- 4. Verificar políticas RLS da tabela usuarios
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies 
WHERE tablename = 'usuarios';
