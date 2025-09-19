-- Script simplificado para verificar o bucket 'viagens'
-- Execute este script no Supabase SQL Editor

-- ============================================
-- 1. VERIFICAR SE O BUCKET EXISTE
-- ============================================

SELECT 'Verificando bucket viagens...' as status;
SELECT * FROM storage.buckets WHERE name = 'viagens';

-- ============================================
-- 2. VERIFICAR POLÍTICAS EXISTENTES
-- ============================================

SELECT 'Políticas de storage existentes:' as verificacao;
SELECT policyname, cmd, permissive, roles
FROM pg_policies 
WHERE schemaname = 'storage' 
  AND tablename = 'objects'
ORDER BY policyname;

-- ============================================
-- 3. VERIFICAR PERMISSÕES DO USUÁRIO
-- ============================================

SELECT 'Permissões do usuário atual:' as verificacao;
SELECT 
  has_schema_privilege('storage', 'USAGE') as pode_usar_storage,
  has_table_privilege('storage.objects', 'SELECT') as pode_select,
  has_table_privilege('storage.objects', 'INSERT') as pode_insert,
  has_table_privilege('storage.objects', 'DELETE') as pode_delete;

-- ============================================
-- 4. VERIFICAR USUÁRIO ATUAL
-- ============================================

SELECT 'Usuário atual:' as verificacao;
SELECT 
  auth.uid() as auth_id,
  (SELECT id FROM public.usuarios WHERE id_auth = auth.uid()) as usuario_id;

-- ============================================
-- 5. VERIFICAR ROLES DO USUÁRIO
-- ============================================

SELECT 'Roles do usuário atual:' as verificacao;
SELECT r.slug, r.nome, ur.ativo
FROM public.user_roles ur
JOIN public.roles r ON r.id = ur.role_id
JOIN public.usuarios u ON u.id = ur.user_id
WHERE u.id_auth = auth.uid()
ORDER BY r.nivel_hierarquico;

SELECT 'Verificação concluída!' as status;
