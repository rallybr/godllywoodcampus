-- Testar consulta de edições
SELECT COUNT(*) as total_edicoes FROM public.edicoes;

-- Ver algumas edições
SELECT id, nome, numero, ativa FROM public.edicoes ORDER BY numero DESC LIMIT 5;

-- Verificar se há políticas RLS na tabela edicoes
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'edicoes';

-- Verificar se RLS está habilitado na tabela edicoes
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'edicoes';
