-- Verificar políticas RLS da tabela dados_viagem
SELECT 
  policyname as nome_politica,
  cmd as comando,
  permissive as permissiva,
  roles as roles_aplicadas,
  qual as condicao_using,
  with_check as condicao_check
FROM pg_policies 
WHERE tablename = 'dados_viagem'
ORDER BY policyname;

-- Verificar se RLS está habilitado na tabela dados_viagem
SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_habilitado
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename = 'dados_viagem';

-- Verificar estrutura da tabela dados_viagem
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'dados_viagem' 
AND table_schema = 'public'
ORDER BY ordinal_position;
