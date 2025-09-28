-- CORRIGIR TODOS OS NÍVEIS PARA "jovem"
-- Script para reverter a bagunça e colocar todos como "jovem"

-- 1. ATUALIZAR TODOS OS USUÁRIOS PARA NÍVEL "jovem"
UPDATE public.usuarios 
SET nivel = 'jovem'
WHERE nivel IS NOT NULL;

-- 2. VERIFICAR QUANTOS USUÁRIOS FORAM ATUALIZADOS
SELECT 
  'Usuários atualizados para jovem' as resultado,
  COUNT(*) as total
FROM public.usuarios 
WHERE nivel = 'jovem';

-- 3. VERIFICAR SE AINDA HÁ OUTROS NÍVEIS
SELECT 
  nivel,
  COUNT(*) as quantidade
FROM public.usuarios 
GROUP BY nivel
ORDER BY nivel;

-- 4. MOSTRAR PRIMEIROS 10 USUÁRIOS PARA CONFIRMAR
SELECT 
  id,
  nome,
  email,
  nivel,
  ativo
FROM public.usuarios 
ORDER BY criado_em DESC
LIMIT 10;
