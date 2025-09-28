-- Script para testar a nova coluna condicao_campus

-- 1. Verificar se a coluna foi criada
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'jovens' 
AND column_name = 'condicao_campus';

-- 2. Testar inserção de dados com a nova coluna
INSERT INTO jovens (
    nome_completo,
    data_nasc,
    sexo,
    estado_civil,
    whatsapp,
    estado_id,
    bloco_id,
    regiao_id,
    igreja_id,
    edicao_id,
    tempo_igreja,
    condicao,
    condicao_campus,
    data_cadastro,
    idade
) VALUES (
    'Teste Campus Condição',
    '1995-01-01',
    'masculino',
    'solteiro',
    '(11) 99999-9999',
    1, -- Substitua pelo ID de um estado válido
    1, -- Substitua pelo ID de um bloco válido
    1, -- Substitua pelo ID de uma região válida
    1, -- Substitua pelo ID de uma igreja válida
    1, -- Substitua pelo ID de uma edição válida
    '5 anos',
    'jovem_batizado_es',
    'obreiro',
    NOW(),
    29
);

-- 3. Verificar se os dados foram inseridos corretamente
SELECT 
    id,
    nome_completo,
    condicao,
    condicao_campus,
    data_cadastro
FROM jovens 
WHERE nome_completo = 'Teste Campus Condição'
ORDER BY data_cadastro DESC
LIMIT 1;

-- 4. Testar atualização da nova coluna
UPDATE jovens 
SET condicao_campus = 'colaborador'
WHERE nome_completo = 'Teste Campus Condição'
AND condicao_campus = 'obreiro';

-- 5. Verificar a atualização
SELECT 
    id,
    nome_completo,
    condicao,
    condicao_campus,
    data_cadastro
FROM jovens 
WHERE nome_completo = 'Teste Campus Condição'
ORDER BY data_cadastro DESC
LIMIT 1;

-- 6. Limpar dados de teste (opcional)
-- DELETE FROM jovens WHERE nome_completo = 'Teste Campus Condição';
