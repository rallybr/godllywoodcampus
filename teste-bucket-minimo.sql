-- Script mínimo para testar o bucket 'viagens'
-- Execute este script no Supabase SQL Editor

-- Teste 1: Verificar se conseguimos acessar a tabela storage.buckets
SELECT 'Teste 1 - Acessando storage.buckets:' as teste;
SELECT COUNT(*) as total_buckets FROM storage.buckets;

-- Teste 2: Verificar se o bucket viagens existe
SELECT 'Teste 2 - Bucket viagens existe:' as teste;
SELECT name FROM storage.buckets WHERE name = 'viagens';

-- Teste 3: Verificar usuário atual
SELECT 'Teste 3 - Usuário atual:' as teste;
SELECT auth.uid() as user_id;

-- Teste 4: Verificar se conseguimos acessar storage.objects
SELECT 'Teste 4 - Acessando storage.objects:' as teste;
SELECT COUNT(*) as total_objects FROM storage.objects;

-- Teste 5: Verificar políticas existentes
SELECT 'Teste 5 - Políticas existentes:' as teste;
SELECT COUNT(*) as total_policies 
FROM pg_policies 
WHERE schemaname = 'storage' AND tablename = 'objects';

-- Teste 6: Listar políticas
SELECT 'Teste 6 - Listando políticas:' as teste;
SELECT policyname, cmd 
FROM pg_policies 
WHERE schemaname = 'storage' AND tablename = 'objects';

SELECT 'Testes concluídos!' as resultado;
