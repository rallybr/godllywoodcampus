-- =====================================================
-- Script para corrigir o bloco Varginha problemático
-- =====================================================

-- PASSO 1: Verificar qual jovem está vinculado ao bloco Varginha
SELECT 
  'JOVEM VINCULADO AO BLOCO VARGINHA' as tipo,
  j.id as jovem_id,
  j.nome_completo,
  j.bloco_id,
  j.estado_id,
  e.nome as estado_nome
FROM public.jovens j
LEFT JOIN public.estados e ON e.id = j.estado_id
WHERE j.bloco_id = 'fde25235-7cd7-5935-9113-918e269a32f3';

-- PASSO 2: Limpar a referência quebrada (definir bloco_id como NULL)
UPDATE public.jovens 
SET bloco_id = NULL
WHERE bloco_id = 'fde25235-7cd7-5935-9113-918e269a32f3';

-- PASSO 3: Verificar se a limpeza funcionou
SELECT 
  'VERIFICAÇÃO APÓS LIMPEZA' as tipo,
  COUNT(*) as jovens_com_bloco_varginha
FROM public.jovens 
WHERE bloco_id = 'fde25235-7cd7-5935-9113-918e269a32f3';

-- PASSO 4: Agora remover o bloco Varginha com segurança
DELETE FROM public.blocos 
WHERE id = 'fde25235-7cd7-5935-9113-918e269a32f3';

-- PASSO 5: Verificar se o bloco foi removido
SELECT 
  'VERIFICAÇÃO FINAL' as tipo,
  COUNT(*) as blocos_varginha_restantes
FROM public.blocos 
WHERE id = 'fde25235-7cd7-5935-9113-918e269a32f3';

-- PASSO 6: Verificar se há outras referências quebradas
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
