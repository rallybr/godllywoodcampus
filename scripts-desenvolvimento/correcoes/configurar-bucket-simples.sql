-- Script simplificado para configurar o bucket 'viagens'
-- Execute este script no Supabase SQL Editor

-- ============================================
-- 1. VERIFICAR BUCKET
-- ============================================

SELECT 'Verificando bucket viagens...' as status;
SELECT * FROM storage.buckets WHERE name = 'viagens';

-- ============================================
-- 2. REMOVER POLÍTICAS EXISTENTES
-- ============================================

-- Remover todas as políticas existentes para storage.objects
DROP POLICY IF EXISTS "Permitir upload de comprovantes" ON storage.objects;
DROP POLICY IF EXISTS "Permitir visualização de comprovantes" ON storage.objects;
DROP POLICY IF EXISTS "Permitir exclusão de comprovantes" ON storage.objects;
DROP POLICY IF EXISTS "Public Access" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can view" ON storage.objects;

-- ============================================
-- 3. CRIAR POLÍTICAS SIMPLES
-- ============================================

-- Política para permitir upload (usuários autenticados)
CREATE POLICY "Authenticated users can upload" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'viagens' 
  AND auth.uid() IS NOT NULL
);

-- Política para permitir visualização (usuários autenticados)
CREATE POLICY "Authenticated users can view" ON storage.objects
FOR SELECT TO authenticated
USING (
  bucket_id = 'viagens'
  AND auth.uid() IS NOT NULL
);

-- Política para permitir exclusão (usuários autenticados)
CREATE POLICY "Authenticated users can delete" ON storage.objects
FOR DELETE TO authenticated
USING (
  bucket_id = 'viagens'
  AND auth.uid() IS NOT NULL
);

-- ============================================
-- 4. VERIFICAR POLÍTICAS CRIADAS
-- ============================================

SELECT 'Políticas criadas:' as status;
SELECT policyname, cmd, permissive, roles
FROM pg_policies 
WHERE schemaname = 'storage' 
  AND tablename = 'objects'
ORDER BY policyname;

-- ============================================
-- 5. TESTE DE PERMISSÕES
-- ============================================

SELECT 'Testando permissões...' as status;
SELECT 
  has_table_privilege('storage.objects', 'SELECT') as pode_select,
  has_table_privilege('storage.objects', 'INSERT') as pode_insert,
  has_table_privilege('storage.objects', 'DELETE') as pode_delete;

SELECT 'Configuração concluída!' as resultado;
