-- Teste completo da função RPC
-- Execute este script no Supabase SQL Editor

-- 1. Verificar se a função existe
SELECT 
  routine_name, 
  routine_type,
  data_type
FROM information_schema.routines 
WHERE routine_name = 'buscar_usuarios_com_ultimo_acesso' 
AND routine_schema = 'public';

-- 2. Verificar se a coluna foto existe na tabela usuarios
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'usuarios' 
AND table_schema = 'public'
AND column_name = 'foto';

-- 3. Testar a função com dados reais
SELECT 
  id, 
  nome, 
  foto, 
  ultimo_acesso,
  dias_sem_acesso,
  status_acesso
FROM public.buscar_usuarios_com_ultimo_acesso() 
LIMIT 3;

-- 4. Verificar se há usuários com foto
SELECT 
  COUNT(*) as total_usuarios,
  COUNT(foto) as usuarios_com_foto,
  COUNT(CASE WHEN foto IS NOT NULL AND foto != '' THEN 1 END) as fotos_validas
FROM public.usuarios;
