-- Script para verificar e corrigir a função can_access_jovem
-- Execute este script no Supabase SQL Editor

-- ============================================
-- 1. VERIFICAR FUNÇÃO ATUAL
-- ============================================

-- Ver se a função existe e seu código
SELECT 
  p.proname as nome_funcao,
  pg_get_function_result(p.oid) as tipo_retorno,
  pg_get_function_arguments(p.oid) as argumentos,
  p.prosrc as codigo_fonte
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' AND p.proname = 'can_access_jovem';

-- ============================================
-- 2. VERIFICAR USUÁRIO ATUAL E SUAS ROLES
-- ============================================

-- Verificar usuário atual
SELECT 
  u.id as usuario_id,
  u.nome,
  u.email,
  u.ativo as usuario_ativo,
  auth.uid() as auth_uid
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
-- 3. TESTAR A FUNÇÃO COM DADOS REAIS
-- ============================================

-- Pegar um jovem para testar
SELECT 
  id,
  nome_completo,
  estado_id,
  bloco_id,
  regiao_id,
  igreja_id
FROM public.jovens
LIMIT 1;

-- Testar a função com os dados do jovem (substitua os UUIDs pelos valores reais acima)
-- SELECT can_access_jovem(
--   'uuid_estado_aqui',
--   'uuid_bloco_aqui', 
--   'uuid_regiao_aqui',
--   'uuid_igreja_aqui'
-- ) as resultado_teste;

-- ============================================
-- 4. VERIFICAR POLÍTICAS DE UPDATE
-- ============================================

-- Ver políticas de UPDATE
SELECT 
  policyname as nome_politica,
  cmd as comando,
  permissive as permissiva,
  roles as roles_aplicadas,
  qual as condicao_using,
  with_check as condicao_check
FROM pg_policies 
WHERE tablename = 'jovens' 
  AND cmd = 'UPDATE'
ORDER BY policyname;

-- ============================================
-- 5. TESTAR UPDATE MANUAL
-- ============================================

-- Tentar fazer um UPDATE manual para testar as políticas
-- (substitua o ID pelo ID real de um jovem)
-- UPDATE public.jovens 
-- SET aprovado = 'pre_aprovado'
-- WHERE id = 'uuid_do_jovem_aqui'
-- RETURNING id, nome_completo, aprovado;
