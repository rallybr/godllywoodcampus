-- =====================================================
-- Script para limpar TODAS as referências quebradas
-- =====================================================

-- PASSO 1: Limpar referências quebradas de blocos
UPDATE public.jovens 
SET bloco_id = NULL
WHERE bloco_id IS NOT NULL 
  AND bloco_id NOT IN (SELECT id FROM public.blocos);

-- PASSO 2: Limpar referências quebradas de regiões
UPDATE public.jovens 
SET regiao_id = NULL
WHERE regiao_id IS NOT NULL 
  AND regiao_id NOT IN (SELECT id FROM public.regioes);

-- PASSO 3: Limpar referências quebradas de igrejas
UPDATE public.jovens 
SET igreja_id = NULL
WHERE igreja_id IS NOT NULL 
  AND igreja_id NOT IN (SELECT id FROM public.igrejas);

-- PASSO 4: Verificar se a limpeza funcionou
SELECT 
  'VERIFICAÇÃO APÓS LIMPEZA' as tipo,
  'Blocos quebrados' as problema,
  COUNT(*) as total
FROM public.jovens j
LEFT JOIN public.blocos b ON b.id = j.bloco_id
WHERE j.bloco_id IS NOT NULL AND b.id IS NULL

UNION ALL

SELECT 
  'VERIFICAÇÃO APÓS LIMPEZA' as tipo,
  'Regiões quebradas' as problema,
  COUNT(*) as total
FROM public.jovens j
LEFT JOIN public.regioes r ON r.id = j.regiao_id
WHERE j.regiao_id IS NOT NULL AND r.id IS NULL

UNION ALL

SELECT 
  'VERIFICAÇÃO APÓS LIMPEZA' as tipo,
  'Igrejas quebradas' as problema,
  COUNT(*) as total
FROM public.jovens j
LEFT JOIN public.igrejas i ON i.id = j.igreja_id
WHERE j.igreja_id IS NOT NULL AND i.id IS NULL;

-- PASSO 5: Mostrar resumo de jovens após limpeza
SELECT 
  'RESUMO APÓS LIMPEZA' as tipo,
  'Total de jovens' as descricao,
  COUNT(*) as total
FROM public.jovens

UNION ALL

SELECT 
  'RESUMO APÓS LIMPEZA' as tipo,
  'Jovens com bloco válido' as descricao,
  COUNT(*) as total
FROM public.jovens j
JOIN public.blocos b ON b.id = j.bloco_id

UNION ALL

SELECT 
  'RESUMO APÓS LIMPEZA' as tipo,
  'Jovens sem bloco' as descricao,
  COUNT(*) as total
FROM public.jovens 
WHERE bloco_id IS NULL;
