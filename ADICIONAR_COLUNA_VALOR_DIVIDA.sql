-- =====================================================
-- ADICIONAR COLUNA VALOR_DIVIDA NA TABELA JOVENS
-- =====================================================

-- Verificar se a coluna já existe antes de adicionar
DO $$
BEGIN
    -- Adicionar coluna valor_divida
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'jovens' 
        AND column_name = 'valor_divida'
    ) THEN
        ALTER TABLE jovens ADD COLUMN valor_divida DECIMAL(10,2);
        RAISE NOTICE 'Coluna valor_divida adicionada com sucesso';
    ELSE
        RAISE NOTICE 'Coluna valor_divida já existe';
    END IF;
END $$;

-- Verificar se a coluna foi adicionada
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'jovens' 
AND column_name = 'valor_divida'
ORDER BY column_name;

-- Comentário na coluna
COMMENT ON COLUMN jovens.valor_divida IS 'Valor da dívida do jovem (apenas se tem_dividas = true)';

-- Verificar estrutura final da tabela
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'jovens' 
AND column_name IN ('tem_dividas', 'valor_divida')
ORDER BY column_name;
