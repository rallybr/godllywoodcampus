-- =====================================================
-- Script para verificar os jovens de Minas Gerais ORIGINAIS
-- =====================================================

-- PASSO 1: Verificar se ainda existem jovens no estado duplicado (antes da migração)
SELECT 
  'JOVENS NO ESTADO DUPLICADO (ANTES DA MIGRAÇÃO)' as tipo,
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
WHERE j.estado_id = '3373645f-f666-5b4e-a0b0-3556f45a0cc2'  -- Estado duplicado
ORDER BY j.nome_completo;

-- PASSO 2: Verificar jovens de Minas Gerais atuais (após migração)
SELECT 
  'JOVENS DE MINAS GERAIS ATUAIS (APÓS MIGRAÇÃO)' as tipo,
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

-- PASSO 3: Verificar se há logs de auditoria
SELECT 
  'LOGS DE AUDITORIA' as tipo,
  la.id as log_id,
  la.tabela_afetada,
  la.acao,
  la.dados_anteriores,
  la.dados_novos,
  la.data_acao
FROM public.logs_auditoria la
WHERE la.tabela_afetada = 'jovens' 
  AND la.acao = 'UPDATE'
  AND la.data_acao >= CURRENT_DATE - INTERVAL '1 day'
ORDER BY la.data_acao DESC;

-- PASSO 4: Verificar se há backup ou histórico em outras tabelas
SELECT 
  'HISTÓRICO EM AVALIAÇÕES' as tipo,
  a.id as avaliacao_id,
  a.jovem_id,
  j.nome_completo,
  a.data_avaliacao
FROM public.avaliacoes a
JOIN public.jovens j ON j.id = a.jovem_id
WHERE j.estado_id = '182c2fcc-122a-4742-99e2-3622a276070c'
ORDER BY a.data_avaliacao DESC;

-- PASSO 5: Verificar se há padrões nos dados atuais
SELECT 
  'PADRÕES NOS DADOS ATUAIS' as tipo,
  'Blocos mais comuns' as categoria,
  b.nome as nome,
  b.id as bloco_id,
  COUNT(*) as total_jovens
FROM public.jovens j
JOIN public.blocos b ON b.id = j.bloco_id
WHERE j.estado_id = '182c2fcc-122a-4742-99e2-3622a276070c'
GROUP BY b.id, b.nome
ORDER BY total_jovens DESC

UNION ALL

SELECT 
  'PADRÕES NOS DADOS ATUAIS' as tipo,
  'Regiões mais comuns' as categoria,
  r.nome as nome,
  r.id as regiao_id,
  COUNT(*) as total_jovens
FROM public.jovens j
JOIN public.regioes r ON r.id = j.regiao_id
WHERE j.estado_id = '182c2fcc-122a-4742-99e2-3622a276070c'
GROUP BY r.id, r.nome
ORDER BY total_jovens DESC

UNION ALL

SELECT 
  'PADRÕES NOS DADOS ATUAIS' as tipo,
  'Igrejas mais comuns' as categoria,
  i.nome as nome,
  i.id as igreja_id,
  COUNT(*) as total_jovens
FROM public.jovens j
JOIN public.igrejas i ON i.id = j.igreja_id
WHERE j.estado_id = '182c2fcc-122a-4742-99e2-3622a276070c'
GROUP BY i.id, i.nome
ORDER BY total_jovens DESC;
