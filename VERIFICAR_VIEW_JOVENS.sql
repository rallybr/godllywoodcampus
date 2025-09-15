-- Verificar se a view jovens_view tem as colunas sexo e whatsapp
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'jovens_view' 
  AND column_name IN ('sexo', 'whatsapp', 'nome_completo', 'edicao')
ORDER BY column_name;

-- Verificar se a tabela jovens tem essas colunas
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'jovens' 
  AND column_name IN ('sexo', 'whatsapp', 'nome_completo', 'edicao')
ORDER BY column_name;
