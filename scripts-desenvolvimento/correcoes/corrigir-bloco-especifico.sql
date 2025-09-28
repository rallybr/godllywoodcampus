-- =====================================================
-- Script para corrigir o bloco específico problemático
-- =====================================================

-- PASSO 1: Limpar APENAS as referências ao bloco problemático
UPDATE public.jovens 
SET bloco_id = NULL
WHERE bloco_id = 'b8966b59-b4a2-5672-a540-6fd6beb5d1d4';

-- PASSO 2: Verificar se a limpeza funcionou
SELECT 
  'VERIFICAÇÃO APÓS LIMPEZA' as tipo,
  COUNT(*) as jovens_com_bloco_problematico
FROM public.jovens 
WHERE bloco_id = 'b8966b59-b4a2-5672-a540-6fd6beb5d1d4';

-- PASSO 3: Mostrar quais jovens foram afetados
SELECT 
  'JOVENS AFETADOS PELA LIMPEZA' as tipo,
  j.id as jovem_id,
  j.nome_completo,
  j.estado_id,
  e.nome as estado_nome
FROM public.jovens j
LEFT JOIN public.estados e ON e.id = j.estado_id
WHERE j.bloco_id IS NULL
  AND j.nome_completo IN (
    SELECT nome_completo 
    FROM public.jovens 
    WHERE bloco_id = 'b8966b59-b4a2-5672-a540-6fd6beb5d1d4'
  )
ORDER BY j.nome_completo;

-- PASSO 4: Verificar se há outras referências quebradas
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
