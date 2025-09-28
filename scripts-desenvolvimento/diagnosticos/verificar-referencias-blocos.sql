-- =====================================================
-- Script para verificar referências de blocos em jovens
-- =====================================================

-- Verificar se há jovens referenciando blocos inexistentes
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

-- Verificar se há jovens referenciando regiões inexistentes
SELECT 
  'JOVENS COM REGIÕES INEXISTENTES' as problema,
  j.id as jovem_id,
  j.nome_completo,
  j.regiao_id,
  r.nome as regiao_nome
FROM public.jovens j
LEFT JOIN public.regioes r ON r.id = j.regiao_id
WHERE j.regiao_id IS NOT NULL 
  AND r.id IS NULL
ORDER BY j.nome_completo;

-- Verificar se há jovens referenciando igrejas inexistentes
SELECT 
  'JOVENS COM IGREJAS INEXISTENTES' as problema,
  j.id as jovem_id,
  j.nome_completo,
  j.igreja_id,
  i.nome as igreja_nome
FROM public.jovens j
LEFT JOIN public.igrejas i ON i.id = j.igreja_id
WHERE j.igreja_id IS NOT NULL 
  AND i.id IS NULL
ORDER BY j.nome_completo;

-- Contar total de jovens com referências quebradas
SELECT 
  'RESUMO DE REFERÊNCIAS QUEBRADAS' as tipo,
  'Blocos inexistentes' as problema,
  COUNT(*) as total
FROM public.jovens j
LEFT JOIN public.blocos b ON b.id = j.bloco_id
WHERE j.bloco_id IS NOT NULL AND b.id IS NULL

UNION ALL

SELECT 
  'RESUMO DE REFERÊNCIAS QUEBRADAS' as tipo,
  'Regiões inexistentes' as problema,
  COUNT(*) as total
FROM public.jovens j
LEFT JOIN public.regioes r ON r.id = j.regiao_id
WHERE j.regiao_id IS NOT NULL AND r.id IS NULL

UNION ALL

SELECT 
  'RESUMO DE REFERÊNCIAS QUEBRADAS' as tipo,
  'Igrejas inexistentes' as problema,
  COUNT(*) as total
FROM public.jovens j
LEFT JOIN public.igrejas i ON i.id = j.igreja_id
WHERE j.igreja_id IS NOT NULL AND i.id IS NULL;

-- Verificar o bloco específico que está causando erro
SELECT 
  'BLOCO PROBLEMÁTICO' as tipo,
  b.id,
  b.nome,
  COUNT(j.id) as total_jovens
FROM public.blocos b
LEFT JOIN public.jovens j ON j.bloco_id = b.id
WHERE b.id = 'fde25235-7cd7-5935-9113-918e269a32f3'
GROUP BY b.id, b.nome;
