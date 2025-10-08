-- Verificar políticas RLS que usam can_access_jovem
SELECT 
  schemaname, 
  tablename, 
  policyname, 
  permissive, 
  roles, 
  cmd, 
  qual 
FROM pg_policies 
WHERE qual LIKE '%can_access_jovem%';
