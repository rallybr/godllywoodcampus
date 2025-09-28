-- =====================================================
-- SCRIPT DE TESTE CORRIGIDO PARA LÍDERES NACIONAIS
-- =====================================================
-- Este script testa se os líderes nacionais têm acesso total
-- usando UUIDs reais da base de dados

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

-- 2. OBTER UUIDs REAIS PARA TESTE
-- Buscar alguns UUIDs reais da base de dados
WITH uuids_reais AS (
  SELECT 
    e.id as estado_id,
    b.id as bloco_id,
    r.id as regiao_id,
    i.id as igreja_id
  FROM public.estados e
  LEFT JOIN public.blocos b ON b.estado_id = e.id
  LEFT JOIN public.regioes r ON r.bloco_id = b.id
  LEFT JOIN public.igrejas i ON i.regiao_id = r.id
  WHERE e.id IS NOT NULL
  LIMIT 3
)
SELECT 
  'UUIDs REAIS ENCONTRADOS' as teste,
  estado_id,
  bloco_id,
  regiao_id,
  igreja_id
FROM uuids_reais;

-- 3. TESTAR FUNCTION can_access_jovem COM UUIDs REAIS
-- (Execute como um líder nacional para testar)
WITH uuids_reais AS (
  SELECT 
    e.id as estado_id,
    b.id as bloco_id,
    r.id as regiao_id,
    i.id as igreja_id
  FROM public.estados e
  LEFT JOIN public.blocos b ON b.estado_id = e.id
  LEFT JOIN public.regioes r ON r.bloco_id = b.id
  LEFT JOIN public.igrejas i ON i.regiao_id = r.id
  WHERE e.id IS NOT NULL
  LIMIT 3
)
SELECT 
  'TESTE can_access_jovem' as teste,
  estado_id,
  bloco_id,
  regiao_id,
  igreja_id,
  can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id) as tem_acesso
FROM uuids_reais;

-- 4. TESTAR FUNCTION can_access_viagem_by_level COM UUIDs REAIS
-- (Execute como um líder nacional para testar)
WITH uuids_reais AS (
  SELECT 
    e.id as estado_id,
    b.id as bloco_id,
    r.id as regiao_id,
    i.id as igreja_id
  FROM public.estados e
  LEFT JOIN public.blocos b ON b.estado_id = e.id
  LEFT JOIN public.regioes r ON r.bloco_id = b.id
  LEFT JOIN public.igrejas i ON i.regiao_id = r.id
  WHERE e.id IS NOT NULL
  LIMIT 3
)
SELECT 
  'TESTE can_access_viagem_by_level' as teste,
  estado_id,
  bloco_id,
  regiao_id,
  igreja_id,
  can_access_viagem_by_level(estado_id, bloco_id, regiao_id, igreja_id) as tem_acesso
FROM uuids_reais;

-- 5. VERIFICAR SE LÍDERES NACIONAIS TÊM ACESSO A DADOS DE QUALQUER LOCALIZAÇÃO
-- (Execute como um líder nacional para testar)
WITH uuids_reais AS (
  SELECT 
    e.id as estado_id,
    b.id as bloco_id,
    r.id as regiao_id,
    i.id as igreja_id
  FROM public.estados e
  LEFT JOIN public.blocos b ON b.estado_id = e.id
  LEFT JOIN public.regioes r ON r.bloco_id = b.id
  LEFT JOIN public.igrejas i ON i.regiao_id = r.id
  WHERE e.id IS NOT NULL
  LIMIT 3
)
SELECT 
  'TESTE ACESSO TOTAL' as teste,
  CASE 
    WHEN COUNT(*) = COUNT(CASE WHEN can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id) = true THEN 1 END)
    THEN '✅ LÍDERES NACIONAIS TÊM ACESSO TOTAL'
    ELSE '❌ LÍDERES NACIONAIS NÃO TÊM ACESSO TOTAL'
  END as resultado,
  COUNT(*) as total_testes,
  COUNT(CASE WHEN can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id) = true THEN 1 END) as acessos_autorizados
FROM uuids_reais;

