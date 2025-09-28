-- =====================================================
-- Script para migrar estados APÓS limpeza de referências
-- =====================================================

-- PASSO 1: Verificar os jovens de Minas Gerais que serão migrados
SELECT 
  'JOVENS DE MINAS GERAIS A MIGRAR' as tipo,
  j.id as jovem_id,
  j.nome_completo,
  j.estado_id,
  j.bloco_id,
  j.regiao_id,
  j.igreja_id
FROM public.jovens j
WHERE j.estado_id = '3373645f-f666-5b4e-a0b0-3556f45a0cc2'  -- ID a remover
ORDER BY j.nome_completo;

-- PASSO 2: Migrar jovens de Minas Gerais
UPDATE public.jovens 
SET estado_id = '182c2fcc-122a-4742-99e2-3622a276070c'  -- ID a manter
WHERE estado_id = '3373645f-f666-5b4e-a0b0-3556f45a0cc2';  -- ID a remover

-- PASSO 3: Verificar se a migração foi bem-sucedida
SELECT 
  'Verificação - Minas Gerais após migração' as status,
  COUNT(*) as total_jovens
FROM public.jovens 
WHERE estado_id = '182c2fcc-122a-4742-99e2-3622a276070c';

-- PASSO 4: Verificar se o ID a remover está vazio
SELECT 
  'Verificação - Minas Gerais ID a remover' as status,
  COUNT(*) as total_jovens
FROM public.jovens 
WHERE estado_id = '3373645f-f666-5b4e-a0b0-3556f45a0cc2';

-- PASSO 5: Agora remover as duplicatas com segurança
-- Remover Minas Gerais duplicado (após migração)
DELETE FROM public.estados 
WHERE id = '3373645f-f666-5b4e-a0b0-3556f45a0cc2';

-- Remover Rio de Janeiro duplicado (já estava vazio)
DELETE FROM public.estados 
WHERE id = 'f20fe338-cb61-4475-863f-a964f06af006';

-- PASSO 6: Verificação final
-- Verificar se não há mais duplicatas
SELECT 
  nome, 
  sigla, 
  COUNT(*) as quantidade
FROM public.estados 
GROUP BY nome, sigla 
HAVING COUNT(*) > 1
ORDER BY nome;

-- Contar total de estados após limpeza
SELECT COUNT(*) as total_estados FROM public.estados;

-- Verificar jovens em Minas Gerais após migração
SELECT 
  'Minas Gerais - Final' as status,
  COUNT(*) as total_jovens
FROM public.jovens 
WHERE estado_id = '182c2fcc-122a-4742-99e2-3622a276070c';

-- Verificar jovens em Rio de Janeiro
SELECT 
  'Rio de Janeiro - Final' as status,
  COUNT(*) as total_jovens
FROM public.jovens 
WHERE estado_id = '7e391556-c53e-5215-9d4a-3a0367c149ca';
