-- Script RÁPIDO para resolver o problema de upload de fotos de usuários
-- Execute este script no Supabase SQL Editor

-- 1. Criar bucket se não existir
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'fotos_usuarios',
  'fotos_usuarios',
  false,
  5242880,
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- 2. Remover políticas conflitantes
DROP POLICY IF EXISTS "Allow upload fotos_usuarios for authenticated users" ON storage.objects;
DROP POLICY IF EXISTS "Allow select fotos_usuarios for authenticated users" ON storage.objects;
DROP POLICY IF EXISTS "Allow update fotos_usuarios for authenticated users" ON storage.objects;
DROP POLICY IF EXISTS "Allow delete fotos_usuarios for authenticated users" ON storage.objects;

-- 3. Criar política simples para fotos_usuarios
CREATE POLICY "Allow all fotos_usuarios for authenticated users" ON storage.objects
FOR ALL TO authenticated
USING (bucket_id = 'fotos_usuarios')
WITH CHECK (bucket_id = 'fotos_usuarios');

-- 4. Verificar se funcionou
SELECT 'Bucket e políticas configurados!' as status;
SELECT name FROM storage.buckets WHERE name = 'fotos_usuarios';
SELECT policyname FROM pg_policies WHERE tablename = 'objects' AND policyname LIKE '%fotos_usuarios%';
