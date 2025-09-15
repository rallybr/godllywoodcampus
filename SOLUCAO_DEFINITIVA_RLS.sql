-- SOLUÇÃO DEFINITIVA - DESABILITAR RLS TEMPORARIAMENTE
-- Execute este script no Supabase SQL Editor

-- 1. DESABILITAR RLS NA TABELA JOVENS TEMPORARIAMENTE
ALTER TABLE jovens DISABLE ROW LEVEL SECURITY;

-- 2. VERIFICAR SE FOI DESABILITADO
SELECT 
    'RLS STATUS' as status,
    schemaname,
    tablename,
    rowsecurity as rls_habilitado
FROM pg_tables 
WHERE tablename = 'jovens';

-- 3. TESTAR INSERÇÃO DIRETA
INSERT INTO jovens (
    nome_completo,
    data_nasc,
    whatsapp,
    estado_civil,
    edicao,
    estado_id,
    bloco_id,
    regiao_id,
    igreja_id,
    edicao_id,
    idade
) VALUES (
    'Teste RLS Desabilitado',
    '2000-01-01',
    '11999999999',
    'solteiro',
    '2024',
    'c20e70c2-92e6-4c50-96a5-177822095a25'::uuid,
    'b0cb2a8a-5b89-478b-95a9-a5bb8e84f06d'::uuid,
    '84cff91c-3afa-49da-b211-24f50f7cb2ab'::uuid,
    'd3301078-fc09-4131-b9e8-03c78570a774'::uuid,
    '78507ba7-d7cf-4476-8505-ffdc44852c50'::uuid,
    24
);

-- 4. VERIFICAR SE FOI INSERIDO
SELECT 
    'TESTE INSERÇÃO' as status,
    id,
    nome_completo,
    data_cadastro
FROM jovens 
WHERE nome_completo = 'Teste RLS Desabilitado'
ORDER BY data_cadastro DESC
LIMIT 1;

-- 5. LIMPAR TESTE
DELETE FROM jovens WHERE nome_completo = 'Teste RLS Desabilitado';
