-- Script de diagnóstico completo para o bucket 'viagens'
-- Execute este script no Supabase SQL Editor

-- ============================================
-- 1. VERIFICAR SE O BUCKET EXISTE
-- ============================================

SELECT '1. Verificando bucket viagens...' as etapa;
SELECT 
  name as bucket_name,
  id as bucket_id,
  public as is_public,
  created_at,
  updated_at
FROM storage.buckets 
WHERE name = 'viagens';

-- ============================================
-- 2. LISTAR TODOS OS BUCKETS
-- ============================================

SELECT '2. Listando todos os buckets...' as etapa;
SELECT name, id, public, created_at
FROM storage.buckets
ORDER BY name;

-- ============================================
-- 3. VERIFICAR POLÍTICAS DE STORAGE
-- ============================================

SELECT '3. Verificando políticas de storage...' as etapa;
SELECT 
  policyname,
  cmd,
  permissive,
  roles,
  qual,
  with_check
FROM pg_policies 
WHERE schemaname = 'storage' 
  AND tablename = 'objects'
ORDER BY policyname;

-- ============================================
-- 4. VERIFICAR USUÁRIO ATUAL
-- ============================================

SELECT '4. Verificando usuário atual...' as etapa;
SELECT 
  auth.uid() as auth_id,
  auth.role() as auth_role;

-- ============================================
-- 5. VERIFICAR USUÁRIO NA TABELA USUARIOS
-- ============================================

SELECT '5. Verificando usuário na tabela usuarios...' as etapa;
SELECT 
  id,
  nome,
  email,
  ativo
FROM public.usuarios 
WHERE id_auth = auth.uid();

-- ============================================
-- 6. VERIFICAR ROLES DO USUÁRIO
-- ============================================

SELECT '6. Verificando roles do usuário...' as etapa;
SELECT 
  r.slug,
  r.nome,
  r.descricao,
  ur.ativo,
  ur.estado_id,
  ur.bloco_id,
  ur.regiao_id,
  ur.igreja_id
FROM public.user_roles ur
JOIN public.roles r ON r.id = ur.role_id
JOIN public.usuarios u ON u.id = ur.user_id
WHERE u.id_auth = auth.uid()
ORDER BY r.nivel_hierarquico;

-- ============================================
-- 7. VERIFICAR PERMISSÕES DE STORAGE
-- ============================================

SELECT '7. Verificando permissões de storage...' as etapa;
SELECT 
  has_schema_privilege('storage', 'USAGE') as pode_usar_storage,
  has_table_privilege('storage.objects', 'SELECT') as pode_select,
  has_table_privilege('storage.objects', 'INSERT') as pode_insert,
  has_table_privilege('storage.objects', 'UPDATE') as pode_update,
  has_table_privilege('storage.objects', 'DELETE') as pode_delete;

-- ============================================
-- 8. VERIFICAR ESTRUTURA DA TABELA STORAGE.OBJECTS
-- ============================================

SELECT '8. Verificando estrutura da tabela storage.objects...' as etapa;
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_schema = 'storage' 
  AND table_name = 'objects'
ORDER BY ordinal_position;

-- ============================================
-- 9. TESTE DE ACESSO AO BUCKET
-- ============================================

SELECT '9. Testando acesso ao bucket...' as etapa;
-- Tentar contar arquivos no bucket (isso vai falhar se não tiver permissão)
SELECT COUNT(*) as total_arquivos
FROM storage.objects 
WHERE bucket_id = 'viagens';

-- ============================================
-- 10. VERIFICAR CONFIGURAÇÕES DO SUPABASE
-- ============================================

SELECT '10. Verificando configurações...' as etapa;
SELECT 
  current_database() as database_name,
  current_user as current_user,
  session_user as session_user,
  current_setting('search_path') as search_path;

SELECT 'Diagnóstico completo finalizado!' as resultado;
