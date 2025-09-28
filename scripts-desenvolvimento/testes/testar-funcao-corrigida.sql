-- Testar se a função buscar_usuarios_com_ultimo_acesso
-- foi corrigida e está retornando a coluna foto

-- 1. Verificar se a função existe
SELECT 
  routine_name, 
  routine_type,
  data_type
FROM information_schema.routines 
WHERE routine_name = 'buscar_usuarios_com_ultimo_acesso' 
AND routine_schema = 'public';

-- 2. Testar a função diretamente
SELECT 
  id, 
  nome, 
  foto, 
  ultimo_acesso
FROM public.buscar_usuarios_com_ultimo_acesso() 
LIMIT 3;

-- 3. Verificar se há usuários com foto na tabela
SELECT 
  id,
  nome,
  foto,
  CASE 
    WHEN foto IS NULL THEN 'NULL'
    WHEN foto = '' THEN 'VAZIO'
    ELSE 'TEM FOTO'
  END as status_foto
FROM public.usuarios 
LIMIT 5;

-- 4. Verificar se a função está retornando dados corretos
SELECT 
  'Função RPC' as fonte,
  COUNT(*) as total_registros,
  COUNT(foto) as com_foto,
  COUNT(CASE WHEN foto IS NOT NULL AND foto != '' THEN 1 END) as fotos_validas
FROM public.buscar_usuarios_com_ultimo_acesso()
UNION ALL
SELECT 
  'Tabela direta' as fonte,
  COUNT(*) as total_registros,
  COUNT(foto) as com_foto,
  COUNT(CASE WHEN foto IS NOT NULL AND foto != '' THEN 1 END) as fotos_validas
FROM public.usuarios;
