-- Desabilitar RLS temporariamente na tabela edicoes
ALTER TABLE public.edicoes DISABLE ROW LEVEL SECURITY;

-- Remover todas as políticas existentes na tabela edicoes
DROP POLICY IF EXISTS "Edições são visíveis para todos" ON public.edicoes;
DROP POLICY IF EXISTS "Edições públicas" ON public.edicoes;
DROP POLICY IF EXISTS "Edições acessíveis" ON public.edicoes;
DROP POLICY IF EXISTS "Edições visíveis para usuários autenticados" ON public.edicoes;

-- Criar política simples para permitir acesso a todos os usuários autenticados
CREATE POLICY "Edições são visíveis para todos" ON public.edicoes
    FOR SELECT
    TO authenticated
    USING (true);

-- Habilitar RLS novamente
ALTER TABLE public.edicoes ENABLE ROW LEVEL SECURITY;

-- Testar se funcionou
SELECT COUNT(*) as total_edicoes FROM public.edicoes;
SELECT id, nome, numero, ativa FROM public.edicoes ORDER BY numero DESC LIMIT 3;
