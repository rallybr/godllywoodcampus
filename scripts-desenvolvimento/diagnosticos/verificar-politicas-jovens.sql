-- Script para VERIFICAR políticas RLS da tabela jovens
-- Execute este script no Supabase SQL Editor

-- ============================================
-- 1. VERIFICAR SE A TABELA EXISTE
-- ============================================

SELECT 'Tabela jovens existe:' as status, 
       EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'jovens') as existe;

-- ============================================
-- 2. VERIFICAR SE RLS ESTÁ HABILITADO
-- ============================================

SELECT 'RLS habilitado:' as status, rowsecurity 
FROM pg_tables 
WHERE tablename = 'jovens';

-- ============================================
-- 3. VERIFICAR POLÍTICAS EXISTENTES
-- ============================================

SELECT 
  policyname as nome_politica,
  cmd as comando,
  permissive as permissiva,
  roles as roles_aplicadas,
  qual as condicao_using,
  with_check as condicao_check
FROM pg_policies 
WHERE tablename = 'jovens'
ORDER BY policyname;

-- ============================================
-- 4. VERIFICAR SE A FUNÇÃO can_access_jovem EXISTE
-- ============================================

SELECT 'Função can_access_jovem existe:' as status,
       EXISTS (
         SELECT 1 FROM pg_proc p
         JOIN pg_namespace n ON p.pronamespace = n.oid
         WHERE n.nspname = 'public' AND p.proname = 'can_access_jovem'
       ) as existe;

-- ============================================
-- 5. VERIFICAR USUÁRIO ATUAL E SUAS ROLES
-- ============================================

-- Verificar usuário atual
SELECT 
  u.id as usuario_id,
  u.nome,
  u.email,
  auth.uid() as auth_uid
FROM public.usuarios u
WHERE u.id_auth = auth.uid();

-- Verificar roles do usuário atual
SELECT 
  ur.id as user_role_id,
  r.slug as role_slug,
  r.nome as role_nome,
  ur.ativo,
  ur.estado_id,
  ur.bloco_id,
  ur.regiao_id,
  ur.igreja_id
FROM public.user_roles ur
JOIN public.roles r ON r.id = ur.role_id
WHERE ur.user_id = (SELECT id FROM public.usuarios WHERE id_auth = auth.uid())
ORDER BY r.nivel_hierarquico DESC;

-- ============================================
-- 6. CONTAR TOTAL DE POLÍTICAS
-- ============================================

SELECT 'Total de políticas na tabela jovens:' as status, COUNT(*) as total
FROM pg_policies 
WHERE tablename = 'jovens';