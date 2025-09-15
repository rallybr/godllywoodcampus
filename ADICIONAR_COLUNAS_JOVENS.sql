-- ADICIONAR COLUNAS AUSENTES NA TABELA JOVENS
-- Execute este script no Supabase SQL Editor

-- 1. VERIFICAR ESTRUTURA ATUAL
SELECT 
    'ESTRUTURA ATUAL' as status,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'jovens'
  AND column_name IN ('sexo', 'observacao_redes')
ORDER BY column_name;

-- 2. ADICIONAR COLUNA SEXO
ALTER TABLE jovens 
ADD COLUMN IF NOT EXISTS sexo text;

-- 3. ADICIONAR COLUNA OBSERVACAO_REDES (se não existir)
ALTER TABLE jovens 
ADD COLUMN IF NOT EXISTS observacao_redes text;

-- 4. VERIFICAR SE FORAM ADICIONADAS
SELECT 
    'APÓS ADIÇÃO' as status,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'jovens'
  AND column_name IN ('sexo', 'observacao_redes')
ORDER BY column_name;

-- 5. TESTAR INSERÇÃO COM AS NOVAS COLUNAS
INSERT INTO jovens (
    nome_completo,
    data_nasc,
    whatsapp,
    estado_civil,
    sexo,
    observacao_redes,
    edicao,
    estado_id,
    bloco_id,
    regiao_id,
    igreja_id,
    edicao_id,
    idade
) VALUES (
    'Teste Colunas Adicionadas',
    '2000-01-01',
    '11999999999',
    'solteiro',
    'masculino',
    'Teste de observação das redes',
    '2024',
    'c20e70c2-92e6-4c50-96a5-177822095a25'::uuid,
    'b0cb2a8a-5b89-478b-95a9-a5bb8e84f06d'::uuid,
    '84cff91c-3afa-49da-b211-24f50f7cb2ab'::uuid,
    'd3301078-fc09-4131-b9e8-03c78570a774'::uuid,
    '78507ba7-d7cf-4476-8505-ffdc44852c50'::uuid,
    24
);

-- 6. VERIFICAR SE FOI INSERIDO
SELECT 
    'TESTE INSERÇÃO' as status,
    id,
    nome_completo,
    sexo,
    observacao_redes,
    data_cadastro
FROM jovens 
WHERE nome_completo = 'Teste Colunas Adicionadas'
ORDER BY data_cadastro DESC
LIMIT 1;

-- 7. LIMPAR TESTE
DELETE FROM jovens WHERE nome_completo = 'Teste Colunas Adicionadas';
