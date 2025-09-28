-- Reativar políticas RLS necessárias para a função buscar_usuarios_com_ultimo_acesso
-- funcionar corretamente

-- 1. Reativar RLS na tabela usuarios
ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;

-- 2. Criar política básica para leitura de usuários
CREATE POLICY "Allow read for authenticated users" ON public.usuarios
FOR SELECT 
USING (auth.role() = 'authenticated');

-- 3. Criar política para administradores
CREATE POLICY "Allow all for admin" ON public.usuarios
FOR ALL 
USING (
  EXISTS (
    SELECT 1 FROM public.user_roles ur
    JOIN public.roles r ON r.id = ur.role_id
    WHERE ur.user_id = (SELECT id FROM public.usuarios WHERE id_auth = auth.uid())
    AND r.slug = 'administrador'
    AND ur.ativo = true
  )
);

-- 4. Criar política para usuários verem seu próprio perfil
CREATE POLICY "Allow users to see own profile" ON public.usuarios
FOR SELECT 
USING (id_auth = auth.uid());

-- 5. Verificar se as políticas foram criadas
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies 
WHERE tablename = 'usuarios'
ORDER BY policyname;
