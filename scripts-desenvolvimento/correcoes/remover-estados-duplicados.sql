-- =====================================================
-- Script para remover estados duplicados
-- =====================================================

-- Verificar duplicatas antes da remoção
SELECT 
  nome, 
  sigla, 
  COUNT(*) as quantidade,
  array_agg(id) as ids
FROM public.estados 
GROUP BY nome, sigla 
HAVING COUNT(*) > 1
ORDER BY nome;

-- Remover duplicatas de Minas Gerais (MG)
-- Manter apenas o primeiro registro: 182c2fcc-122a-4742-99e2-3622a276070c
DELETE FROM public.estados WHERE id = '3373645f-f666-5b4e-a0b0-3556f45a0cc2';

-- Remover duplicatas de Rio de Janeiro (RJ)  
-- Manter apenas o primeiro registro: 7e391556-c53e-5215-9d4a-3a0367c149ca
DELETE FROM public.estados WHERE id = 'f20fe338-cb61-4475-863f-a964f06af006';

-- Verificar se as duplicatas foram removidas
SELECT 
  nome, 
  sigla, 
  COUNT(*) as quantidade
FROM public.estados 
GROUP BY nome, sigla 
HAVING COUNT(*) > 1
ORDER BY nome;

-- Mostrar total de estados após limpeza
SELECT COUNT(*) as total_estados FROM public.estados;
