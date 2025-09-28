-- Testar a função get_jovens_por_estado_count que já existe
-- Baseado na estrutura real das funções

-- 1. Verificar se a função existe
SELECT '=== VERIFICANDO FUNÇÃO ===' as secao;
SELECT 
  routine_name, 
  routine_type, 
  data_type,
  routine_definition
FROM information_schema.routines 
WHERE routine_name = 'get_jovens_por_estado_count'
AND routine_schema = 'public';

-- 2. Testar a função sem parâmetros
SELECT '=== TESTE 1 - SEM PARÂMETROS ===' as secao;
SELECT * FROM public.get_jovens_por_estado_count();

-- 3. Testar a função com NULL
SELECT '=== TESTE 2 - COM NULL ===' as secao;
SELECT * FROM public.get_jovens_por_estado_count(NULL);

-- 4. Verificar se há edições ativas
SELECT '=== VERIFICANDO EDIÇÕES ===' as secao;
SELECT id, nome, ativa FROM public.edicoes WHERE ativa = true LIMIT 3;

-- 5. Testar com edição específica (se houver)
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

-- 6. Verificar dados básicos
SELECT '=== DADOS BÁSICOS ===' as secao;
SELECT 'Estados:' as info, COUNT(*) as total FROM public.estados;
SELECT 'Jovens:' as info, COUNT(*) as total FROM public.jovens;
SELECT 'Jovens com estado:' as info, COUNT(*) as total FROM public.jovens WHERE estado_id IS NOT NULL;
SELECT 'Edições:' as info, COUNT(*) as total FROM public.edicoes;
SELECT 'Edições ativas:' as info, COUNT(*) as total FROM public.edicoes WHERE ativa = true;
