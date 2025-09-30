-- =====================================================
-- DIAGNÓSTICO COMPLETO DO PROBLEMA DO USUÁRIO JOVEM
-- =====================================================
-- Objetivo: Identificar por que usuário jovem aparece como "Desconhecido" 
-- e vê dados de administrador

-- ============================================
-- 1. VERIFICAR AUTENTICAÇÃO ATUAL
-- ============================================

SELECT '=== VERIFICAÇÃO DE AUTENTICAÇÃO ===' as secao;

-- Verificar se há usuário autenticado
SELECT 
  'Usuário autenticado:' as status,
  auth.uid() as user_id_auth,
  CASE 
    WHEN auth.uid() IS NULL THEN '❌ NENHUM USUÁRIO AUTENTICADO'
    ELSE '✅ Usuário autenticado: ' || auth.uid()::text
  END as resultado;

-- ============================================
-- 2. VERIFICAR DADOS DO USUÁRIO NA TABELA USUARIOS
-- ============================================

SELECT '=== DADOS DO USUÁRIO ===' as secao;

-- Buscar dados do usuário atual
SELECT 
  'Dados do usuário:' as status,
  u.id,
  u.nome,
  u.email,
  u.nivel,
  u.ativo,
  u.id_auth,
  u.criado_em
FROM public.usuarios u
WHERE u.id_auth = auth.uid();

-- ============================================
-- 3. VERIFICAR ROLES DO USUÁRIO
-- ============================================

SELECT '=== ROLES DO USUÁRIO ===' as secao;

-- Verificar roles atribuídos ao usuário
SELECT 
  'Roles do usuário:' as status,
  ur.id as user_role_id,
  ur.ativo as role_ativo,
  r.slug as role_slug,
  r.nome as role_nome,
  r.nivel_hierarquico,
  ur.estado_id,
  ur.bloco_id,
  ur.regiao_id,
  ur.igreja_id
FROM public.user_roles ur
JOIN public.roles r ON r.id = ur.role_id
JOIN public.usuarios u ON u.id = ur.user_id
WHERE u.id_auth = auth.uid();

-- ============================================
-- 4. TESTAR FUNÇÃO has_role
-- ============================================

SELECT '=== TESTE DA FUNÇÃO has_role ===' as secao;

-- Testar função has_role para diferentes roles
SELECT 
  'Teste has_role:' as status,
  has_role('administrador') as is_admin,
  has_role('jovem') as is_jovem,
  has_role('colaborador') as is_colaborador,
  has_role('lider_nacional_iurd') as is_lider_nacional;

-- ============================================
-- 5. VERIFICAR POLICIES RLS
-- ============================================

SELECT '=== VERIFICAÇÃO DE POLICIES RLS ===' as secao;

-- Verificar se RLS está habilitado
SELECT 
  'RLS habilitado:' as status,
  relname as tabela,
  relrowsecurity as rls_habilitado
FROM pg_class 
WHERE relname IN ('usuarios', 'jovens', 'dados_viagem', 'avaliacoes')
ORDER BY relname;

-- Listar policies da tabela jovens
SELECT 
  'Policies da tabela jovens:' as status,
  polname as nome_politica,
  CASE polcmd
    WHEN 'r' THEN 'SELECT'
    WHEN 'a' THEN 'INSERT'
    WHEN 'w' THEN 'UPDATE'
    WHEN 'd' THEN 'DELETE'
    WHEN '*' THEN 'ALL'
  END as comando,
  pg_get_expr(polqual, polrelid) as condicao_using,
  pg_get_expr(polwithcheck, polrelid) as condicao_check
FROM pg_policy
WHERE polrelid = (SELECT oid FROM pg_class WHERE relname = 'jovens')
ORDER BY polname;

-- ============================================
-- 6. TESTAR ACESSO A DADOS
-- ============================================

SELECT '=== TESTE DE ACESSO A DADOS ===' as secao;

-- Testar acesso à tabela jovens
SELECT 
  'Acesso à tabela jovens:' as status,
  COUNT(*) as total_jovens_visiveis
FROM public.jovens;

-- Testar acesso à tabela usuarios
SELECT 
  'Acesso à tabela usuarios:' as status,
  COUNT(*) as total_usuarios_visiveis
FROM public.usuarios;

-- ============================================
-- 7. VERIFICAR FUNÇÃO can_access_jovem
-- ============================================

SELECT '=== TESTE DA FUNÇÃO can_access_jovem ===' as secao;

-- Testar função can_access_jovem com dados de exemplo
SELECT 
  'Teste can_access_jovem:' as status,
  j.id as jovem_id,
  j.nome_completo,
  j.estado_id,
  j.bloco_id,
  j.regiao_id,
  j.igreja_id,
  can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id) as tem_acesso
FROM public.jovens j
LIMIT 5;

-- ============================================
-- 8. VERIFICAR TRIGGER DE ATRIBUIÇÃO DE PAPEL
-- ============================================

SELECT '=== VERIFICAÇÃO DE TRIGGER ===' as secao;

-- Verificar se existe trigger para atribuir papel padrão
SELECT 
  'Triggers na tabela usuarios:' as status,
  tgname as trigger_name,
  tgtype as trigger_type,
  tgenabled as enabled
FROM pg_trigger
WHERE tgrelid = (SELECT oid FROM pg_class WHERE relname = 'usuarios')
AND tgname LIKE '%papel%';

-- ============================================
-- 9. RESUMO DO DIAGNÓSTICO
-- ============================================

SELECT '=== RESUMO DO DIAGNÓSTICO ===' as secao;

-- Resumo das informações
SELECT 
  'Resumo:' as status,
  CASE 
    WHEN auth.uid() IS NULL THEN '❌ PROBLEMA: Usuário não autenticado'
    WHEN NOT EXISTS (SELECT 1 FROM public.usuarios WHERE id_auth = auth.uid()) THEN '❌ PROBLEMA: Usuário não encontrado na tabela usuarios'
    WHEN NOT EXISTS (SELECT 1 FROM public.user_roles ur JOIN public.roles r ON r.id = ur.role_id JOIN public.usuarios u ON u.id = ur.user_id WHERE u.id_auth = auth.uid()) THEN '❌ PROBLEMA: Usuário não tem roles atribuídos'
    WHEN NOT has_role('jovem') AND NOT has_role('administrador') THEN '❌ PROBLEMA: Usuário não tem role jovem nem administrador'
    ELSE '✅ DIAGNÓSTICO: Sistema funcionando normalmente'
  END as resultado;
