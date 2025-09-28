-- Desabilitar RLS na tabela estados (se estiver habilitado)
ALTER TABLE public.estados DISABLE ROW LEVEL SECURITY;

-- Remover políticas existentes na tabela estados (se houver)
DROP POLICY IF EXISTS "Estados são visíveis para todos" ON public.estados;
DROP POLICY IF EXISTS "Estados públicos" ON public.estados;
DROP POLICY IF EXISTS "Estados acessíveis" ON public.estados;

-- Criar política simples para permitir acesso a todos
CREATE POLICY "Estados são visíveis para todos" ON public.estados
    FOR SELECT
    TO authenticated
    USING (true);

-- Habilitar RLS novamente
ALTER TABLE public.estados ENABLE ROW LEVEL SECURITY;

-- Testar se funcionou
SELECT COUNT(*) as total_estados FROM public.estados;
SELECT id, nome, sigla FROM public.estados LIMIT 3;
