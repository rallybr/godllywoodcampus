-- =====================================================
-- Script para recuperar as referências geográficas originais
-- =====================================================

-- PASSO 1: Verificar se ainda existem jovens no estado duplicado (antes da migração)
-- Se não existirem, precisamos verificar o histórico ou logs
SELECT 
  'VERIFICAÇÃO - JOVENS NO ESTADO DUPLICADO' as tipo,
  COUNT(*) as total_jovens
FROM public.jovens 
WHERE estado_id = '3373645f-f666-5b4e-a0b0-3556f45a0cc2';

-- PASSO 2: Verificar jovens de Minas Gerais atuais (após migração)
SELECT 
  'JOVENS DE MINAS GERAIS ATUAIS' as tipo,
  j.id as jovem_id,
  j.nome_completo,
  j.estado_id,
  j.bloco_id,
  j.regiao_id,
  j.igreja_id,
  b.nome as bloco_nome,
  r.nome as regiao_nome,
  i.nome as igreja_nome
FROM public.jovens j
LEFT JOIN public.blocos b ON b.id = j.bloco_id
LEFT JOIN public.regioes r ON r.id = j.regiao_id
LEFT JOIN public.igrejas i ON i.id = j.igreja_id
WHERE j.estado_id = '182c2fcc-122a-4742-99e2-3622a276070c'  -- Minas Gerais correto
ORDER BY j.nome_completo;

-- PASSO 3: Verificar se há logs de auditoria ou histórico
SELECT 
  'VERIFICAÇÃO - LOGS DE AUDITORIA' as tipo,
  COUNT(*) as total_logs
FROM public.logs_auditoria 
WHERE tabela_afetada = 'jovens' 
  AND acao = 'UPDATE'
  AND data_acao >= CURRENT_DATE - INTERVAL '1 day';

-- PASSO 4: Verificar se há backup ou histórico em outras tabelas
SELECT 
  'VERIFICAÇÃO - OUTRAS FONTES' as tipo,
  'Avaliações' as fonte,
  COUNT(*) as total
FROM public.avaliacoes a
JOIN public.jovens j ON j.id = a.jovem_id
WHERE j.estado_id = '182c2fcc-122a-4742-99e2-3622a276070c'

UNION ALL

SELECT 
  'VERIFICAÇÃO - OUTRAS FONTES' as tipo,
  'Dados de Viagem' as fonte,
  COUNT(*) as total
FROM public.dados_viagem d
JOIN public.jovens j ON j.id = d.jovem_id
WHERE j.estado_id = '182c2fcc-122a-4742-99e2-3622a276070c';

-- PASSO 5: Verificar se há padrões nos dados atuais
SELECT 
  'PADRÕES NOS DADOS ATUAIS' as tipo,
  'Blocos mais comuns' as categoria,
  b.nome as nome,
  COUNT(*) as total_jovens
FROM public.jovens j
JOIN public.blocos b ON b.id = j.bloco_id
WHERE j.estado_id = '182c2fcc-122a-4742-99e2-3622a276070c'
GROUP BY b.nome
ORDER BY total_jovens DESC

UNION ALL

SELECT 
  'PADRÕES NOS DADOS ATUAIS' as tipo,
  'Regiões mais comuns' as categoria,
  r.nome as nome,
  COUNT(*) as total_jovens
FROM public.jovens j
JOIN public.regioes r ON r.id = j.regiao_id
WHERE j.estado_id = '182c2fcc-122a-4742-99e2-3622a276070c'
GROUP BY r.nome
ORDER BY total_jovens DESC

UNION ALL

SELECT 
  'PADRÕES NOS DADOS ATUAIS' as tipo,
  'Igrejas mais comuns' as categoria,
  i.nome as nome,
  COUNT(*) as total_jovens
FROM public.jovens j
JOIN public.igrejas i ON i.id = j.igreja_id
WHERE j.estado_id = '182c2fcc-122a-4742-99e2-3622a276070c'
GROUP BY i.nome
ORDER BY total_jovens DESC;
