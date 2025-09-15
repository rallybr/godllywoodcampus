-- =====================================================
-- ADICIONAR COLUNAS DO INTELLIMEN NA TABELA JOVENS
-- =====================================================

-- Verificar se as colunas já existem antes de adicionar
DO $$
BEGIN
    -- Adicionar coluna formado_intellimen
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'jovens' 
        AND column_name = 'formado_intellimen'
    ) THEN
        ALTER TABLE jovens ADD COLUMN formado_intellimen BOOLEAN DEFAULT FALSE;
        RAISE NOTICE 'Coluna formado_intellimen adicionada com sucesso';
    ELSE
        RAISE NOTICE 'Coluna formado_intellimen já existe';
    END IF;

    -- Adicionar coluna fazendo_desafios
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'jovens' 
        AND column_name = 'fazendo_desafios'
    ) THEN
        ALTER TABLE jovens ADD COLUMN fazendo_desafios BOOLEAN DEFAULT FALSE;
        RAISE NOTICE 'Coluna fazendo_desafios adicionada com sucesso';
    ELSE
        RAISE NOTICE 'Coluna fazendo_desafios já existe';
    END IF;

    -- Adicionar coluna qual_desafio
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'jovens' 
        AND column_name = 'qual_desafio'
    ) THEN
        ALTER TABLE jovens ADD COLUMN qual_desafio TEXT;
        RAISE NOTICE 'Coluna qual_desafio adicionada com sucesso';
    ELSE
        RAISE NOTICE 'Coluna qual_desafio já existe';
    END IF;
END $$;

-- Verificar se as colunas foram adicionadas
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'jovens' 
AND column_name IN ('formado_intellimen', 'fazendo_desafios', 'qual_desafio')
ORDER BY column_name;

-- Comentários nas colunas
COMMENT ON COLUMN jovens.formado_intellimen IS 'Indica se o jovem é formado no IntelliMen';
COMMENT ON COLUMN jovens.fazendo_desafios IS 'Indica se o jovem está fazendo os desafios do IntelliMen';
COMMENT ON COLUMN jovens.qual_desafio IS 'Qual desafio específico o jovem está fazendo (ex: Desafio #12)';

-- Verificar estrutura final da tabela
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'jovens' 
ORDER BY ordinal_position;
