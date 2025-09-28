-- Script básico para configurar o bucket 'viagens'
-- Execute este script no Supabase SQL Editor

-- ============================================
-- 1. VERIFICAR BUCKET
-- ============================================

SELECT 'Verificando bucket viagens...' as status;
SELECT * FROM storage.buckets WHERE name = 'viagens';

-- ============================================
-- 2. REMOVER TODAS AS POLÍTICAS EXISTENTES
-- ============================================

-- Listar políticas existentes primeiro
SELECT 'Políticas existentes:' as status;
SELECT policyname FROM pg_policies 
WHERE schemaname = 'storage' AND tablename = 'objects';

-- Remover todas as políticas
DO $$
DECLARE
    policy_name text;
BEGIN
    FOR policy_name IN 
        SELECT policyname FROM pg_policies 
        WHERE schemaname = 'storage' AND tablename = 'objects'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON storage.objects', policy_name);
    END LOOP;
END $$;

-- ============================================
-- 3. CRIAR POLÍTICAS BÁSICAS
-- ============================================

-- Política para permitir tudo para usuários autenticados
CREATE POLICY "Allow all for authenticated users" ON storage.objects
FOR ALL TO authenticated
USING (bucket_id = 'viagens')
WITH CHECK (bucket_id = 'viagens');

-- ============================================
-- 4. VERIFICAR POLÍTICAS CRIADAS
-- ============================================

SELECT 'Políticas criadas:' as status;
SELECT policyname, cmd, permissive, roles
FROM pg_policies 
WHERE schemaname = 'storage' AND tablename = 'objects'
ORDER BY policyname;

-- ============================================
-- 5. TESTE DE PERMISSÕES
-- ============================================

SELECT 'Testando permissões...' as status;
SELECT 
  has_table_privilege('storage.objects', 'SELECT') as pode_select,
  has_table_privilege('storage.objects', 'INSERT') as pode_insert,
  has_table_privilege('storage.objects', 'DELETE') as pode_delete;

SELECT 'Configuração básica concluída!' as resultado;
