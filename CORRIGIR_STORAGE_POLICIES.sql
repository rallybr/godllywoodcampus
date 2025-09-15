-- CORRIGIR POLÍTICAS DE STORAGE
-- Execute este script no Supabase SQL Editor

-- 1. REMOVER POLÍTICAS EXISTENTES DO STORAGE
DROP POLICY IF EXISTS "fotos_usuarios_policy" ON storage.objects;
DROP POLICY IF EXISTS "fotos_jovens_policy" ON storage.objects;
DROP POLICY IF EXISTS "documentos_policy" ON storage.objects;
DROP POLICY IF EXISTS "backups_policy" ON storage.objects;
DROP POLICY IF EXISTS "temp_policy" ON storage.objects;

-- 2. CRIAR POLÍTICAS MAIS PERMISSIVAS
-- Política para fotos_usuarios - permitir tudo para usuários autenticados
CREATE POLICY "fotos_usuarios_policy" ON storage.objects
    FOR ALL
    TO authenticated
    USING (bucket_id = 'fotos_usuarios')
    WITH CHECK (bucket_id = 'fotos_usuarios');

-- Política para fotos_jovens - permitir tudo para usuários autenticados
CREATE POLICY "fotos_jovens_policy" ON storage.objects
    FOR ALL
    TO authenticated
    USING (bucket_id = 'fotos_jovens')
    WITH CHECK (bucket_id = 'fotos_jovens');

-- Política para documentos - permitir tudo para usuários autenticados
CREATE POLICY "documentos_policy" ON storage.objects
    FOR ALL
    TO authenticated
    USING (bucket_id = 'documentos')
    WITH CHECK (bucket_id = 'documentos');

-- Política para backups - permitir tudo para usuários autenticados
CREATE POLICY "backups_policy" ON storage.objects
    FOR ALL
    TO authenticated
    USING (bucket_id = 'backups')
    WITH CHECK (bucket_id = 'backups');

-- Política para temp - permitir tudo para usuários autenticados
CREATE POLICY "temp_policy" ON storage.objects
    FOR ALL
    TO authenticated
    USING (bucket_id = 'temp')
    WITH CHECK (bucket_id = 'temp');

-- 3. VERIFICAR POLÍTICAS CRIADAS
SELECT 
    'STORAGE POLICIES' as status,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies 
WHERE schemaname = 'storage' AND tablename = 'objects'
ORDER BY policyname;

-- 4. VERIFICAR BUCKETS
SELECT 
    'BUCKETS' as status,
    name,
    id,
    public
FROM storage.buckets
ORDER BY name;