-- 6. VERIFICAR SE LÍDERES NACIONAIS TÊM ACESSO A DADOS DE VIAGEM DE QUALQUER LOCALIZAÇÃO
-- (Execute como um líder nacional para testar)
WITH uuids_reais AS (
  SELECT 
    e.id as estado_id,
    b.id as bloco_id,
    r.id as regiao_id,
    i.id as igreja_id
  FROM public.estados e
  LEFT JOIN public.blocos b ON b.estado_id = e.id
  LEFT JOIN public.regioes r ON r.bloco_id = b.id
  LEFT JOIN public.igrejas i ON i.regiao_id = r.id
  WHERE e.id IS NOT NULL
  LIMIT 3
)
SELECT 
  'TESTE ACESSO VIAGEM TOTAL' as teste,
  CASE 
    WHEN COUNT(*) = COUNT(CASE WHEN can_access_viagem_by_level(estado_id, bloco_id, regiao_id, igreja_id) = true THEN 1 END)
    THEN '✅ LÍDERES NACIONAIS TÊM ACESSO TOTAL A VIAGENS'
    ELSE '❌ LÍDERES NACIONAIS NÃO TÊM ACESSO TOTAL A VIAGENS'
  END as resultado,
  COUNT(*) as total_testes,
  COUNT(CASE WHEN can_access_viagem_by_level(estado_id, bloco_id, regiao_id, igreja_id) = true THEN 1 END) as acessos_autorizados
FROM uuids_reais;

-- 7. VERIFICAR SE LÍDERES NACIONAIS TÊM ACESSO A DADOS INDEPENDENTE DE QUEM CRIOU
-- (Execute como um líder nacional para testar)
WITH uuids_reais AS (
  SELECT 
    e.id as estado_id,
    b.id as bloco_id,
    r.id as regiao_id,
    i.id as igreja_id
  FROM public.estados e
  LEFT JOIN public.blocos b ON b.estado_id = e.id
  LEFT JOIN public.regioes r ON r.bloco_id = b.id
  LEFT JOIN public.igrejas i ON i.regiao_id = r.id
  WHERE e.id IS NOT NULL
  LIMIT 3
)
SELECT 
  'TESTE ACESSO INDEPENDENTE DE CRIADOR' as teste,
  CASE 
    WHEN COUNT(*) = COUNT(CASE WHEN can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id) = true THEN 1 END)
    THEN '✅ LÍDERES NACIONAIS TÊM ACESSO INDEPENDENTE DE QUEM CRIOU'
    ELSE '❌ LÍDERES NACIONAIS NÃO TÊM ACESSO INDEPENDENTE DE QUEM CRIOU'
  END as resultado,
  COUNT(*) as total_testes,
  COUNT(CASE WHEN can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id) = true THEN 1 END) as acessos_autorizados
FROM uuids_reais;

-- 8. VERIFICAR SE LÍDERES NACIONAIS TÊM ACESSO A DADOS DE VIAGEM INDEPENDENTE DE QUEM CRIOU
-- (Execute como um líder nacional para testar)
WITH uuids_reais AS (
  SELECT 
    e.id as estado_id,
    b.id as bloco_id,
    r.id as regiao_id,
    i.id as igreja_id
  FROM public.estados e
  LEFT JOIN public.blocos b ON b.estado_id = e.id
  LEFT JOIN public.regioes r ON r.bloco_id = b.id
  LEFT JOIN public.igrejas i ON i.regiao_id = r.id
  WHERE e.id IS NOT NULL
  LIMIT 3
)
SELECT 
  'TESTE ACESSO VIAGEM INDEPENDENTE DE CRIADOR' as teste,
  CASE 
    WHEN COUNT(*) = COUNT(CASE WHEN can_access_viagem_by_level(estado_id, bloco_id, regiao_id, igreja_id) = true THEN 1 END)
    THEN '✅ LÍDERES NACIONAIS TÊM ACESSO A VIAGENS INDEPENDENTE DE QUEM CRIOU'
    ELSE '❌ LÍDERES NACIONAIS NÃO TÊM ACESSO A VIAGENS INDEPENDENTE DE QUEM CRIOU'
  END as resultado,
  COUNT(*) as total_testes,
  COUNT(CASE WHEN can_access_viagem_by_level(estado_id, bloco_id, regiao_id, igreja_id) = true THEN 1 END) as acessos_autorizados
