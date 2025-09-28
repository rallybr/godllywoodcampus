-- Script para adicionar a nova coluna "condicao_campus" na tabela jovens
-- Esta coluna armazenará a condição do jovem quando foi para o Campus

-- Adicionar a nova coluna
ALTER TABLE jovens 
ADD COLUMN condicao_campus TEXT;

-- Adicionar comentário para documentar a coluna
COMMENT ON COLUMN jovens.condicao_campus IS 'Condição do jovem quando foi para o Campus (para acompanhar evolução)';

-- Verificar se a coluna foi criada corretamente
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'jovens' 
AND column_name = 'condicao_campus';
