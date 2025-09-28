-- =====================================================
-- DIAGNÓSTICO DETALHADO DO PROBLEMA
-- =====================================================
-- Este script vai mostrar exatamente o que está acontecendo

-- 1. VERIFICAR USUÁRIO ATUAL COMPLETO
SELECT 
  'USUÁRIO ATUAL COMPLETO' as diagnostico,
  u.id,
  u.id_auth,
  u.nome,
  u.email,
  u.nivel,
  u.estado_id,
  u.bloco_id,
  u.regiao_id,
  u.igreja_id,
  u.ativo
FROM public.usuarios u
WHERE u.id_auth = auth.uid();

-- 2. VERIFICAR SE O USUÁRIO É LÍDER NACIONAL
SELECT 
  'VERIFICAÇÃO LÍDER NACIONAL' as diagnostico,
  u.nivel,
  CASE 
    WHEN u.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju') THEN '✅ USUÁRIO É LÍDER NACIONAL'
    ELSE '❌ USUÁRIO NÃO É LÍDER NACIONAL'
  END as resultado
FROM public.usuarios u
WHERE u.id_auth = auth.uid();

-- 3. TESTAR FUNCTION can_access_jovem COM DEBUG DETALHADO
SELECT 
  'TESTE can_access_jovem COM DEBUG' as diagnostico,
  can_access_jovem(NULL, NULL, NULL, NULL) as resultado;

-- 4. TESTAR FUNCTION can_access_viagem_by_level COM DEBUG DETALHADO
SELECT 
  'TESTE can_access_viagem_by_level COM DEBUG' as diagnostico,
  can_access_viagem_by_level(NULL, NULL, NULL, NULL) as resultado;

-- 5. VERIFICAR SE AS FUNCTIONS ESTÃO USANDO A ESTRUTURA CORRETA
SELECT 
  'VERIFICAÇÃO DE FUNCTIONS' as diagnostico,
  proname as function_name,
  CASE 
    WHEN prosrc LIKE '%user_info.nivel%' THEN '✅ Function usa campo nivel'
    WHEN prosrc LIKE '%user_roles_info.nivel_hierarquico%' THEN '❌ Function usa estrutura antiga'
    ELSE '❓ Function com estrutura desconhecida'
  END as status_estrutura
FROM pg_proc 
WHERE proname IN ('can_access_jovem', 'can_access_viagem_by_level')
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- 6. VERIFICAR SE O USUÁRIO ESTÁ AUTENTICADO
SELECT 
  'VERIFICAÇÃO DE AUTENTICAÇÃO' as diagnostico,
  auth.uid() as user_id_auth,
  CASE 
    WHEN auth.uid() IS NOT NULL THEN '✅ USUÁRIO AUTENTICADO'
    ELSE '❌ USUÁRIO NÃO AUTENTICADO'
  END as resultado;

-- 7. VERIFICAR SE O USUÁRIO EXISTE NA TABELA usuarios
SELECT 
  'VERIFICAÇÃO DE USUÁRIO NA TABELA' as diagnostico,
  CASE 
    WHEN EXISTS (SELECT 1 FROM public.usuarios WHERE id_auth = auth.uid()) THEN '✅ USUÁRIO EXISTE NA TABELA'
    ELSE '❌ USUÁRIO NÃO EXISTE NA TABELA'
  END as resultado;

-- 8. VERIFICAR SE O USUÁRIO TEM NÍVEL VÁLIDO
SELECT 
  'VERIFICAÇÃO DE NÍVEL VÁLIDO' as diagnostico,
  u.nivel,
  CASE 
    WHEN u.nivel IS NOT NULL AND u.nivel != '' THEN '✅ USUÁRIO TEM NÍVEL VÁLIDO'
    ELSE '❌ USUÁRIO NÃO TEM NÍVEL VÁLIDO'
  END as resultado
FROM public.usuarios u
WHERE u.id_auth = auth.uid();

-- 9. VERIFICAR SE O USUÁRIO ESTÁ ATIVO
SELECT 
  'VERIFICAÇÃO DE USUÁRIO ATIVO' as diagnostico,
  u.ativo,
  CASE 
    WHEN u.ativo = true THEN '✅ USUÁRIO ESTÁ ATIVO'
    ELSE '❌ USUÁRIO NÃO ESTÁ ATIVO'
  END as resultado
FROM public.usuarios u
WHERE u.id_auth = auth.uid();

-- 10. TESTAR FUNCTION can_access_jovem COM DADOS ESPECÍFICOS
SELECT 
  'TESTE can_access_jovem COM DADOS ESPECÍFICOS' as diagnostico,
  can_access_jovem('0f922947-675b-5f2b-8dfc-bcc180ccb86d', NULL, NULL, NULL) as resultado;

-- 11. TESTAR FUNCTION can_access_viagem_by_level COM DADOS ESPECÍFICOS
SELECT 
  'TESTE can_access_viagem_by_level COM DADOS ESPECÍFICOS' as diagnostico,
  can_access_viagem_by_level('0f922947-675b-5f2b-8dfc-bcc180ccb86d', NULL, NULL, NULL) as resultado;

-- 12. VERIFICAR SE O USUÁRIO É ADMINISTRADOR
SELECT 
  'VERIFICAÇÃO ADMINISTRADOR' as diagnostico,
  u.nivel,
  CASE 
    WHEN u.nivel = 'administrador' THEN '✅ USUÁRIO É ADMINISTRADOR'
    ELSE '❌ USUÁRIO NÃO É ADMINISTRADOR'
  END as resultado
FROM public.usuarios u
WHERE u.id_auth = auth.uid();

-- =====================================================
-- FIM DO DIAGNÓSTICO DETALHADO
-- =====================================================
