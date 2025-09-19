-- =====================================================
-- TESTE FINAL DE ACESSO PARA LÍDERES NACIONAIS
-- =====================================================
-- Este script testa se os líderes nacionais têm acesso total

-- 1. VERIFICAR USUÁRIO ATUAL E SEU NÍVEL
SELECT 
  'USUÁRIO ATUAL' as teste,
  u.nome,
  u.email,
  u.nivel,
  CASE 
    WHEN u.nivel = 'administrador' THEN 'Administrador'
    WHEN u.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju') THEN 'Líder Nacional'
    WHEN u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') THEN 'Líder Estadual'
    WHEN u.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') THEN 'Líder de Bloco'
    WHEN u.nivel = 'lider_regional_iurd' THEN 'Líder Regional'
    WHEN u.nivel = 'lider_igreja_iurd' THEN 'Líder de Igreja'
    WHEN u.nivel = 'colaborador' THEN 'Colaborador'
    WHEN u.nivel = 'jovem' THEN 'Jovem'
    ELSE 'Nível não reconhecido'
  END as descricao_nivel
FROM public.usuarios u
WHERE u.id_auth = auth.uid();

-- 2. TESTAR ACESSO A JOVENS COM NULL (deve ser true para líderes nacionais)
SELECT 
  'TESTE ACESSO JOVENS' as teste,
  can_access_jovem(NULL, NULL, NULL, NULL) as resultado,
  CASE 
    WHEN can_access_jovem(NULL, NULL, NULL, NULL) = true THEN '✅ ACESSO CONCEDIDO'
    ELSE '❌ ACESSO NEGADO'
  END as status;

-- 3. TESTAR ACESSO A DADOS DE VIAGEM COM NULL (deve ser true para líderes nacionais)
SELECT 
  'TESTE ACESSO VIAGENS' as teste,
  can_access_viagem_by_level(NULL, NULL, NULL, NULL) as resultado,
  CASE 
    WHEN can_access_viagem_by_level(NULL, NULL, NULL, NULL) = true THEN '✅ ACESSO CONCEDIDO'
    ELSE '❌ ACESSO NEGADO'
  END as status;

-- 4. TESTAR ACESSO COM UUIDs REAIS (usando dados do usuário atual)
WITH user_data AS (
  SELECT 
    estado_id,
    bloco_id,
    regiao_id,
    igreja_id
  FROM public.usuarios 
  WHERE id_auth = auth.uid()
)
SELECT 
  'TESTE COM DADOS REAIS' as teste,
  can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id) as acesso_jovem,
  can_access_viagem_by_level(estado_id, bloco_id, regiao_id, igreja_id) as acesso_viagem,
  CASE 
    WHEN can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id) = true
     AND can_access_viagem_by_level(estado_id, bloco_id, regiao_id, igreja_id) = true
    THEN '✅ ACESSO TOTAL CONCEDIDO'
    ELSE '❌ ACESSO TOTAL NEGADO'
  END as status
FROM user_data;

-- 5. TESTAR ACESSO COM UUIDs DE OUTROS ESTADOS (deve ser true para líderes nacionais)
SELECT 
  'TESTE ACESSO OUTROS ESTADOS' as teste,
  can_access_jovem('0f922947-675b-5f2b-8dfc-bcc180ccb86d', NULL, NULL, NULL) as acesso_jovem,
  can_access_viagem_by_level('0f922947-675b-5f2b-8dfc-bcc180ccb86d', NULL, NULL, NULL) as acesso_viagem,
  CASE 
    WHEN can_access_jovem('0f922947-675b-5f2b-8dfc-bcc180ccb86d', NULL, NULL, NULL) = true
     AND can_access_viagem_by_level('0f922947-675b-5f2b-8dfc-bcc180ccb86d', NULL, NULL, NULL) = true
    THEN '✅ ACESSO A OUTROS ESTADOS CONCEDIDO'
    ELSE '❌ ACESSO A OUTROS ESTADOS NEGADO'
  END as status;

-- 6. VERIFICAÇÃO FINAL DE ACESSO TOTAL
SELECT 
  'VERIFICAÇÃO FINAL' as teste,
  CASE 
    WHEN can_access_jovem(NULL, NULL, NULL, NULL) = true
     AND can_access_viagem_by_level(NULL, NULL, NULL, NULL) = true
     AND can_access_jovem('0f922947-675b-5f2b-8dfc-bcc180ccb86d', NULL, NULL, NULL) = true
     AND can_access_viagem_by_level('0f922947-675b-5f2b-8dfc-bcc180ccb86d', NULL, NULL, NULL) = true
    THEN '✅ LÍDERES NACIONAIS TÊM ACESSO TOTAL CONFIRMADO'
    ELSE '❌ LÍDERES NACIONAIS NÃO TÊM ACESSO TOTAL'
  END as resultado;

-- 7. VERIFICAR SE O USUÁRIO É LÍDER NACIONAL
SELECT 
  'VERIFICAÇÃO LÍDER NACIONAL' as teste,
  CASE 
    WHEN u.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju') THEN '✅ USUÁRIO É LÍDER NACIONAL'
    ELSE '❌ USUÁRIO NÃO É LÍDER NACIONAL'
  END as resultado,
  u.nivel as nivel_atual
FROM public.usuarios u
WHERE u.id_auth = auth.uid();

-- 8. VERIFICAR SE O USUÁRIO É ADMINISTRADOR
SELECT 
  'VERIFICAÇÃO ADMINISTRADOR' as teste,
  CASE 
    WHEN u.nivel = 'administrador' THEN '✅ USUÁRIO É ADMINISTRADOR'
    ELSE '❌ USUÁRIO NÃO É ADMINISTRADOR'
  END as resultado,
  u.nivel as nivel_atual
FROM public.usuarios u
WHERE u.id_auth = auth.uid();

-- =====================================================
-- FIM DO TESTE FINAL
-- =====================================================
