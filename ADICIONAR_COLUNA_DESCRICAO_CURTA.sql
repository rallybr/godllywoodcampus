-- Script para adicionar a nova coluna "descricao_curta" na tabela jovens
-- Esta coluna armazenará uma descrição curta (máximo 144 caracteres) para exibição nos cards do relatório

-- Adicionar a nova coluna
ALTER TABLE public.jovens 
ADD COLUMN IF NOT EXISTS descricao_curta TEXT;

-- Adicionar constraint para limitar o tamanho a 144 caracteres
ALTER TABLE public.jovens
ADD CONSTRAINT descricao_curta_max_length 
CHECK (LENGTH(descricao_curta) <= 144);

-- Adicionar comentário para documentar a coluna
COMMENT ON COLUMN public.jovens.descricao_curta IS 'Descrição curta do jovem para exibição nos cards do relatório (máximo 144 caracteres)';

-- Verificar se a coluna foi criada corretamente
SELECT column_name, data_type, is_nullable, column_default, character_maximum_length
FROM information_schema.columns 
WHERE table_schema = 'public'
AND table_name = 'jovens' 
AND column_name = 'descricao_curta';
