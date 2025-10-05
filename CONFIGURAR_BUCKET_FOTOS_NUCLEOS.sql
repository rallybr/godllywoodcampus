-- Script para configurar o bucket "fotos_nucleos" no Supabase Storage
-- Execute este script no SQL Editor do Supabase

-- 1. Criar o bucket "fotos_nucleos" se não existir
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'fotos_nucleos',
  'fotos_nucleos',
  true, -- Bucket público para permitir acesso às imagens
  52428800, -- 50MB limite por arquivo
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml']
)
ON CONFLICT (id) DO NOTHING;

-- 2. Configurar políticas RLS para o bucket
-- Política para permitir que usuários autenticados façam upload
CREATE POLICY "Usuários autenticados podem fazer upload de fotos do núcleo"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'fotos_nucleos');

-- Política para permitir que usuários autenticados vejam as fotos
CREATE POLICY "Usuários autenticados podem ver fotos do núcleo"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'fotos_nucleos');

-- Política para permitir que usuários autenticados atualizem suas próprias fotos
CREATE POLICY "Usuários podem atualizar suas próprias fotos do núcleo"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'fotos_nucleos' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Política para permitir que usuários autenticados deletem suas próprias fotos
CREATE POLICY "Usuários podem deletar suas próprias fotos do núcleo"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'fotos_nucleos' AND auth.uid()::text = (storage.foldername(name))[1]);

-- 3. Verificar se o bucket foi criado
SELECT * FROM storage.buckets WHERE id = 'fotos_nucleos';

-- 4. Verificar as políticas criadas
SELECT * FROM pg_policies WHERE tablename = 'objects' AND policyname LIKE '%fotos_nucleos%';
