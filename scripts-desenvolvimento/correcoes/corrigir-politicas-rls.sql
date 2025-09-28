-- Corrigir políticas RLS que estão causando recursão infinita

-- 1. Remover políticas problemáticas
DROP POLICY IF EXISTS "Usuários podem ver seu próprio último acesso" ON public.usuarios;
DROP POLICY IF EXISTS "Administradores podem ver todos os acessos" ON public.usuarios;

-- 2. Verificar políticas existentes na tabela usuarios
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'usuarios' AND schemaname = 'public';

-- 3. Criar políticas RLS mais simples e seguras
CREATE POLICY "Usuários podem ver seu próprio perfil" ON public.usuarios
  FOR SELECT USING (id_auth = auth.uid());

CREATE POLICY "Administradores podem ver todos os usuários" ON public.usuarios
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id_auth = auth.uid() 
      AND u.nivel = 'administrador'
    )
  );

-- 4. Política para permitir que administradores vejam dados de último acesso
CREATE POLICY "Administradores podem ver dados de acesso" ON public.usuarios
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id_auth = auth.uid() 
      AND u.nivel = 'administrador'
    )
  );

-- 5. Política para permitir atualização do último acesso
CREATE POLICY "Sistema pode atualizar último acesso" ON public.usuarios
  FOR UPDATE USING (true)
  WITH CHECK (true);

-- 6. Verificar se há outras políticas problemáticas
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'usuarios' AND schemaname = 'public'
ORDER BY policyname;
