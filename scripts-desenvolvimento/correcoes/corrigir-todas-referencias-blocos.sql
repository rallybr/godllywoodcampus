-- =====================================================
-- Script para corrigir TODAS as referências quebradas de blocos
-- =====================================================

-- PASSO 1: Encontrar TODOS os blocos que têm jovens referenciando mas não existem
SELECT 
  'BLOCO PROBLEMÁTICO' as tipo,
  b.id as bloco_id,
  b.nome as bloco_nome,
  COUNT(j.id) as jovens_vinculados
FROM public.blocos b
LEFT JOIN public.jovens j ON j.bloco_id = b.id
WHERE b.id IN (
  SELECT DISTINCT j.bloco_id 
  FROM public.jovens j 
  WHERE j.bloco_id IS NOT NULL
)
GROUP BY b.id, b.nome
HAVING COUNT(j.id) > 0
ORDER BY b.nome;

-- PASSO 2: Encontrar jovens que referenciam blocos inexistentes
SELECT 
  'JOVENS COM BLOCOS INEXISTENTES' as problema,
  j.id as jovem_id,
  j.nome_completo,
  j.bloco_id,
  b.nome as bloco_nome
FROM public.jovens j
LEFT JOIN public.blocos b ON b.id = j.bloco_id
WHERE j.bloco_id IS NOT NULL 
  AND b.id IS NULL
ORDER BY j.nome_completo;

-- PASSO 3: Limpar TODAS as referências quebradas de blocos
UPDATE public.jovens 
SET bloco_id = NULL
WHERE bloco_id IS NOT NULL 
  AND bloco_id NOT IN (SELECT id FROM public.blocos);

-- PASSO 4: Verificar se a limpeza funcionou
SELECT 
  'VERIFICAÇÃO APÓS LIMPEZA - BLOCOS' as tipo,
  COUNT(*) as jovens_com_blocos_inexistentes
FROM public.jovens j
LEFT JOIN public.blocos b ON b.id = j.bloco_id
WHERE j.bloco_id IS NOT NULL AND b.id IS NULL;

-- PASSO 5: Limpar referências quebradas de regiões
UPDATE public.jovens 
SET regiao_id = NULL
WHERE regiao_id IS NOT NULL 
  AND regiao_id NOT IN (SELECT id FROM public.regioes);

-- PASSO 6: Limpar referências quebradas de igrejas
UPDATE public.jovens 
SET igreja_id = NULL
WHERE igreja_id IS NOT NULL 
  AND igreja_id NOT IN (SELECT id FROM public.igrejas);

-- PASSO 7: Verificação final de todas as referências
SELECT 
  'VERIFICAÇÃO FINAL' as tipo,
  'Blocos quebrados' as problema,
  COUNT(*) as total
FROM public.jovens j
LEFT JOIN public.blocos b ON b.id = j.bloco_id
WHERE j.bloco_id IS NOT NULL AND b.id IS NULL

UNION ALL

SELECT 
  'VERIFICAÇÃO FINAL' as tipo,
  'Regiões quebradas' as problema,
  COUNT(*) as total
FROM public.jovens j
LEFT JOIN public.regioes r ON r.id = j.regiao_id
WHERE j.regiao_id IS NOT NULL AND r.id IS NULL

UNION ALL

SELECT 
  'VERIFICAÇÃO FINAL' as tipo,
  'Igrejas quebradas' as problema,
  COUNT(*) as total
FROM public.jovens j
LEFT JOIN public.igrejas i ON i.id = j.igreja_id
WHERE j.igreja_id IS NOT NULL AND i.id IS NULL;

-- PASSO 8: Mostrar resumo de jovens com referências limpas
SELECT 
  'RESUMO FINAL' as tipo,
  'Total de jovens' as descricao,
  COUNT(*) as total
FROM public.jovens

UNION ALL

SELECT 
  'RESUMO FINAL' as tipo,
  'Jovens com bloco válido' as descricao,
  COUNT(*) as total
FROM public.jovens j
JOIN public.blocos b ON b.id = j.bloco_id

UNION ALL

SELECT 
  'RESUMO FINAL' as tipo,
  'Jovens sem bloco' as descricao,
  COUNT(*) as total
FROM public.jovens 
WHERE bloco_id IS NULL;
