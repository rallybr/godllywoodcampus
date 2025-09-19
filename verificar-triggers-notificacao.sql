-- Verificar triggers na tabela jovens
SELECT 
  trigger_name,
  event_manipulation,
  action_timing,
  action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'jovens'
ORDER BY trigger_name;

-- Verificar se existe função trigger_notificar_mudanca_status
SELECT 
  routine_name,
  routine_type,
  routine_definition
FROM information_schema.routines 
WHERE routine_name LIKE '%notificar%' 
AND routine_schema = 'public';

-- Verificar se existe função notificar_lideres
SELECT 
  routine_name,
  routine_type,
  routine_definition
FROM information_schema.routines 
WHERE routine_name LIKE '%lideres%' 
AND routine_schema = 'public';

-- Verificar logs de auditoria recentes para ver se há tentativas de criar notificações
SELECT 
  acao,
  detalhe
FROM public.logs_historico 
WHERE acao LIKE '%notific%' 
ORDER BY id DESC 
LIMIT 10;
