-- Verificar a função trigger_notificar_mudanca_status
SELECT 
  routine_name,
  routine_type,
  routine_definition
FROM information_schema.routines 
WHERE routine_name = 'trigger_notificar_mudanca_status'
AND routine_schema = 'public';

-- Verificar a função trigger_notificar_novo_cadastro
SELECT 
  routine_name,
  routine_type,
  routine_definition
FROM information_schema.routines 
WHERE routine_name = 'trigger_notificar_novo_cadastro'
AND routine_schema = 'public';
