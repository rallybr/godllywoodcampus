-- Script para corrigir completamente o problema de RLS

-- 1. Desabilitar RLS em todas as tabelas problemáticas
ALTER TABLE public.usuarios DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.jovens DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.avaliacoes DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles DISABLE ROW LEVEL SECURITY;

-- 2. Remover TODAS as políticas existentes
DO $$
DECLARE
    r RECORD;
BEGIN
    -- Remover políticas da tabela usuarios
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'usuarios' AND schemaname = 'public')
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON public.usuarios';
    END LOOP;
    
    -- Remover políticas da tabela jovens
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'jovens' AND schemaname = 'public')
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON public.jovens';
    END LOOP;
    
    -- Remover políticas da tabela avaliacoes
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'avaliacoes' AND schemaname = 'public')
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON public.avaliacoes';
    END LOOP;
    
    -- Remover políticas da tabela user_roles
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'user_roles' AND schemaname = 'public')
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON public.user_roles';
    END LOOP;
    
    -- Remover políticas da tabela roles
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'roles' AND schemaname = 'public')
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON public.roles';
    END LOOP;
END $$;

-- 3. Aguardar um momento para garantir que as políticas foram removidas
SELECT pg_sleep(1);

-- 4. Verificar se todas as políticas foram removidas
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('usuarios', 'jovens', 'avaliacoes', 'user_roles', 'roles')
ORDER BY tablename, policyname;

-- 5. Reabilitar RLS apenas nas tabelas que realmente precisam
ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jovens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.avaliacoes ENABLE ROW LEVEL SECURITY;

-- 6. Criar políticas MUITO simples e seguras
-- Políticas para usuarios
CREATE POLICY "usuarios_select_own" ON public.usuarios
  FOR SELECT USING (id_auth = auth.uid());

CREATE POLICY "usuarios_select_admin" ON public.usuarios
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.usuarios 
      WHERE id_auth = auth.uid() 
      AND nivel = 'administrador'
    )
  );

-- Políticas para jovens (básicas)
CREATE POLICY "jovens_select_all" ON public.jovens
  FOR SELECT USING (true);

CREATE POLICY "jovens_insert_admin" ON public.jovens
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.usuarios 
      WHERE id_auth = auth.uid() 
      AND nivel = 'administrador'
    )
  );

-- Políticas para avaliacoes (básicas)
CREATE POLICY "avaliacoes_select_all" ON public.avaliacoes
  FOR SELECT USING (true);

CREATE POLICY "avaliacoes_insert_admin" ON public.avaliacoes
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.usuarios 
      WHERE id_auth = auth.uid() 
      AND nivel = 'administrador'
    )
  );

-- 7. Verificar políticas criadas
SELECT schemaname, tablename, policyname, permissive, roles, cmd
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('usuarios', 'jovens', 'avaliacoes')
ORDER BY tablename, policyname;
