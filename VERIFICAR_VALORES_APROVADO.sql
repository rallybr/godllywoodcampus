-- Verificar valores únicos na coluna aprovado
SELECT DISTINCT aprovado, COUNT(*) as quantidade
FROM jovens 
GROUP BY aprovado
ORDER BY aprovado;

-- Verificar alguns registros específicos
SELECT id, nome_completo, aprovado, data_cadastro
FROM jovens 
ORDER BY data_cadastro DESC
LIMIT 10;
