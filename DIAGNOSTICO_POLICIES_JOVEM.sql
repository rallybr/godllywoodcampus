-- 🔍 DIAGNÓSTICO COMPLETO DAS POLICIES DA TABELA JOVENS
-- Execute este script no Supabase SQL Editor para identificar o problema

-- ============================================
-- 1. VERIFICAR POLICIES ATUAIS DA TABELA JOVENS
-- ============================================

SELECT 
  'POLICIES ATUAIS DA TABELA JOVENS:' as status,
  policyname as nome_politica,
  cmd as comando,
  permissive as permissiva,
  roles as roles_aplicadas,
  CASE 
    WHEN qual IS NULL THEN 'Sem condição USING'
    ELSE 'Com condição USING'
  END as tem_condicao_using,
  CASE 
    WHEN with_check IS NULL THEN 'Sem condição CHECK'
    ELSE 'Com condição CHECK'
  END as tem_condicao_check
FROM pg_policies 
WHERE tablename = 'jovens'
ORDER BY policyname;

-- ============================================
-- 2. VERIFICAR SE A FUNÇÃO can_access_jovem EXISTE
-- ============================================

SELECT 
  'FUNÇÃO can_access_jovem EXISTE:' as status,
  EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' AND p.proname = 'can_access_jovem'
  ) as existe;

-- ============================================
-- 3. VERIFICAR RLS HABILITADO
-- ============================================

SELECT 
  'RLS HABILITADO NA TABELA JOVENS:' as status,
  rowsecurity as rls_ativo
FROM pg_tables 
WHERE tablename = 'jovens';

-- ============================================
-- 4. VERIFICAR USUÁRIOS COM NÍVEL JOVEM
-- ============================================

SELECT 
  'USUÁRIOS COM NÍVEL JOVEM:' as status,
  u.id,
  u.nome,
  u.nivel,
  u.estado_id,
  u.bloco_id,
  u.regiao_id,
  u.igreja_id
FROM public.usuarios u
WHERE u.nivel = 'jovem'
ORDER BY u.nome;

-- ============================================
-- 5. VERIFICAR JOVENS CADASTRADOS
-- ============================================

SELECT 
  'JOVENS CADASTRADOS:' as status,
  COUNT(*) as total_jovens,
  COUNT(DISTINCT usuario_id) as usuarios_diferentes
FROM public.jovens;

-- ============================================
-- 6. TESTAR ACESSO DE UM USUÁRIO JOVEM
-- ============================================

-- Substitua 'USER_ID_AQUI' pelo ID de um usuário jovem
-- SELECT 
--   'TESTE DE ACESSO PARA USUÁRIO JOVEM:' as status,
--   can_access_jovem(
--     (SELECT estado_id FROM public.jovens WHERE usuario_id = 'USER_ID_AQUI' LIMIT 1),
--     (SELECT bloco_id FROM public.jovens WHERE usuario_id = 'USER_ID_AQUI' LIMIT 1),
--     (SELECT regiao_id FROM public.jovens WHERE usuario_id = 'USER_ID_AQUI' LIMIT 1),
--     (SELECT igreja_id FROM public.jovens WHERE usuario_id = 'USER_ID_AQUI' LIMIT 1)
--   ) as pode_acessar;

-- ============================================
-- 7. VERIFICAR POLICIES PROBLEMÁTICAS
-- ============================================

-- Verificar se há policies que permitem acesso total
SELECT 
  'POLICIES QUE PERMITEM ACESSO TOTAL:' as status,
  policyname as nome_politica,
  cmd as comando,
  qual as condicao_using,
  with_check as condicao_check
FROM pg_policies 
WHERE tablename = 'jovens'
  AND (
    qual IS NULL 
    OR qual = 'true'
    OR with_check IS NULL
    OR with_check = 'true'
  )
ORDER BY policyname;
