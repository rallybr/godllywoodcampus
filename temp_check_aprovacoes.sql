-- Verificar estrutura da tabela aprovacoes_jovens
SELECT 
  column_name, 
  data_type 
FROM information_schema.columns 
WHERE table_name = 'aprovacoes_jovens' 
  AND table_schema = 'public'
ORDER BY ordinal_position;
