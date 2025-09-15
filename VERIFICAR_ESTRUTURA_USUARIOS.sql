-- =====================================================
-- VERIFICAR ESTRUTURA DA TABELA USUARIOS
-- =====================================================

-- Verificar estrutura da tabela usuarios
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'usuarios' 
ORDER BY ordinal_position;

-- Verificar se existem dados na tabela usuarios
SELECT COUNT(*) as total_usuarios FROM usuarios;

-- Verificar alguns registros de exemplo
SELECT id, nome, email FROM usuarios LIMIT 5;

-- Verificar se o campo nome existe e tem dados
SELECT 
    COUNT(*) as total_com_nome,
    COUNT(nome) as nomes_preenchidos
FROM usuarios;
