-- Script completo para testar e corrigir o card JOVENS POR ESTADO
-- Baseado na estrutura real das tabelas

-- 1. Verificar se há dados nas tabelas principais
SELECT '=== VERIFICANDO DADOS ===' as secao;

SELECT 'Estados cadastrados:' as info, COUNT(*) as total FROM public.estados;
SELECT 'Jovens cadastrados:' as info, COUNT(*) as total FROM public.jovens;
SELECT 'Jovens com estado_id:' as info, COUNT(*) as total FROM public.jovens WHERE estado_id IS NOT NULL;
SELECT 'Edições cadastradas:' as info, COUNT(*) as total FROM public.edicoes;
SELECT 'Edição ativa:' as info, COUNT(*) as total FROM public.edicoes WHERE ativa = true;

-- 2. Verificar alguns dados de exemplo
SELECT '=== DADOS DE EXEMPLO ===' as secao;

SELECT 'Primeiros 3 estados:' as info;
SELECT id, nome, sigla, bandeira FROM public.estados LIMIT 3;

SELECT 'Primeiros 3 jovens:' as info;
SELECT id, nome_completo, estado_id, edicao_id FROM public.jovens LIMIT 3;

-- 3. Verificar contagem atual por estado
SELECT '=== CONTAGEM ATUAL POR ESTADO ===' as secao;
SELECT 
  e.nome as estado_nome,
  e.sigla,
  e.bandeira,
  COUNT(j.id) as total_jovens
FROM public.estados e
LEFT JOIN public.jovens j ON e.id = j.estado_id
GROUP BY e.id, e.nome, e.sigla, e.bandeira
ORDER BY total_jovens DESC
LIMIT 10;

-- 4. Corrigir função RPC
SELECT '=== CRIANDO FUNÇÃO RPC ===' as secao;

-- Dropar função existente
DROP FUNCTION IF EXISTS public.get_jovens_por_estado_count(uuid);

-- Criar função corrigida
CREATE OR REPLACE FUNCTION public.get_jovens_por_estado_count(p_edicao_id uuid DEFAULT NULL)
RETURNS TABLE (
  estado_id uuid,
  total bigint
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    j.estado_id,
    COUNT(*) as total
  FROM public.jovens j
  WHERE j.estado_id IS NOT NULL
    AND (p_edicao_id IS NULL OR j.edicao_id = p_edicao_id)
  GROUP BY j.estado_id;
END;
$$;

-- 5. Testar a função
SELECT '=== TESTANDO FUNÇÃO RPC ===' as secao;

SELECT 'Teste 1 - Sem parâmetros:' as teste;
SELECT * FROM public.get_jovens_por_estado_count();

SELECT 'Teste 2 - Com NULL:' as teste;
SELECT * FROM public.get_jovens_por_estado_count(NULL);

-- 6. Verificar se há edição ativa para testar com parâmetro
SELECT '=== TESTANDO COM EDIÇÃO ESPECÍFICA ===' as secao;

-- Buscar primeira edição ativa
SELECT 'Edição ativa encontrada:' as info, id, nome FROM public.edicoes WHERE ativa = true LIMIT 1;

-- Se houver edição ativa, testar com ela
DO $$
DECLARE
  edicao_ativa_id uuid;
BEGIN
  SELECT id INTO edicao_ativa_id FROM public.edicoes WHERE ativa = true LIMIT 1;
  
  IF edicao_ativa_id IS NOT NULL THEN
    RAISE NOTICE 'Testando com edição ativa: %', edicao_ativa_id;
    PERFORM * FROM public.get_jovens_por_estado_count(edicao_ativa_id);
  ELSE
    RAISE NOTICE 'Nenhuma edição ativa encontrada';
  END IF;
END $$;

-- 7. Verificar se a função foi criada corretamente
SELECT '=== VERIFICANDO FUNÇÃO CRIADA ===' as secao;
SELECT 
  routine_name, 
  routine_type, 
  data_type,
  routine_definition
FROM information_schema.routines 
WHERE routine_name = 'get_jovens_por_estado_count'
AND routine_schema = 'public';
