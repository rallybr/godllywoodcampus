-- =====================================================
-- Script para verificar TODAS as referências quebradas
-- =====================================================

-- PASSO 1: Verificar jovens com blocos inexistentes
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

-- PASSO 2: Verificar jovens com regiões inexistentes
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

-- PASSO 3: Verificar jovens com igrejas inexistentes
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

-- PASSO 4: Contar total de referências quebradas
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

-- PASSO 5: Verificar o bloco específico que está causando erro
SELECT 
  'BLOCO PROBLEMÁTICO ESPECÍFICO' as tipo,
  b.id,
  b.nome,
  COUNT(j.id) as total_jovens
FROM public.blocos b
LEFT JOIN public.jovens j ON j.bloco_id = b.id
WHERE b.id = 'b8966b59-b4a2-5672-a540-6fd6beb5d1d4'
GROUP BY b.id, b.nome;

-- PASSO 6: Listar jovens que referenciam o bloco problemático
SELECT 
  'JOVENS VINCULADOS AO BLOCO PROBLEMÁTICO' as tipo,
  j.id as jovem_id,
  j.nome_completo,
  j.bloco_id,
  j.estado_id,
  e.nome as estado_nome
FROM public.jovens j
LEFT JOIN public.estados e ON e.id = j.estado_id
WHERE j.bloco_id = 'b8966b59-b4a2-5672-a540-6fd6beb5d1d4'
ORDER BY j.nome_completo;
