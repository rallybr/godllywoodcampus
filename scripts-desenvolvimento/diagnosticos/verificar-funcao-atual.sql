-- VERIFICAR SE A FUNÇÃO FOI ATUALIZADA
-- Este script mostra a definição atual da função

SELECT 
    'Definição atual da função get_jovens_por_estado_count:' as info,
    pg_get_functiondef(oid) as definicao
FROM pg_proc 
WHERE proname = 'get_jovens_por_estado_count' 
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- Se a função não foi atualizada, você verá a versão antiga
-- Se foi atualizada, você verá a lógica hierárquica com IF/ELSIF