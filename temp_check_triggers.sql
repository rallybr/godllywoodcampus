-- Verificar triggers na tabela aprovacoes_jovens
SELECT 
  trigger_name, 
  event_manipulation, 
  action_statement 
FROM information_schema.triggers 
WHERE event_object_table = 'aprovacoes_jovens';
