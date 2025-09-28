-- Verificar se a função trigger_notificar_mudanca_status existe
SELECT 
  routine_name,
  routine_type,
  routine_definition
FROM information_schema.routines 
WHERE routine_name = 'trigger_notificar_mudanca_status'
AND routine_schema = 'public';

-- Se não existir, verificar todas as funções que contêm "mudanca" ou "status"
SELECT 
  routine_name,
  routine_type,
  routine_definition
FROM information_schema.routines 
WHERE routine_name LIKE '%mudanca%' 
OR routine_name LIKE '%status%'
AND routine_schema = 'public';

-- Verificar se há alguma função que chama notificar_lideres com tipo inválido
SELECT 
  routine_name,
  routine_definition
FROM information_schema.routines 
WHERE routine_definition LIKE '%notificar_lideres%'
AND routine_schema = 'public';
