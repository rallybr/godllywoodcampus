-- Verificar se há políticas RLS na tabela estados
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
WHERE tablename = 'estados';

-- Verificar se RLS está habilitado na tabela estados
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'estados';

-- Testar consulta direta de estados
SELECT COUNT(*) as total_estados FROM public.estados;

-- Ver alguns estados
SELECT id, nome, sigla, bandeira FROM public.estados LIMIT 3;
