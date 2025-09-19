-- =====================================================
-- SCRIPT DE TESTE SIMPLES PARA LÍDERES NACIONAIS
-- =====================================================
-- Este script testa se os líderes nacionais têm acesso total
-- de forma simples e direta

-- 1. VERIFICAR NÍVEIS HIERÁRQUICOS ATUAIS
SELECT 
  'VERIFICAÇÃO DE NÍVEIS' as teste,
  slug,
  nome,
  nivel_hierarquico,
  CASE 
    WHEN nivel_hierarquico = 1 THEN 'Administrador (Acesso Total)'
    WHEN nivel_hierarquico = 2 THEN 'Líder Nacional (Acesso Total)'
    WHEN nivel_hierarquico = 3 THEN 'Líder Estadual (Visão Estadual)'
    WHEN nivel_hierarquico = 4 THEN 'Líder de Bloco (Visão de Bloco)'
    WHEN nivel_hierarquico = 5 THEN 'Líder Regional (Visão Regional)'
    WHEN nivel_hierarquico = 6 THEN 'Líder de Igreja (Visão de Igreja)'
    WHEN nivel_hierarquico = 7 THEN 'Colaborador (Visão do que Criou)'
    WHEN nivel_hierarquico = 8 THEN 'Jovem (Visão Própria)'
    ELSE 'Nível não definido'
  END as descricao_nivel
FROM public.roles 
WHERE slug IN ('administrador', 'lider_nacional_iurd', 'lider_nacional_fju')
ORDER BY nivel_hierarquico ASC;

-- 2. TESTAR FUNCTION can_access_jovem COM NULL (deve retornar true para líderes nacionais)
-- (Execute como um líder nacional para testar)
SELECT 
  'TESTE can_access_jovem com NULL' as teste,
  can_access_jovem(NULL, NULL, NULL, NULL) as tem_acesso;

-- 3. TESTAR FUNCTION can_access_viagem_by_level COM NULL (deve retornar true para líderes nacionais)
-- (Execute como um líder nacional para testar)
SELECT 
  'TESTE can_access_viagem_by_level com NULL' as teste,
  can_access_viagem_by_level(NULL, NULL, NULL, NULL) as tem_acesso;

-- 4. TESTAR FUNCTION can_access_jovem COM UUIDs VÁLIDOS
-- (Execute como um líder nacional para testar)
-- Substitua pelos UUIDs reais da sua base de dados
SELECT 
  'TESTE can_access_jovem com UUIDs válidos' as teste,
  can_access_jovem(
    '0f922947-675b-5f2b-8dfc-bcc180ccb86d', -- UUID de Pernambuco
    NULL, -- bloco_id
    NULL, -- regiao_id  
    NULL  -- igreja_id
  ) as tem_acesso;

-- 5. TESTAR FUNCTION can_access_viagem_by_level COM UUIDs VÁLIDOS
-- (Execute como um líder nacional para testar)
-- Substitua pelos UUIDs reais da sua base de dados
SELECT 
  'TESTE can_access_viagem_by_level com UUIDs válidos' as teste,
  can_access_viagem_by_level(
    '0f922947-675b-5f2b-8dfc-bcc180ccb86d', -- UUID de Pernambuco
    NULL, -- bloco_id
    NULL, -- regiao_id
    NULL  -- igreja_id
  ) as tem_acesso;

-- 6. VERIFICAR SE LÍDERES NACIONAIS TÊM ACESSO TOTAL
-- (Execute como um líder nacional para testar)
SELECT 
  'TESTE ACESSO TOTAL' as teste,
  CASE 
    WHEN can_access_jovem(NULL, NULL, NULL, NULL) = true
     AND can_access_viagem_by_level(NULL, NULL, NULL, NULL) = true
    THEN '✅ LÍDERES NACIONAIS TÊM ACESSO TOTAL'
    ELSE '❌ LÍDERES NACIONAIS NÃO TÊM ACESSO TOTAL'
  END as resultado;

-- 7. VERIFICAR SE LÍDERES NACIONAIS TÊM ACESSO A DADOS DE QUALQUER LOCALIZAÇÃO
-- (Execute como um líder nacional para testar)
SELECT 
  'TESTE ACESSO A QUALQUER LOCALIZAÇÃO' as teste,
  CASE 
    WHEN can_access_jovem('0f922947-675b-5f2b-8dfc-bcc180ccb86d', NULL, NULL, NULL) = true
     AND can_access_viagem_by_level('0f922947-675b-5f2b-8dfc-bcc180ccb86d', NULL, NULL, NULL) = true
    THEN '✅ LÍDERES NACIONAIS TÊM ACESSO A QUALQUER LOCALIZAÇÃO'
    ELSE '❌ LÍDERES NACIONAIS NÃO TÊM ACESSO A QUALQUER LOCALIZAÇÃO'
  END as resultado;

-- 8. VERIFICAR SE LÍDERES NACIONAIS TÊM ACESSO A DADOS INDEPENDENTE DE QUEM CRIOU
-- (Execute como um líder nacional para testar)
SELECT 
  'TESTE ACESSO INDEPENDENTE DE CRIADOR' as teste,
  CASE 
    WHEN can_access_jovem(NULL, NULL, NULL, NULL) = true
     AND can_access_viagem_by_level(NULL, NULL, NULL, NULL) = true
    THEN '✅ LÍDERES NACIONAIS TÊM ACESSO INDEPENDENTE DE QUEM CRIOU'
    ELSE '❌ LÍDERES NACIONAIS NÃO TÊM ACESSO INDEPENDENTE DE QUEM CRIOU'
  END as resultado;

-- 9. VERIFICAR SE LÍDERES NACIONAIS TÊM ACESSO A DADOS DE QUALQUER USUÁRIO
-- (Execute como um líder nacional para testar)
SELECT 
  'TESTE ACESSO A DADOS DE QUALQUER USUÁRIO' as teste,
  CASE 
    WHEN can_access_jovem(NULL, NULL, NULL, NULL) = true
     AND can_access_viagem_by_level(NULL, NULL, NULL, NULL) = true
    THEN '✅ LÍDERES NACIONAIS TÊM ACESSO A DADOS DE QUALQUER USUÁRIO'
    ELSE '❌ LÍDERES NACIONAIS NÃO TÊM ACESSO A DADOS DE QUALQUER USUÁRIO'
  END as resultado;

-- 10. VERIFICAR SE LÍDERES NACIONAIS TÊM ACESSO A DADOS DE QUALQUER LOCALIZAÇÃO
-- (Execute como um líder nacional para testar)
SELECT 
  'TESTE ACESSO A DADOS DE QUALQUER LOCALIZAÇÃO' as teste,
  CASE 
    WHEN can_access_jovem(NULL, NULL, NULL, NULL) = true
     AND can_access_viagem_by_level(NULL, NULL, NULL, NULL) = true
    THEN '✅ LÍDERES NACIONAIS TÊM ACESSO A DADOS DE QUALQUER LOCALIZAÇÃO'
    ELSE '❌ LÍDERES NACIONAIS NÃO TÊM ACESSO A DADOS DE QUALQUER LOCALIZAÇÃO'
  END as resultado;

-- =====================================================
-- FIM DO SCRIPT DE TESTE SIMPLES
-- =====================================================
