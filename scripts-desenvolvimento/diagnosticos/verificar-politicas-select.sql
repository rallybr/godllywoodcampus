-- Script para verificar e corrigir as políticas de SELECT
-- Execute este script no Supabase SQL Editor

-- ============================================
-- 1. VERIFICAR POLÍTICAS DE SELECT ATUAIS
-- ============================================

-- Ver todas as políticas de SELECT
SELECT 
  policyname as nome_politica,
  cmd as comando,
  permissive as permissiva,
  roles as roles_aplicadas,
  qual as condicao_using,
  with_check as condicao_check
FROM pg_policies 
WHERE tablename = 'jovens' 
  AND cmd = 'SELECT'
ORDER BY policyname;

-- ============================================
-- 2. VERIFICAR SE A FUNÇÃO can_access_jovem FUNCIONA
-- ============================================

-- Testar a função com um jovem específico (substitua os UUIDs pelos reais)
-- SELECT can_access_jovem(
--   'uuid_estado_aqui',
--   'uuid_bloco_aqui', 
--   'uuid_regiao_aqui',
--   'uuid_igreja_aqui'
-- ) as resultado_teste;

-- ============================================
-- 3. VERIFICAR USUÁRIO ATUAL E SUAS ROLES
-- ============================================

-- Verificar usuário atual
SELECT 
  u.id as usuario_id,
  u.nome,
  u.email,
  u.ativo as usuario_ativo
FROM public.usuarios u
WHERE u.id_auth = auth.uid();

-- Verificar roles do usuário atual
SELECT 
  ur.id as user_role_id,
  r.slug as role_slug,
  r.nome as role_nome,
  r.nivel_hierarquico,
  ur.ativo as role_ativa,
  ur.estado_id,
  ur.bloco_id,
  ur.regiao_id,
  ur.igreja_id
FROM public.user_roles ur
JOIN public.roles r ON r.id = ur.role_id
WHERE ur.user_id = (SELECT id FROM public.usuarios WHERE id_auth = auth.uid())
ORDER BY r.nivel_hierarquico DESC;

-- ============================================
-- 4. TESTAR ACESSO AOS DADOS
-- ============================================

-- Tentar selecionar jovens (deve mostrar se as políticas estão funcionando)
SELECT 
  COUNT(*) as total_jovens_visiveis
FROM public.jovens;

-- Ver alguns jovens (se a política permitir)
SELECT 
  id,
  nome_completo,
  aprovado,
  estado_id,
  bloco_id,
  regiao_id,
  igreja_id
FROM public.jovens
LIMIT 5;
