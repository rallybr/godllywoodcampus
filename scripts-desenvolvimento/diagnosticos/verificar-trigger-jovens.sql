-- Verificar triggers na tabela jovens
SELECT 
  trigger_name,
  event_manipulation,
  action_timing,
  action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'jovens'
ORDER BY trigger_name;

-- Verificar se existe trigger específico para mudança de status
SELECT 
  trigger_name,
  event_manipulation,
  action_timing,
  action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'jovens'
AND action_statement LIKE '%notificar%'
ORDER BY trigger_name;
