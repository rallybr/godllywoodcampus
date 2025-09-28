-- Script para corrigir recursão infinita nas políticas RLS

-- 1. Desabilitar RLS temporariamente para corrigir
ALTER TABLE public.usuarios DISABLE ROW LEVEL SECURITY;

-- 2. Remover todas as políticas existentes
DROP POLICY IF EXISTS "Usuários podem ver seu próprio último acesso" ON public.usuarios;
DROP POLICY IF EXISTS "Administradores podem ver todos os acessos" ON public.usuarios;
DROP POLICY IF EXISTS "Usuários podem ver seu próprio perfil" ON public.usuarios;
DROP POLICY IF EXISTS "Administradores podem ver todos os usuários" ON public.usuarios;
DROP POLICY IF EXISTS "Administradores podem ver dados de acesso" ON public.usuarios;
DROP POLICY IF EXISTS "Sistema pode atualizar último acesso" ON public.usuarios;

-- 3. Recriar políticas simples e seguras
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

CREATE POLICY "usuarios_update_own" ON public.usuarios
  FOR UPDATE USING (id_auth = auth.uid())
  WITH CHECK (id_auth = auth.uid());

CREATE POLICY "usuarios_update_admin" ON public.usuarios
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.usuarios 
      WHERE id_auth = auth.uid() 
      AND nivel = 'administrador'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.usuarios 
      WHERE id_auth = auth.uid() 
      AND nivel = 'administrador'
    )
  );

-- 4. Reabilitar RLS
ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;

-- 5. Verificar políticas criadas
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'usuarios' AND schemaname = 'public'
ORDER BY policyname;