FROM uuids_reais;

-- 9. VERIFICAR SE LÍDERES NACIONAIS TÊM ACESSO A DADOS DE QUALQUER USUÁRIO
-- (Execute como um líder nacional para testar)
WITH uuids_reais AS (
  SELECT 
    e.id as estado_id,
    b.id as bloco_id,
    r.id as regiao_id,
    i.id as igreja_id
  FROM public.estados e
  LEFT JOIN public.blocos b ON b.estado_id = e.id
  LEFT JOIN public.regioes r ON r.bloco_id = b.id
  LEFT JOIN public.igrejas i ON i.regiao_id = r.id
  WHERE e.id IS NOT NULL
  LIMIT 3
)
SELECT 
  'TESTE ACESSO A DADOS DE QUALQUER USUÁRIO' as teste,
  CASE 
    WHEN COUNT(*) = COUNT(CASE WHEN can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id) = true THEN 1 END)
    THEN '✅ LÍDERES NACIONAIS TÊM ACESSO A DADOS DE QUALQUER USUÁRIO'
    ELSE '❌ LÍDERES NACIONAIS NÃO TÊM ACESSO A DADOS DE QUALQUER USUÁRIO'
  END as resultado,
  COUNT(*) as total_testes,
  COUNT(CASE WHEN can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id) = true THEN 1 END) as acessos_autorizados
FROM uuids_reais;

-- 10. VERIFICAR SE LÍDERES NACIONAIS TÊM ACESSO A DADOS DE VIAGEM DE QUALQUER USUÁRIO
-- (Execute como um líder nacional para testar)
WITH uuids_reais AS (
  SELECT 
    e.id as estado_id,
    b.id as bloco_id,
    r.id as regiao_id,
    i.id as igreja_id
  FROM public.estados e
  LEFT JOIN public.blocos b ON b.estado_id = e.id
  LEFT JOIN public.regioes r ON r.bloco_id = b.id
  LEFT JOIN public.igrejas i ON i.regiao_id = r.id
  WHERE e.id IS NOT NULL
  LIMIT 3
)
SELECT 
  'TESTE ACESSO A VIAGENS DE QUALQUER USUÁRIO' as teste,
  CASE 
    WHEN COUNT(*) = COUNT(CASE WHEN can_access_viagem_by_level(estado_id, bloco_id, regiao_id, igreja_id) = true THEN 1 END)
    THEN '✅ LÍDERES NACIONAIS TÊM ACESSO A VIAGENS DE QUALQUER USUÁRIO'
    ELSE '❌ LÍDERES NACIONAIS NÃO TÊM ACESSO A VIAGENS DE QUALQUER USUÁRIO'
  END as resultado,
  COUNT(*) as total_testes,
  COUNT(CASE WHEN can_access_viagem_by_level(estado_id, bloco_id, regiao_id, igreja_id) = true THEN 1 END) as acessos_autorizados
FROM uuids_reais;

-- 11. VERIFICAR SE LÍDERES NACIONAIS TÊM ACESSO A DADOS DE QUALQUER LOCALIZAÇÃO
-- (Execute como um líder nacional para testar)
WITH uuids_reais AS (
  SELECT 
    e.id as estado_id,
    b.id as bloco_id,
    r.id as regiao_id,
    i.id as igreja_id
  FROM public.estados e
  LEFT JOIN public.blocos b ON b.estado_id = e.id
  LEFT JOIN public.regioes r ON r.bloco_id = b.id
  LEFT JOIN public.igrejas i ON i.regiao_id = r.id
  WHERE e.id IS NOT NULL
  LIMIT 3
)
SELECT 
  'TESTE ACESSO A DADOS DE QUALQUER LOCALIZAÇÃO' as teste,
  CASE 
    WHEN COUNT(*) = COUNT(CASE WHEN can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id) = true THEN 1 END)
    THEN '✅ LÍDERES NACIONAIS TÊM ACESSO A DADOS DE QUALQUER LOCALIZAÇÃO'
    ELSE '❌ LÍDERES NACIONAIS NÃO TÊM ACESSO A DADOS DE QUALQUER LOCALIZAÇÃO'
  END as resultado,
  COUNT(*) as total_testes,
  COUNT(CASE WHEN can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id) = true THEN 1 END) as acessos_autorizados
