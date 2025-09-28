-- Verificar se a tabela roles existe e sua estrutura
SELECT 
  table_name,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'roles' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- Verificar se existem dados na tabela roles
SELECT COUNT(*) as total_roles FROM public.roles;

-- Listar alguns papéis existentes
SELECT id, nome, slug, nivel_hierarquico 
FROM public.roles 
ORDER BY nivel_hierarquico ASC 
LIMIT 10;
