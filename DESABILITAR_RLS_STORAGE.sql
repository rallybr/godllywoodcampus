-- DESABILITAR RLS NO STORAGE
-- Execute este script no Supabase SQL Editor

-- 1. DESABILITAR RLS NA TABELA OBJECTS (STORAGE)
ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;

-- 2. VERIFICAR SE FOI DESABILITADO
SELECT 
    'STORAGE RLS STATUS' as status,
    schemaname,
    tablename,
    rowsecurity as rls_habilitado
FROM pg_tables 
WHERE schemaname = 'storage' AND tablename = 'objects';

-- 3. TESTAR UPLOAD SIMPLES (simulação)
-- Este teste não pode ser executado diretamente, mas o RLS desabilitado deve resolver

-- 4. VERIFICAR BUCKETS EXISTENTES
SELECT 
    'BUCKETS' as status,
    name,
    id,
    public
FROM storage.buckets
ORDER BY name;