FROM uuids_reais;

-- 12. VERIFICAR SE LÍDERES NACIONAIS TÊM ACESSO A DADOS DE VIAGEM DE QUALQUER LOCALIZAÇÃO
-- (Execute como um líder nacional para testar)
WITH uuids_reais AS (
  SELECT 
    e.id as estado_id,
    b.id as bloco_id,
    r.id as regiao_id,
    i.id as igreja_id
  FROM public.estados e
  LEFT JOIN public.blocos b ON b.estado_id = e.id
  LEFT JOIN public.regioes r ON r.bloco_id = b.id
  LEFT JOIN public.igrejas i ON i.regiao_id = r.id
  WHERE e.id IS NOT NULL
  LIMIT 3
)
SELECT 
  'TESTE ACESSO A VIAGENS DE QUALQUER LOCALIZAÇÃO' as teste,
  CASE 
    WHEN COUNT(*) = COUNT(CASE WHEN can_access_viagem_by_level(estado_id, bloco_id, regiao_id, igreja_id) = true THEN 1 END)
    THEN '✅ LÍDERES NACIONAIS TÊM ACESSO A VIAGENS DE QUALQUER LOCALIZAÇÃO'
    ELSE '❌ LÍDERES NACIONAIS NÃO TÊM ACESSO A VIAGENS DE QUALQUER LOCALIZAÇÃO'
  END as resultado,
  COUNT(*) as total_testes,
  COUNT(CASE WHEN can_access_viagem_by_level(estado_id, bloco_id, regiao_id, igreja_id) = true THEN 1 END) as acessos_autorizados
FROM uuids_reais;

-- 13. VERIFICAR SE LÍDERES NACIONAIS TÊM ACESSO A DADOS DE QUALQUER USUÁRIO
-- (Execute como um líder nacional para testar)
WITH uuids_reais AS (
  SELECT 
    e.id as estado_id,
    b.id as bloco_id,
    r.id as regiao_id,
    i.id as igreja_id
  FROM public.estados e
  LEFT JOIN public.blocos b ON b.estado_id = e.id
  LEFT JOIN public.regioes r ON r.bloco_id = b.id
  LEFT JOIN public.igrejas i ON i.regiao_id = r.id
  WHERE e.id IS NOT NULL
  LIMIT 3
)
SELECT 
  'TESTE ACESSO A DADOS DE QUALQUER USUÁRIO' as teste,
  CASE 
    WHEN COUNT(*) = COUNT(CASE WHEN can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id) = true THEN 1 END)
    THEN '✅ LÍDERES NACIONAIS TÊM ACESSO A DADOS DE QUALQUER USUÁRIO'
    ELSE '❌ LÍDERES NACIONAIS NÃO TÊM ACESSO A DADOS DE QUALQUER USUÁRIO'
  END as resultado,
  COUNT(*) as total_testes,
  COUNT(CASE WHEN can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id) = true THEN 1 END) as acessos_autorizados
FROM uuids_reais;

