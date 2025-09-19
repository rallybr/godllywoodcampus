-- Script para configurar políticas RLS para o bucket fotos_usuarios
-- Execute este script no Supabase SQL Editor

-- ============================================
-- 1. VERIFICAR SE O BUCKET EXISTE
-- ============================================

SELECT 'Verificando bucket fotos_usuarios...' as status;
SELECT * FROM storage.buckets WHERE name = 'fotos_usuarios';

-- ============================================
-- 2. CRIAR BUCKET SE NÃO EXISTIR
-- ============================================

-- Criar bucket fotos_usuarios se não existir
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'fotos_usuarios',
  'fotos_usuarios',
  false, -- Não público
  5242880, -- 5MB limite
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- 3. REMOVER POLÍTICAS EXISTENTES (SE HOUVER)
-- ============================================

-- Remover políticas existentes para fotos_usuarios
DROP POLICY IF EXISTS "Allow upload fotos_usuarios for authenticated users" ON storage.objects;
DROP POLICY IF EXISTS "Allow select fotos_usuarios for authenticated users" ON storage.objects;
DROP POLICY IF EXISTS "Allow update fotos_usuarios for authenticated users" ON storage.objects;
DROP POLICY IF EXISTS "Allow delete fotos_usuarios for authenticated users" ON storage.objects;

-- ============================================
-- 4. CRIAR POLÍTICAS PARA O BUCKET FOTOS_USUARIOS
-- ============================================

-- 1. Política para permitir INSERT (upload) de fotos para usuários autenticados
CREATE POLICY "Allow upload fotos_usuarios for authenticated users" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'fotos_usuarios' 
  AND auth.uid() IS NOT NULL
);

-- 2. Política para permitir SELECT (download/visualização) de fotos para usuários autenticados
CREATE POLICY "Allow select fotos_usuarios for authenticated users" ON storage.objects
FOR SELECT TO authenticated
USING (
  bucket_id = 'fotos_usuarios'
  AND auth.uid() IS NOT NULL
);

-- 3. Política para permitir UPDATE (atualização) de fotos para usuários autenticados
CREATE POLICY "Allow update fotos_usuarios for authenticated users" ON storage.objects
FOR UPDATE TO authenticated
USING (
  bucket_id = 'fotos_usuarios'
  AND auth.uid() IS NOT NULL
)
WITH CHECK (
  bucket_id = 'fotos_usuarios'
  AND auth.uid() IS NOT NULL
);

-- 4. Política para permitir DELETE (exclusão) de fotos para usuários autenticados
CREATE POLICY "Allow delete fotos_usuarios for authenticated users" ON storage.objects
FOR DELETE TO authenticated
USING (
  bucket_id = 'fotos_usuarios'
  AND auth.uid() IS NOT NULL
);

-- ============================================
-- 5. VERIFICAR SE AS POLÍTICAS FORAM CRIADAS
-- ============================================

SELECT 'Políticas criadas para fotos_usuarios:' as status;
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
AND policyname LIKE '%fotos_usuarios%'
ORDER BY policyname;

-- ============================================
-- 6. VERIFICAR BUCKET FINAL
-- ============================================

SELECT 'Bucket fotos_usuarios configurado:' as status;
SELECT 
  name as nome_bucket,
  public as publico,
  file_size_limit as limite_tamanho,
  allowed_mime_types as tipos_permitidos
FROM storage.buckets 
WHERE name = 'fotos_usuarios';

-- ============================================
-- 7. TESTE DE PERMISSÕES
-- ============================================

SELECT 'Testando permissões do usuário atual:' as status;
SELECT 
  auth.uid() as usuario_atual,
  has_table_privilege('storage.objects', 'SELECT') as pode_select,
  has_table_privilege('storage.objects', 'INSERT') as pode_insert,
  has_table_privilege('storage.objects', 'UPDATE') as pode_update,
  has_table_privilege('storage.objects', 'DELETE') as pode_delete;
