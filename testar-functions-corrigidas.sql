-- =====================================================
-- TESTE DAS FUNCTIONS CORRIGIDAS
-- =====================================================
-- Este script testa se as functions corrigidas estão funcionando

-- 1. VERIFICAR USUÁRIO ATUAL
SELECT 
  'USUÁRIO ATUAL' as diagnostico,
  auth.uid() as user_id_auth,
  u.id as user_id,
  u.nome,
  u.email,
  u.nivel
FROM public.usuarios u
WHERE u.id_auth = auth.uid();

-- 2. VERIFICAR SE O USUÁRIO É LÍDER NACIONAL
SELECT 
  'VERIFICAÇÃO LÍDER NACIONAL' as diagnostico,
  CASE 
    WHEN u.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju') THEN '✅ USUÁRIO É LÍDER NACIONAL'
    ELSE '❌ USUÁRIO NÃO É LÍDER NACIONAL'
  END as resultado,
  u.nivel as nivel_atual
FROM public.usuarios u
WHERE u.id_auth = auth.uid();

-- 3. TESTAR FUNCTION can_access_jovem COM DEBUG
SELECT 
  'TESTE can_access_jovem com DEBUG' as diagnostico,
  can_access_jovem(NULL, NULL, NULL, NULL) as resultado;

-- 4. TESTAR FUNCTION can_access_viagem_by_level COM DEBUG
SELECT 
  'TESTE can_access_viagem_by_level com DEBUG' as diagnostico,
  can_access_viagem_by_level(NULL, NULL, NULL, NULL) as resultado;

-- 5. TESTAR COM UUIDs REAIS (usando dados do usuário atual)
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
  'TESTE COM DADOS REAIS' as diagnostico,
  can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id) as acesso_jovem,
  can_access_viagem_by_level(estado_id, bloco_id, regiao_id, igreja_id) as acesso_viagem
FROM user_data;

-- 6. VERIFICAR SE LÍDERES NACIONAIS TÊM ACESSO TOTAL
SELECT 
  'VERIFICAÇÃO ACESSO TOTAL' as diagnostico,
  CASE 
    WHEN can_access_jovem(NULL, NULL, NULL, NULL) = true
     AND can_access_viagem_by_level(NULL, NULL, NULL, NULL) = true
    THEN '✅ LÍDERES NACIONAIS TÊM ACESSO TOTAL'
    ELSE '❌ LÍDERES NACIONAIS NÃO TÊM ACESSO TOTAL'
  END as resultado;

-- 7. VERIFICAR SE LÍDERES NACIONAIS TÊM ACESSO A QUALQUER LOCALIZAÇÃO
SELECT 
  'VERIFICAÇÃO ACESSO A QUALQUER LOCALIZAÇÃO' as diagnostico,
  CASE 
    WHEN can_access_jovem('0f922947-675b-5f2b-8dfc-bcc180ccb86d', NULL, NULL, NULL) = true
     AND can_access_viagem_by_level('0f922947-675b-5f2b-8dfc-bcc180ccb86d', NULL, NULL, NULL) = true
    THEN '✅ LÍDERES NACIONAIS TÊM ACESSO A QUALQUER LOCALIZAÇÃO'
    ELSE '❌ LÍDERES NACIONAIS NÃO TÊM ACESSO A QUALQUER LOCALIZAÇÃO'
  END as resultado;

-- 8. VERIFICAR SE LÍDERES NACIONAIS TÊM ACESSO INDEPENDENTE DE QUEM CRIOU
SELECT 
  'VERIFICAÇÃO ACESSO INDEPENDENTE DE CRIADOR' as diagnostico,
  CASE 
    WHEN can_access_jovem(NULL, NULL, NULL, NULL) = true
     AND can_access_viagem_by_level(NULL, NULL, NULL, NULL) = true
    THEN '✅ LÍDERES NACIONAIS TÊM ACESSO INDEPENDENTE DE QUEM CRIOU'
    ELSE '❌ LÍDERES NACIONAIS NÃO TÊM ACESSO INDEPENDENTE DE QUEM CRIOU'
  END as resultado;

-- 9. VERIFICAR SE LÍDERES NACIONAIS TÊM ACESSO A DADOS DE QUALQUER USUÁRIO
SELECT 
  'VERIFICAÇÃO ACESSO A DADOS DE QUALQUER USUÁRIO' as diagnostico,
  CASE 
    WHEN can_access_jovem(NULL, NULL, NULL, NULL) = true
     AND can_access_viagem_by_level(NULL, NULL, NULL, NULL) = true
    THEN '✅ LÍDERES NACIONAIS TÊM ACESSO A DADOS DE QUALQUER USUÁRIO'
    ELSE '❌ LÍDERES NACIONAIS NÃO TÊM ACESSO A DADOS DE QUALQUER USUÁRIO'
  END as resultado;

-- 10. VERIFICAR SE LÍDERES NACIONAIS TÊM ACESSO A DADOS DE QUALQUER LOCALIZAÇÃO
SELECT 
  'VERIFICAÇÃO ACESSO A DADOS DE QUALQUER LOCALIZAÇÃO' as diagnostico,
  CASE 
    WHEN can_access_jovem(NULL, NULL, NULL, NULL) = true
     AND can_access_viagem_by_level(NULL, NULL, NULL, NULL) = true
    THEN '✅ LÍDERES NACIONAIS TÊM ACESSO A DADOS DE QUALQUER LOCALIZAÇÃO'
    ELSE '❌ LÍDERES NACIONAIS NÃO TÊM ACESSO A DADOS DE QUALQUER LOCALIZAÇÃO'
  END as resultado;

-- =====================================================
-- FIM DO TESTE
-- =====================================================