-- 14. VERIFICAR SE LÍDERES NACIONAIS TÊM ACESSO A DADOS DE VIAGEM DE QUALQUER USUÁRIO
-- (Execute como um líder nacional para testar)
WITH uuids_reais AS (
  SELECT 
    e.id as estado_id,
    b.id as bloco_id,
    r.id as regiao_id,
    i.id as igreja_id
  FROM public.estados e
  LEFT JOIN public.blocos b ON b.estado_id = e.id
  LEFT JOIN public.regioes r ON r.bloco_id = b.id
  LEFT JOIN public.igrejas i ON i.regiao_id = r.id
  WHERE e.id IS NOT NULL
  LIMIT 3
)
SELECT 
  'TESTE ACESSO A VIAGENS DE QUALQUER USUÁRIO' as teste,
  CASE 
    WHEN COUNT(*) = COUNT(CASE WHEN can_access_viagem_by_level(estado_id, bloco_id, regiao_id, igreja_id) = true THEN 1 END)
    THEN '✅ LÍDERES NACIONAIS TÊM ACESSO A VIAGENS DE QUALQUER USUÁRIO'
    ELSE '❌ LÍDERES NACIONAIS NÃO TÊM ACESSO A VIAGENS DE QUALQUER USUÁRIO'
  END as resultado,
  COUNT(*) as total_testes,
  COUNT(CASE WHEN can_access_viagem_by_level(estado_id, bloco_id, regiao_id, igreja_id) = true THEN 1 END) as acessos_autorizados
FROM uuids_reais;

-- 15. VERIFICAR SE LÍDERES NACIONAIS TÊM ACESSO A DADOS DE QUALQUER LOCALIZAÇÃO
-- (Execute como um líder nacional para testar)
WITH uuids_reais AS (
  SELECT 
    e.id as estado_id,
    b.id as bloco_id,
    r.id as regiao_id,
    i.id as igreja_id
  FROM public.estados e
  LEFT JOIN public.blocos b ON b.estado_id = e.id
  LEFT JOIN public.regioes r ON r.bloco_id = b.id
  LEFT JOIN public.igrejas i ON i.regiao_id = r.id
  WHERE e.id IS NOT NULL
  LIMIT 3
)
SELECT 
  'TESTE ACESSO A DADOS DE QUALQUER LOCALIZAÇÃO' as teste,
  CASE 
    WHEN COUNT(*) = COUNT(CASE WHEN can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id) = true THEN 1 END)
    THEN '✅ LÍDERES NACIONAIS TÊM ACESSO A DADOS DE QUALQUER LOCALIZAÇÃO'
    ELSE '❌ LÍDERES NACIONAIS NÃO TÊM ACESSO A DADOS DE QUALQUER LOCALIZAÇÃO'
  END as resultado,
  COUNT(*) as total_testes,
  COUNT(CASE WHEN can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id) = true THEN 1 END) as acessos_autorizados
FROM uuids_reais;

-- 16. VERIFICAR SE LÍDERES NACIONAIS TÊM ACESSO A DADOS DE VIAGEM DE QUALQUER LOCALIZAÇÃO
-- (Execute como um líder nacional para testar)
WITH uuids_reais AS (
  SELECT 
    e.id as estado_id,
    b.id as bloco_id,
    r.id as regiao_id,
    i.id as igreja_id
  FROM public.estados e
  LEFT JOIN public.blocos b ON b.estado_id = e.id
  LEFT JOIN public.regioes r ON r.bloco_id = b.id
  LEFT JOIN public.igrejas i ON i.regiao_id = r.id
  WHERE e.id IS NOT NULL
  LIMIT 3
)
SELECT 
  'TESTE ACESSO A VIAGENS DE QUALQUER LOCALIZAÇÃO' as teste,
  CASE 
    WHEN COUNT(*) = COUNT(CASE WHEN can_access_viagem_by_level(estado_id, bloco_id, regiao_id, igreja_id) = true THEN 1 END)
    THEN '✅ LÍDERES NACIONAIS TÊM ACESSO A VIAGENS DE QUALQUER LOCALIZAÇÃO'
    ELSE '❌ LÍDERES NACIONAIS NÃO TÊM ACESSO A VIAGENS DE QUALQUER LOCALIZAÇÃO'
  END as resultado,
  COUNT(*) as total_testes,
  COUNT(CASE WHEN can_access_viagem_by_level(estado_id, bloco_id, regiao_id, igreja_id) = true THEN 1 END) as acessos_autorizados
FROM uuids_reais;

-- =====================================================
-- FIM DO SCRIPT DE TESTE CORRIGIDO
-- =====================================================
