-- Testar a função buscar_usuarios_com_ultimo_acesso
-- após reativar as políticas RLS

-- 1. Testar a função diretamente
SELECT 
  id, 
  nome, 
  foto, 
  ultimo_acesso,
  dias_sem_acesso,
  status_acesso
FROM public.buscar_usuarios_com_ultimo_acesso() 
LIMIT 3;

-- 2. Verificar se há usuários com foto
SELECT 
  COUNT(*) as total_usuarios,
  COUNT(foto) as usuarios_com_foto,
  COUNT(CASE WHEN foto IS NOT NULL AND foto != '' THEN 1 END) as fotos_validas
FROM public.usuarios;

-- 3. Testar acesso direto à tabela usuarios
SELECT 
  id, 
  nome, 
  foto, 
  ultimo_acesso
FROM public.usuarios 
LIMIT 3;

-- 4. Verificar se a função está retornando dados corretos
SELECT 
  'Função RPC' as fonte,
  COUNT(*) as total_registros,
  COUNT(foto) as com_foto
FROM public.buscar_usuarios_com_ultimo_acesso()
UNION ALL
SELECT 
  'Tabela direta' as fonte,
  COUNT(*) as total_registros,
  COUNT(foto) as com_foto
FROM public.usuarios;
