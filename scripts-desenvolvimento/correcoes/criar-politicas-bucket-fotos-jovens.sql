-- Criar políticas RLS para o bucket fotos_jovens

-- 1. Política para permitir INSERT (upload) de fotos para usuários autenticados
CREATE POLICY "Allow upload fotos_jovens for authenticated users" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'fotos_jovens');

-- 2. Política para permitir SELECT (download/visualização) de fotos para usuários autenticados
CREATE POLICY "Allow select fotos_jovens for authenticated users" ON storage.objects
FOR SELECT TO authenticated
USING (bucket_id = 'fotos_jovens');

-- 3. Política para permitir UPDATE (atualização) de fotos para usuários autenticados
CREATE POLICY "Allow update fotos_jovens for authenticated users" ON storage.objects
FOR UPDATE TO authenticated
USING (bucket_id = 'fotos_jovens')
WITH CHECK (bucket_id = 'fotos_jovens');

-- 4. Política para permitir DELETE (exclusão) de fotos para usuários autenticados
CREATE POLICY "Allow delete fotos_jovens for authenticated users" ON storage.objects
FOR DELETE TO authenticated
USING (bucket_id = 'fotos_jovens');

-- Verificar se as políticas foram criadas
SELECT 
  policyname as nome_politica,
  cmd as comando,
  permissive as permissiva,
  roles as roles_aplicadas,
  qual as condicao_using,
  with_check as condicao_check
FROM pg_policies 
WHERE tablename = 'objects'
AND schemaname = 'storage'
AND policyname LIKE '%fotos_jovens%'
ORDER BY policyname;
