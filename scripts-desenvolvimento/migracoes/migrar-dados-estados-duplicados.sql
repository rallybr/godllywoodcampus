-- =====================================================
-- Script para migrar dados antes de remover duplicatas
-- =====================================================

-- PASSO 1: Migrar jovens de Minas Gerais
-- Mover os 8 jovens do ID que será removido para o ID que será mantido
UPDATE public.jovens 
SET estado_id = '182c2fcc-122a-4742-99e2-3622a276070c'  -- ID a manter
WHERE estado_id = '3373645f-f666-5b4e-a0b0-3556f45a0cc2';  -- ID a remover

-- Verificar se a migração foi bem-sucedida
SELECT 
  'Verificação - Minas Gerais após migração' as status,
  COUNT(*) as total_jovens
FROM public.jovens 
WHERE estado_id = '182c2fcc-122a-4742-99e2-3622a276070c';

-- Verificar se o ID a remover está vazio
SELECT 
  'Verificação - Minas Gerais ID a remover' as status,
  COUNT(*) as total_jovens
FROM public.jovens 
WHERE estado_id = '3373645f-f666-5b4e-a0b0-3556f45a0cc2';

-- PASSO 2: Rio de Janeiro está OK (ID a remover já tem 0 jovens)
-- Não precisa migrar nada para Rio de Janeiro

-- PASSO 3: Agora podemos remover as duplicatas com segurança
-- Remover Minas Gerais duplicado (após migração)
DELETE FROM public.estados 
WHERE id = '3373645f-f666-5b4e-a0b0-3556f45a0cc2';

-- Remover Rio de Janeiro duplicado (já estava vazio)
DELETE FROM public.estados 
WHERE id = 'f20fe338-cb61-4475-863f-a964f06af006';

-- PASSO 4: Verificação final
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
