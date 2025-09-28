-- =====================================================
-- Script para verificar o bloco específico problemático
-- =====================================================

-- PASSO 1: Verificar o bloco específico que está causando erro
SELECT 
  'BLOCO PROBLEMÁTICO ESPECÍFICO' as tipo,
  b.id,
  b.nome,
  COUNT(j.id) as total_jovens
FROM public.blocos b
LEFT JOIN public.jovens j ON j.bloco_id = b.id
WHERE b.id = 'b8966b59-b4a2-5672-a540-6fd6beb5d1d4'
GROUP BY b.id, b.nome;

-- PASSO 2: Listar TODOS os jovens que referenciam este bloco
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

-- PASSO 3: Verificar se este bloco existe na tabela blocos
SELECT 
  'VERIFICAÇÃO - BLOCO EXISTE?' as tipo,
  CASE 
    WHEN EXISTS (SELECT 1 FROM public.blocos WHERE id = 'b8966b59-b4a2-5672-a540-6fd6beb5d1d4') 
    THEN 'SIM - Bloco existe'
    ELSE 'NÃO - Bloco não existe'
  END as status;

-- PASSO 4: Contar total de jovens com este bloco
SELECT 
  'TOTAL DE JOVENS COM ESTE BLOCO' as tipo,
  COUNT(*) as total
FROM public.jovens 
WHERE bloco_id = 'b8966b59-b4a2-5672-a540-6fd6beb5d1d4';
