-- Script de diagnóstico e correção para problemas na tabela dados_viagem
-- Execute este script no Supabase SQL Editor

-- ============================================
-- 1. DIAGNÓSTICO INICIAL
-- ============================================

-- Verificar se a tabela dados_viagem existe
SELECT 'Tabela dados_viagem existe:' as status, 
       EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'dados_viagem') as existe;

-- Verificar estrutura da tabela
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'dados_viagem' 
ORDER BY ordinal_position;

-- Verificar se RLS está habilitado
SELECT 'RLS habilitado:' as status, rowsecurity 
FROM pg_tables 
WHERE tablename = 'dados_viagem';

-- Verificar políticas existentes
SELECT policyname, cmd, permissive, roles, qual, with_check
FROM pg_policies 
WHERE tablename = 'dados_viagem'
ORDER BY policyname;

-- ============================================
-- 2. VERIFICAR FUNÇÃO can_access_jovem
-- ============================================

-- Verificar se a função existe
SELECT 'Função can_access_jovem existe:' as status,
       EXISTS (
         SELECT 1 FROM pg_proc p
         JOIN pg_namespace n ON p.pronamespace = n.oid
         WHERE n.nspname = 'public' AND p.proname = 'can_access_jovem'
       ) as existe;

-- Se a função não existir, vamos criá-la
CREATE OR REPLACE FUNCTION can_access_jovem(
  jovem_estado_id uuid,
  jovem_bloco_id uuid,
  jovem_regiao_id uuid,
  jovem_igreja_id uuid
) RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_user_id uuid;
  user_role_slug text;
BEGIN
  -- Obter o ID do usuário atual
  current_user_id := (SELECT id FROM public.usuarios WHERE id_auth = auth.uid());
  
  IF current_user_id IS NULL THEN
    RETURN false;
  END IF;
  
  -- Verificar se é administrador ou colaborador (acesso total)
  SELECT r.slug INTO user_role_slug
  FROM public.user_roles ur
  JOIN public.roles r ON r.id = ur.role_id
  WHERE ur.user_id = current_user_id
    AND ur.ativo = true
    AND r.slug IN ('administrador', 'colaborador');
  
  IF user_role_slug IS NOT NULL THEN
    RETURN true;
  END IF;
  
  -- Verificar líderes com escopo específico
  SELECT r.slug INTO user_role_slug
  FROM public.user_roles ur
  JOIN public.roles r ON r.id = ur.role_id
  WHERE ur.user_id = current_user_id
    AND ur.ativo = true
    AND r.slug IN ('lider_estadual', 'lider_bloco', 'lider_regional', 'lider_igreja')
    AND (
      (r.slug = 'lider_estadual' AND ur.estado_id = jovem_estado_id) OR
      (r.slug = 'lider_bloco' AND ur.bloco_id = jovem_bloco_id) OR
      (r.slug = 'lider_regional' AND ur.regiao_id = jovem_regiao_id) OR
      (r.slug = 'lider_igreja' AND ur.igreja_id = jovem_igreja_id)
    );
  
  RETURN user_role_slug IS NOT NULL;
END;
$$;

-- ============================================
-- 3. CRIAR TRIGGER PARA USUARIO_ID
-- ============================================

-- Criar função para definir usuario_id automaticamente
CREATE OR REPLACE FUNCTION set_usuario_id_dados_viagem()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Se usuario_id não foi fornecido, definir com o usuário atual
  IF NEW.usuario_id IS NULL THEN
    NEW.usuario_id := (SELECT id FROM public.usuarios WHERE id_auth = auth.uid());
  END IF;
  
  RETURN NEW;
END;
$$;

-- Criar trigger
DROP TRIGGER IF EXISTS trigger_set_usuario_id_dados_viagem ON public.dados_viagem;
CREATE TRIGGER trigger_set_usuario_id_dados_viagem
  BEFORE INSERT ON public.dados_viagem
  FOR EACH ROW
  EXECUTE FUNCTION set_usuario_id_dados_viagem();

-- ============================================
-- 4. CORRIGIR POLÍTICAS RLS
-- ============================================

-- Remover políticas existentes
DROP POLICY IF EXISTS "dados_viagem_select_scoped" ON public.dados_viagem;
DROP POLICY IF EXISTS "dados_viagem_insert_scoped" ON public.dados_viagem;
DROP POLICY IF EXISTS "dados_viagem_update_scoped" ON public.dados_viagem;
DROP POLICY IF EXISTS "dados_viagem_delete_admin" ON public.dados_viagem;

-- Habilitar RLS se não estiver habilitado
ALTER TABLE public.dados_viagem ENABLE ROW LEVEL SECURITY;

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

-- ============================================
-- 5. VERIFICAÇÃO FINAL
-- ============================================

-- Verificar se as políticas foram criadas
SELECT 'Políticas criadas:' as status, 
       COUNT(*) as total_policies
FROM pg_policies 
WHERE tablename = 'dados_viagem';

-- Listar todas as políticas
SELECT policyname, cmd, permissive, roles
FROM pg_policies 
WHERE tablename = 'dados_viagem'
ORDER BY policyname;

-- Verificar se a função foi criada
SELECT 'Função can_access_jovem criada:' as status,
       EXISTS (
         SELECT 1 FROM pg_proc p
         JOIN pg_namespace n ON p.pronamespace = n.oid
         WHERE n.nspname = 'public' AND p.proname = 'can_access_jovem'
       ) as existe;

-- Verificar se o trigger foi criado
SELECT 'Trigger criado:' as status,
       EXISTS (
         SELECT 1 FROM pg_trigger t
         JOIN pg_class c ON t.tgrelid = c.oid
         WHERE c.relname = 'dados_viagem' 
         AND t.tgname = 'trigger_set_usuario_id_dados_viagem'
       ) as existe;

-- ============================================
-- 6. TESTE DE INSERÇÃO (OPCIONAL)
-- ============================================

-- Descomente as linhas abaixo para testar a inserção
-- (substitua os UUIDs pelos valores reais)

/*
-- Teste de inserção
INSERT INTO public.dados_viagem (
  jovem_id,
  edicao_id,
  pagou_despesas,
  comprovante_pagamento
) VALUES (
  'UUID_DO_JOVEM_AQUI',
  'UUID_DA_EDICAO_AQUI',
  true,
  'https://exemplo.com/comprovante.jpg'
);
*/

SELECT 'Script de diagnóstico e correção executado com sucesso!' as resultado;
