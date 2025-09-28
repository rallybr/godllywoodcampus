-- Script para corrigir políticas RLS da tabela dados_viagem

-- 1. Verificar se a tabela existe
SELECT 'Tabela dados_viagem existe:' as status, 
       EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'dados_viagem') as existe;

-- 2. Verificar se RLS está habilitado
SELECT 'RLS habilitado:' as status, rowsecurity 
FROM pg_tables 
WHERE tablename = 'dados_viagem';

-- 3. Remover políticas existentes (se houver)
DROP POLICY IF EXISTS "dados_viagem_select_scoped" ON public.dados_viagem;
DROP POLICY IF EXISTS "dados_viagem_insert_scoped" ON public.dados_viagem;
DROP POLICY IF EXISTS "dados_viagem_update_scoped" ON public.dados_viagem;
DROP POLICY IF EXISTS "dados_viagem_delete_admin" ON public.dados_viagem;

-- 4. Criar políticas corretas
-- Política para SELECT
CREATE POLICY "dados_viagem_select_scoped" ON public.dados_viagem
FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.jovens j
    WHERE j.id = dados_viagem.jovem_id
    AND (
      can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id)
      OR j.usuario_id = (SELECT id FROM public.usuarios WHERE id_auth = auth.uid())
    )
  )
);

-- Política para INSERT
CREATE POLICY "dados_viagem_insert_scoped" ON public.dados_viagem
FOR INSERT TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.jovens j
    WHERE j.id = dados_viagem.jovem_id
    AND (
      can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id)
      OR j.usuario_id = (SELECT id FROM public.usuarios WHERE id_auth = auth.uid())
    )
  )
);

-- Política para UPDATE
CREATE POLICY "dados_viagem_update_scoped" ON public.dados_viagem
FOR UPDATE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.jovens j
    WHERE j.id = dados_viagem.jovem_id
    AND (
      can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id)
      OR j.usuario_id = (SELECT id FROM public.usuarios WHERE id_auth = auth.uid())
    )
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.jovens j
    WHERE j.id = dados_viagem.jovem_id
    AND (
      can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id)
      OR j.usuario_id = (SELECT id FROM public.usuarios WHERE id_auth = auth.uid())
    )
  )
);

-- Política para DELETE (apenas administradores)
CREATE POLICY "dados_viagem_delete_admin" ON public.dados_viagem
FOR DELETE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.user_roles ur
    JOIN public.roles r ON r.id = ur.role_id
    WHERE ur.user_id = (SELECT id FROM public.usuarios WHERE id_auth = auth.uid())
    AND ur.ativo = true
    AND r.slug = 'administrador'
  )
);

-- 5. Verificar se as políticas foram criadas
SELECT 'Políticas criadas:' as status, 
       COUNT(*) as total_policies
FROM pg_policies 
WHERE tablename = 'dados_viagem';

-- 6. Listar todas as políticas
SELECT policyname, cmd, permissive, roles
FROM pg_policies 
WHERE tablename = 'dados_viagem'
ORDER BY policyname;
