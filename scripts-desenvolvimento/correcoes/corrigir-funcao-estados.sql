-- Corrigir a função get_jovens_por_estado_count
-- O problema é que ela usa p_edicao_id na query, mas o parâmetro é edicao_id

-- Primeiro, dropar a função existente
DROP FUNCTION IF EXISTS public.get_jovens_por_estado_count(uuid);

-- Criar a função corrigida
CREATE OR REPLACE FUNCTION public.get_jovens_por_estado_count(edicao_id uuid DEFAULT NULL)
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
    AND (edicao_id IS NULL OR j.edicao_id = edicao_id)
  GROUP BY j.estado_id;
END;
$$;

-- Testar a função corrigida
SELECT '=== TESTANDO FUNÇÃO CORRIGIDA ===' as secao;

SELECT 'Teste 1 - Sem parâmetros:' as teste;
SELECT * FROM public.get_jovens_por_estado_count();

SELECT 'Teste 2 - Com NULL:' as teste;
SELECT * FROM public.get_jovens_por_estado_count(NULL);

-- Verificar se há edições ativas para testar com parâmetro específico
SELECT '=== VERIFICANDO EDIÇÕES ATIVAS ===' as secao;
SELECT id, nome, ativa FROM public.edicoes WHERE ativa = true LIMIT 3;

-- Testar com edição específica se houver
DO $$
DECLARE
  edicao_ativa_id uuid;
  resultado record;
BEGIN
  SELECT id INTO edicao_ativa_id FROM public.edicoes WHERE ativa = true LIMIT 1;
  
  IF edicao_ativa_id IS NOT NULL THEN
    RAISE NOTICE '=== TESTE 3 - COM EDIÇÃO ESPECÍFICA ===';
    RAISE NOTICE 'Edição ativa: %', edicao_ativa_id;
    
    FOR resultado IN 
      SELECT * FROM public.get_jovens_por_estado_count(edicao_ativa_id)
    LOOP
      RAISE NOTICE 'Estado: %, Total: %', resultado.estado_id, resultado.total;
    END LOOP;
  ELSE
    RAISE NOTICE 'Nenhuma edição ativa encontrada';
  END IF;
END $$;

-- Verificar dados básicos
SELECT '=== DADOS BÁSICOS ===' as secao;
SELECT 'Estados:' as info, COUNT(*) as total FROM public.estados;
SELECT 'Jovens:' as info, COUNT(*) as total FROM public.jovens;
SELECT 'Jovens com estado:' as info, COUNT(*) as total FROM public.jovens WHERE estado_id IS NOT NULL;
SELECT 'Edições:' as info, COUNT(*) as total FROM public.edicoes;
SELECT 'Edições ativas:' as info, COUNT(*) as total FROM public.edicoes WHERE ativa = true;
