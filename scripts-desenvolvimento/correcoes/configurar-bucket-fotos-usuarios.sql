-- Configurar bucket para fotos de usuários
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'fotos-usuarios',
  'fotos-usuarios',
  true,
  5242880, -- 5MB
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 5242880,
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp'];

-- Políticas RLS para o bucket de fotos de usuários
CREATE POLICY "Enable read access for all authenticated users"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'fotos-usuarios');

CREATE POLICY "Enable insert for authenticated users"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'fotos-usuarios');

CREATE POLICY "Enable update for authenticated users"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'fotos-usuarios');

CREATE POLICY "Enable delete for authenticated users"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'fotos-usuarios');

-- Verificar se o bucket foi criado
SELECT * FROM storage.buckets WHERE id = 'fotos-usuarios';
