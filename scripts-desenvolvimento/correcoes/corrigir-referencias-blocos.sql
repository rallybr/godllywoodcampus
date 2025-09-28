-- =====================================================
-- Script para corrigir referências quebradas de blocos
-- =====================================================

-- PASSO 1: Verificar o problema específico
SELECT 
  'DIAGNÓSTICO - BLOCO PROBLEMÁTICO' as tipo,
  b.id as bloco_id,
  b.nome as bloco_nome,
  COUNT(j.id) as jovens_vinculados
FROM public.blocos b
LEFT JOIN public.jovens j ON j.bloco_id = b.id
WHERE b.id = 'fde25235-7cd7-5935-9113-918e269a32f3'
GROUP BY b.id, b.nome;

-- PASSO 2: Listar jovens que referenciam o bloco problemático
SELECT 
  'JOVENS VINCULADOS AO BLOCO PROBLEMÁTICO' as tipo,
  j.id as jovem_id,
  j.nome_completo,
  j.bloco_id,
  j.estado_id,
  e.nome as estado_nome
FROM public.jovens j
LEFT JOIN public.estados e ON e.id = j.estado_id
WHERE j.bloco_id = 'fde25235-7cd7-5935-9113-918e269a32f3'
ORDER BY j.nome_completo;

-- PASSO 3: Opção 1 - Limpar referências quebradas (definir como NULL)
UPDATE public.jovens 
SET bloco_id = NULL
WHERE bloco_id = 'fde25235-7cd7-5935-9113-918e269a32f3';

-- PASSO 4: Verificar se a limpeza funcionou
SELECT 
  'VERIFICAÇÃO APÓS LIMPEZA' as tipo,
  COUNT(*) as jovens_com_bloco_problematico
FROM public.jovens 
WHERE bloco_id = 'fde25235-7cd7-5935-9113-918e269a32f3';

-- PASSO 5: Agora tentar remover o bloco novamente
-- (Este comando deve ser executado separadamente após verificar que não há mais referências)
-- DELETE FROM public.blocos WHERE id = 'fde25235-7cd7-5935-9113-918e269a32f3';

-- PASSO 6: Verificar outras referências quebradas
SELECT 
  'OUTRAS REFERÊNCIAS QUEBRADAS' as tipo,
  'Blocos' as tabela,
  COUNT(*) as total
FROM public.jovens j
LEFT JOIN public.blocos b ON b.id = j.bloco_id
WHERE j.bloco_id IS NOT NULL AND b.id IS NULL

UNION ALL

SELECT 
  'OUTRAS REFERÊNCIAS QUEBRADAS' as tipo,
  'Regiões' as tabela,
  COUNT(*) as total
FROM public.jovens j
LEFT JOIN public.regioes r ON r.id = j.regiao_id
WHERE j.regiao_id IS NOT NULL AND r.id IS NULL

UNION ALL

SELECT 
  'OUTRAS REFERÊNCIAS QUEBRADAS' as tipo,
  'Igrejas' as tabela,
  COUNT(*) as total
FROM public.jovens j
LEFT JOIN public.igrejas i ON i.id = j.igreja_id
WHERE j.igreja_id IS NOT NULL AND i.id IS NULL;
