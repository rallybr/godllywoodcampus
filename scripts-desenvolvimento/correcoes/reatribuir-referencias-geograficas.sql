-- =====================================================
-- Script para reatribuir referências geográficas aos jovens de Minas Gerais
-- =====================================================

-- PASSO 1: Verificar jovens de Minas Gerais sem referências geográficas
SELECT 
  'JOVENS DE MINAS GERAIS SEM REFERÊNCIAS GEOGRÁFICAS' as tipo,
  j.id as jovem_id,
  j.nome_completo,
  j.estado_id,
  j.bloco_id,
  j.regiao_id,
  j.igreja_id,
  e.nome as estado_nome
FROM public.jovens j
JOIN public.estados e ON e.id = j.estado_id
WHERE j.estado_id = '182c2fcc-122a-4742-99e2-3622a276070c'  -- Minas Gerais correto
  AND (j.bloco_id IS NULL OR j.regiao_id IS NULL OR j.igreja_id IS NULL)
ORDER BY j.nome_completo;

-- PASSO 2: Verificar blocos disponíveis em Minas Gerais
SELECT 
  'BLOCOS DISPONÍVEIS EM MINAS GERAIS' as tipo,
  b.id as bloco_id,
  b.nome as bloco_nome,
  COUNT(j.id) as jovens_vinculados
FROM public.blocos b
LEFT JOIN public.jovens j ON j.bloco_id = b.id
WHERE b.estado_id = '182c2fcc-122a-4742-99e2-3622a276070c'  -- Minas Gerais
GROUP BY b.id, b.nome
ORDER BY b.nome;

-- PASSO 3: Verificar regiões disponíveis em Minas Gerais
SELECT 
  'REGIÕES DISPONÍVEIS EM MINAS GERAIS' as tipo,
  r.id as regiao_id,
  r.nome as regiao_nome,
  COUNT(j.id) as jovens_vinculados
FROM public.regioes r
LEFT JOIN public.jovens j ON j.regiao_id = r.id
WHERE r.estado_id = '182c2fcc-122a-4742-99e2-3622a276070c'  -- Minas Gerais
GROUP BY r.id, r.nome
ORDER BY r.nome;

-- PASSO 4: Verificar igrejas disponíveis em Minas Gerais
SELECT 
  'IGREJAS DISPONÍVEIS EM MINAS GERAIS' as tipo,
  i.id as igreja_id,
  i.nome as igreja_nome,
  COUNT(j.id) as jovens_vinculados
FROM public.igrejas i
LEFT JOIN public.jovens j ON j.igreja_id = i.id
WHERE i.estado_id = '182c2fcc-122a-4742-99e2-3622a276070c'  -- Minas Gerais
GROUP BY i.id, i.nome
ORDER BY i.nome;

-- PASSO 5: Sugestão de reatribuição (você pode ajustar conforme necessário)
-- Exemplo: Atribuir o primeiro bloco disponível a todos os jovens
UPDATE public.jovens 
SET bloco_id = (
  SELECT b.id 
  FROM public.blocos b 
  WHERE b.estado_id = '182c2fcc-122a-4742-99e2-3622a276070c' 
  ORDER BY b.nome 
  LIMIT 1
)
WHERE estado_id = '182c2fcc-122a-4742-99e2-3622a276070c' 
  AND bloco_id IS NULL;

-- PASSO 6: Atribuir a primeira região disponível
UPDATE public.jovens 
SET regiao_id = (
  SELECT r.id 
  FROM public.regioes r 
  WHERE r.estado_id = '182c2fcc-122a-4742-99e2-3622a276070c' 
  ORDER BY r.nome 
  LIMIT 1
)
WHERE estado_id = '182c2fcc-122a-4742-99e2-3622a276070c' 
  AND regiao_id IS NULL;

-- PASSO 7: Atribuir a primeira igreja disponível
UPDATE public.jovens 
SET igreja_id = (
  SELECT i.id 
  FROM public.igrejas i 
  WHERE i.estado_id = '182c2fcc-122a-4742-99e2-3622a276070c' 
  ORDER BY i.nome 
  LIMIT 1
)
WHERE estado_id = '182c2fcc-122a-4742-99e2-3622a276070c' 
  AND igreja_id IS NULL;

-- PASSO 8: Verificar se a reatribuição funcionou
SELECT 
  'VERIFICAÇÃO APÓS REATRIBUIÇÃO' as tipo,
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
WHERE j.estado_id = '182c2fcc-122a-4742-99e2-3622a276070c'
ORDER BY j.nome_completo;
