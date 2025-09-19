-- Verificar se o bucket fotos_jovens existe
SELECT 
  name as nome_bucket,
  public as publico,
  file_size_limit as limite_tamanho,
  allowed_mime_types as tipos_permitidos
FROM storage.buckets 
WHERE name = 'fotos_jovens';

-- Verificar todos os buckets disponíveis
SELECT 
  name as nome_bucket,
  public as publico,
  file_size_limit as limite_tamanho,
  allowed_mime_types as tipos_permitidos
FROM storage.buckets 
ORDER BY name;

-- Verificar políticas RLS do storage.objects
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
ORDER BY policyname;

-- Verificar se há políticas específicas para fotos_jovens
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
AND (qual LIKE '%fotos_jovens%' OR with_check LIKE '%fotos_jovens%')
ORDER BY policyname;
