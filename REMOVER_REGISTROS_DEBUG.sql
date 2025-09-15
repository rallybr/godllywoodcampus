-- =====================================================
-- REMOVER REGISTROS DE DEBUG "Teste Debug"
-- =====================================================
-- Data: 2024-12-19
-- Objetivo: Remover registros de teste que foram inseridos pelo código de debug

-- Verificar quantos registros de debug existem
SELECT 
    COUNT(*) as total_debug,
    nome_completo,
    data_cadastro
FROM jovens 
WHERE nome_completo = 'Teste Debug'
GROUP BY nome_completo, data_cadastro
ORDER BY data_cadastro DESC;

-- Remover todos os registros de debug
DELETE FROM jovens 
WHERE nome_completo = 'Teste Debug';

-- Verificar se foram removidos
SELECT COUNT(*) as registros_restantes
FROM jovens 
WHERE nome_completo = 'Teste Debug';
