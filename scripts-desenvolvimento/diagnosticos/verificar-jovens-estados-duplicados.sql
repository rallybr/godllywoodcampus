-- =====================================================
-- Script para verificar jovens nos estados duplicados
-- =====================================================

-- Verificar duplicatas de estados
SELECT 
  nome, 
  sigla, 
  COUNT(*) as quantidade,
  array_agg(id ORDER BY id) as ids_ordenados
FROM public.estados 
GROUP BY nome, sigla 
HAVING COUNT(*) > 1
ORDER BY nome;

-- Verificar jovens em Minas Gerais (ambos os IDs)
SELECT 
  'Minas Gerais - ID 1 (manter)' as status,
  e.id as estado_id,
  e.nome,
  e.sigla,
  COUNT(j.id) as total_jovens
FROM public.estados e
LEFT JOIN public.jovens j ON j.estado_id = e.id
WHERE e.id = '182c2fcc-122a-4742-99e2-3622a276070c'
GROUP BY e.id, e.nome, e.sigla

UNION ALL

SELECT 
  'Minas Gerais - ID 2 (remover)' as status,
  e.id as estado_id,
  e.nome,
  e.sigla,
  COUNT(j.id) as total_jovens
FROM public.estados e
LEFT JOIN public.jovens j ON j.estado_id = e.id
WHERE e.id = '3373645f-f666-5b4e-a0b0-3556f45a0cc2'
GROUP BY e.id, e.nome, e.sigla;

-- Verificar jovens em Rio de Janeiro (ambos os IDs)
SELECT 
  'Rio de Janeiro - ID 1 (manter)' as status,
  e.id as estado_id,
  e.nome,
  e.sigla,
  COUNT(j.id) as total_jovens
FROM public.estados e
LEFT JOIN public.jovens j ON j.estado_id = e.id
WHERE e.id = '7e391556-c53e-5215-9d4a-3a0367c149ca'
GROUP BY e.id, e.nome, e.sigla

UNION ALL

SELECT 
  'Rio de Janeiro - ID 2 (remover)' as status,
  e.id as estado_id,
  e.nome,
  e.sigla,
  COUNT(j.id) as total_jovens
FROM public.estados e
LEFT JOIN public.jovens j ON j.estado_id = e.id
WHERE e.id = 'f20fe338-cb61-4475-863f-a964f06af006'
GROUP BY e.id, e.nome, e.sigla;

-- Listar jovens específicos nos estados que serão removidos
SELECT 
  'JOVENS NO ESTADO QUE SERÁ REMOVIDO - MINAS GERAIS' as aviso,
  j.id as jovem_id,
  j.nome_completo,
  j.estado_id
FROM public.jovens j
WHERE j.estado_id = '3373645f-f666-5b4e-a0b0-3556f45a0cc2'
ORDER BY j.nome_completo;

SELECT 
  'JOVENS NO ESTADO QUE SERÁ REMOVIDO - RIO DE JANEIRO' as aviso,
  j.id as jovem_id,
  j.nome_completo,
  j.estado_id
FROM public.jovens j
WHERE j.estado_id = 'f20fe338-cb61-4475-863f-a964f06af006'
ORDER BY j.nome_completo;

-- Resumo final
SELECT 
  'RESUMO FINAL' as tipo,
  'Minas Gerais - ID a manter' as estado,
  COUNT(j.id) as total_jovens
FROM public.jovens j
WHERE j.estado_id = '182c2fcc-122a-4742-99e2-3622a276070c'

UNION ALL

SELECT 
  'RESUMO FINAL' as tipo,
  'Minas Gerais - ID a remover' as estado,
  COUNT(j.id) as total_jovens
FROM public.jovens j
WHERE j.estado_id = '3373645f-f666-5b4e-a0b0-3556f45a0cc2'

UNION ALL

SELECT 
  'RESUMO FINAL' as tipo,
  'Rio de Janeiro - ID a manter' as estado,
  COUNT(j.id) as total_jovens
FROM public.jovens j
WHERE j.estado_id = '7e391556-c53e-5215-9d4a-3a0367c149ca'

UNION ALL

SELECT 
  'RESUMO FINAL' as tipo,
  'Rio de Janeiro - ID a remover' as estado,
  COUNT(j.id) as total_jovens
FROM public.jovens j
WHERE j.estado_id = 'f20fe338-cb61-4475-863f-a964f06af006';
