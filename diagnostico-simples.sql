-- =====================================================
-- DIAGNÓSTICO SIMPLES PARA IDENTIFICAR PROBLEMA
-- =====================================================
-- Este script vai diagnosticar por que os líderes nacionais não têm acesso total

-- 1. VERIFICAR USUÁRIO ATUAL E SEUS PAPÉIS
SELECT 
  'USUÁRIO ATUAL' as diagnostico,
  auth.uid() as user_id_auth,
  u.id as user_id,
  u.nome,
  u.email
FROM public.usuarios u
WHERE u.id_auth = auth.uid();

-- 2. VERIFICAR PAPÉIS DO USUÁRIO ATUAL
SELECT 
  'PAPÉIS DO USUÁRIO ATUAL' as diagnostico,
  r.slug,
  r.nome,
  r.nivel_hierarquico,
  ur.ativo,
  ur.estado_id,
  ur.bloco_id,
  ur.regiao_id,
  ur.igreja_id
FROM public.user_roles ur
JOIN public.roles r ON r.id = ur.role_id
JOIN public.usuarios u ON u.id = ur.user_id
WHERE u.id_auth = auth.uid()
ORDER BY r.nivel_hierarquico ASC;

-- 3. VERIFICAR SE O USUÁRIO TEM PAPEL DE LÍDER NACIONAL
SELECT 
  'VERIFICAÇÃO LÍDER NACIONAL' as diagnostico,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM public.user_roles ur
      JOIN public.roles r ON r.id = ur.role_id
      JOIN public.usuarios u ON u.id = ur.user_id
      WHERE u.id_auth = auth.uid()
        AND r.slug IN ('lider_nacional_iurd', 'lider_nacional_fju')
        AND ur.ativo = true
    ) THEN '✅ USUÁRIO É LÍDER NACIONAL'
    ELSE '❌ USUÁRIO NÃO É LÍDER NACIONAL'
  END as resultado;

-- 4. VERIFICAR NÍVEL HIERÁRQUICO MÍNIMO DO USUÁRIO
SELECT 
  'NÍVEL HIERÁRQUICO MÍNIMO' as diagnostico,
  MIN(r.nivel_hierarquico) as nivel_minimo,
  CASE 
    WHEN MIN(r.nivel_hierarquico) = 1 THEN 'Administrador'
    WHEN MIN(r.nivel_hierarquico) = 2 THEN 'Líder Nacional'
    WHEN MIN(r.nivel_hierarquico) = 3 THEN 'Líder Estadual'
    WHEN MIN(r.nivel_hierarquico) = 4 THEN 'Líder de Bloco'
    WHEN MIN(r.nivel_hierarquico) = 5 THEN 'Líder Regional'
    WHEN MIN(r.nivel_hierarquico) = 6 THEN 'Líder de Igreja'
    WHEN MIN(r.nivel_hierarquico) = 7 THEN 'Colaborador'
    WHEN MIN(r.nivel_hierarquico) = 8 THEN 'Jovem'
    ELSE 'Nível não definido'
  END as descricao_nivel
FROM public.user_roles ur
JOIN public.roles r ON r.id = ur.role_id
JOIN public.usuarios u ON u.id = ur.user_id
WHERE u.id_auth = auth.uid()
  AND ur.ativo = true;

-- 5. VERIFICAR SE O USUÁRIO ESTÁ AUTENTICADO
SELECT 
  'VERIFICAÇÃO DE AUTENTICAÇÃO' as diagnostico,
  CASE 
    WHEN auth.uid() IS NOT NULL THEN '✅ USUÁRIO AUTENTICADO'
    ELSE '❌ USUÁRIO NÃO AUTENTICADO'
  END as resultado,
  auth.uid() as user_id_auth;

-- 6. VERIFICAR SE O USUÁRIO EXISTE NA TABELA usuarios
SELECT 
  'VERIFICAÇÃO DE USUÁRIO NA TABELA' as diagnostico,
  CASE 
    WHEN EXISTS (SELECT 1 FROM public.usuarios WHERE id_auth = auth.uid()) THEN '✅ USUÁRIO EXISTE NA TABELA'
    ELSE '❌ USUÁRIO NÃO EXISTE NA TABELA'
  END as resultado;

-- 7. VERIFICAR SE O USUÁRIO TEM PAPÉIS ATIVOS
SELECT 
  'VERIFICAÇÃO DE PAPÉIS ATIVOS' as diagnostico,
  COUNT(*) as total_papeis,
  COUNT(CASE WHEN ur.ativo = true THEN 1 END) as papeis_ativos,
  COUNT(CASE WHEN ur.ativo = false THEN 1 END) as papeis_inativos
FROM public.user_roles ur
JOIN public.usuarios u ON u.id = ur.user_id
WHERE u.id_auth = auth.uid();

-- 8. VERIFICAR SE O USUÁRIO TEM PAPÉIS COM NÍVEL HIERÁRQUICO
SELECT 
  'VERIFICAÇÃO DE NÍVEIS HIERÁRQUICOS' as diagnostico,
  COUNT(*) as total_papeis,
  COUNT(CASE WHEN r.nivel_hierarquico IS NOT NULL THEN 1 END) as papeis_com_nivel,
  COUNT(CASE WHEN r.nivel_hierarquico IS NULL THEN 1 END) as papeis_sem_nivel
FROM public.user_roles ur
JOIN public.roles r ON r.id = ur.role_id
JOIN public.usuarios u ON u.id = ur.user_id
WHERE u.id_auth = auth.uid()
  AND ur.ativo = true;

-- 9. VERIFICAR SE O USUÁRIO TEM PAPÉIS COM NÍVEL HIERÁRQUICO VÁLIDO
SELECT 
  'VERIFICAÇÃO DE NÍVEIS HIERÁRQUICOS VÁLIDOS' as diagnostico,
  COUNT(*) as total_papeis,
  COUNT(CASE WHEN r.nivel_hierarquico BETWEEN 1 AND 8 THEN 1 END) as papeis_com_nivel_valido,
  COUNT(CASE WHEN r.nivel_hierarquico NOT BETWEEN 1 AND 8 THEN 1 END) as papeis_com_nivel_invalido
FROM public.user_roles ur
JOIN public.roles r ON r.id = ur.role_id
JOIN public.usuarios u ON u.id = ur.user_id
WHERE u.id_auth = auth.uid()
  AND ur.ativo = true;

-- 10. VERIFICAR SE AS FUNCTIONS EXISTEM
SELECT 
  'VERIFICAÇÃO DE FUNCTIONS' as diagnostico,
  proname as function_name,
  CASE 
    WHEN prosrc LIKE '%RAISE NOTICE%' THEN '✅ Function com debug'
    ELSE '❌ Function sem debug'
  END as debug_status
FROM pg_proc 
WHERE proname IN ('can_access_jovem', 'can_access_viagem_by_level')
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- 11. TESTAR FUNCTION can_access_jovem COM DEBUG
-- Vamos ver o que está acontecendo dentro da function
SELECT 
  'TESTE can_access_jovem com DEBUG' as diagnostico,
  can_access_jovem(NULL, NULL, NULL, NULL) as resultado;

-- 12. TESTAR FUNCTION can_access_viagem_by_level COM DEBUG
-- Vamos ver o que está acontecendo dentro da function
SELECT 
  'TESTE can_access_viagem_by_level com DEBUG' as diagnostico,
  can_access_viagem_by_level(NULL, NULL, NULL, NULL) as resultado;

-- =====================================================
-- FIM DO DIAGNÓSTICO SIMPLES
-- =====================================================
