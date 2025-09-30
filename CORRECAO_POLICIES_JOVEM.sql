-- 🔧 CORREÇÃO DAS POLICIES DA TABELA JOVENS
-- Este script corrige as policies para que o nível jovem veja apenas seus próprios dados

-- ============================================
-- 1. REMOVER TODAS AS POLICIES ATUAIS
-- ============================================

-- Remover TODAS as policies existentes da tabela jovens
DROP POLICY IF EXISTS "jovem pode inserir proprio cadastro" ON public.jovens;
DROP POLICY IF EXISTS "jovem pode ver proprio cadastro" ON public.jovens;
DROP POLICY IF EXISTS "jovens_select_scoped" ON public.jovens;
DROP POLICY IF EXISTS "jovens_insert_self_or_admin" ON public.jovens;
DROP POLICY IF EXISTS "jovens_update_scoped_roles" ON public.jovens;
DROP POLICY IF EXISTS "jovens_delete_admin" ON public.jovens;
DROP POLICY IF EXISTS "jovens_delete_admin_only" ON public.jovens;
DROP POLICY IF EXISTS "jovens_admin_colab" ON public.jovens;
DROP POLICY IF EXISTS "jovens_admin_policy" ON public.jovens;
DROP POLICY IF EXISTS "jovens_colaborador_policy" ON public.jovens;
DROP POLICY IF EXISTS "jovens_lider_bloco" ON public.jovens;
DROP POLICY IF EXISTS "jovens_lider_bloco_policy" ON public.jovens;
DROP POLICY IF EXISTS "jovens_lider_estadual" ON public.jovens;
DROP POLICY IF EXISTS "jovens_lider_estadual_policy" ON public.jovens;
DROP POLICY IF EXISTS "jovens_lider_igreja" ON public.jovens;
DROP POLICY IF EXISTS "jovens_lider_igreja_policy" ON public.jovens;
DROP POLICY IF EXISTS "jovens_lider_regional" ON public.jovens;
DROP POLICY IF EXISTS "jovens_lider_regional_policy" ON public.jovens;
DROP POLICY IF EXISTS "allow_read_jovens_by_hierarchy" ON public.jovens;
DROP POLICY IF EXISTS "allow_insert_jovens_by_hierarchy" ON public.jovens;
DROP POLICY IF EXISTS "allow_update_jovens_by_hierarchy" ON public.jovens;
DROP POLICY IF EXISTS "allow_delete_jovens_admin" ON public.jovens;
DROP POLICY IF EXISTS "jovens_select_by_hierarchy" ON public.jovens;
DROP POLICY IF EXISTS "jovens_insert_by_hierarchy" ON public.jovens;
DROP POLICY IF EXISTS "jovens_update_by_hierarchy" ON public.jovens;

-- Remover TODAS as policies restantes (método mais seguro)
DO $$
DECLARE
    policy_record RECORD;
BEGIN
    FOR policy_record IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'jovens'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.jovens', policy_record.policyname);
    END LOOP;
END $$;

-- ============================================
-- 2. VERIFICAR SE A FUNÇÃO can_access_jovem EXISTE
-- ============================================

-- Se não existir, criar a função correta
CREATE OR REPLACE FUNCTION public.can_access_jovem(
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
  user_info record;
BEGIN
  -- Obter o ID do usuário atual
  current_user_id := (SELECT id FROM public.usuarios WHERE id_auth = auth.uid());
  
  -- Se não encontrou o usuário, não tem acesso
  IF current_user_id IS NULL THEN 
    RETURN false; 
  END IF;
  
  -- Buscar informações do usuário atual
  SELECT 
    id,
    nivel,
    estado_id,
    bloco_id,
    regiao_id,
    igreja_id
  INTO user_info
  FROM public.usuarios 
  WHERE id = current_user_id;
  
  -- Se não encontrou o usuário, não tem acesso
  IF user_info IS NULL THEN 
    RETURN false; 
  END IF;
  
  -- 1. ADMINISTRADOR - Acesso total
  IF user_info.nivel = 'administrador' THEN 
    RETURN true; 
  END IF;
  
  -- 2. LÍDERES NACIONAIS - Acesso total (visão nacional)
  IF user_info.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju') THEN 
    RETURN true; 
  END IF;
  
  -- 3. LÍDERES ESTADUAIS - Visão estadual
  IF user_info.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') THEN
    RETURN user_info.estado_id = jovem_estado_id;
  END IF;
  
  -- 4. LÍDERES DE BLOCO - Visão de bloco
  IF user_info.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') THEN
    RETURN user_info.bloco_id = jovem_bloco_id;
  END IF;
  
  -- 5. LÍDER REGIONAL - Visão regional
  IF user_info.nivel = 'lider_regional_iurd' THEN
    RETURN user_info.regiao_id = jovem_regiao_id;
  END IF;
  
  -- 6. LÍDER DE IGREJA - Visão de igreja
  IF user_info.nivel = 'lider_igreja_iurd' THEN
    RETURN user_info.igreja_id = jovem_igreja_id;
  END IF;
  
  -- 7. COLABORADOR - Acesso aos jovens que cadastrou
  IF user_info.nivel = 'colaborador' THEN
    RETURN EXISTS (
      SELECT 1 FROM public.jovens j
      WHERE j.estado_id = jovem_estado_id
        AND j.bloco_id = jovem_bloco_id
        AND j.regiao_id = jovem_regiao_id
        AND j.igreja_id = jovem_igreja_id
        AND j.usuario_id = current_user_id
    );
  END IF;
  
  -- 8. JOVEM - Acesso APENAS aos seus próprios dados
  IF user_info.nivel = 'jovem' THEN
    RETURN EXISTS (
      SELECT 1 FROM public.jovens j
      WHERE j.estado_id = jovem_estado_id
        AND j.bloco_id = jovem_bloco_id
        AND j.regiao_id = jovem_regiao_id
        AND j.igreja_id = jovem_igreja_id
        AND (j.usuario_id = current_user_id OR j.usuario_id IS NULL)
    );
  END IF;
  
  RETURN false;
END;
$$;

-- ============================================
-- 3. CRIAR POLICIES CORRETAS
-- ============================================

-- Política para SELECT (leitura)
CREATE POLICY "jovens_select_by_hierarchy" ON public.jovens
FOR SELECT TO authenticated
USING (
  -- Administrador: acesso total
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
  OR
  -- Líderes nacionais: acesso nacional
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju'))
  OR
  -- Líderes estaduais: acesso ao estado
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') AND u.estado_id = jovens.estado_id)
  OR
  -- Líderes de bloco: acesso ao bloco
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') AND u.bloco_id = jovens.bloco_id)
  OR
  -- Líder regional: acesso à região
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_regional_iurd' AND u.regiao_id = jovens.regiao_id)
  OR
  -- Líder de igreja: acesso à igreja
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_igreja_iurd' AND u.igreja_id = jovens.igreja_id)
  OR
  -- Colaborador: acesso aos jovens que cadastrou
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'colaborador' AND u.id = jovens.usuario_id)
  OR
  -- Jovem: acesso apenas aos seus próprios dados (incluindo quando usuario_id é null)
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND (u.id = jovens.usuario_id OR jovens.usuario_id IS NULL))
);

-- Política para INSERT (inserção)
CREATE POLICY "jovens_insert_by_hierarchy" ON public.jovens
FOR INSERT TO authenticated
WITH CHECK (
  -- Administrador: pode inserir qualquer jovem
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
  OR
  -- Líderes nacionais: podem inserir qualquer jovem
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju'))
  OR
  -- Líderes estaduais: podem inserir jovens do seu estado
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') AND u.estado_id = jovens.estado_id)
  OR
  -- Líderes de bloco: podem inserir jovens do seu bloco
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') AND u.bloco_id = jovens.bloco_id)
  OR
  -- Líder regional: pode inserir jovens da sua região
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_regional_iurd' AND u.regiao_id = jovens.regiao_id)
  OR
  -- Líder de igreja: pode inserir jovens da sua igreja
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_igreja_iurd' AND u.igreja_id = jovens.igreja_id)
  OR
  -- Colaborador: pode inserir jovens (será associado ao colaborador)
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'colaborador')
  OR
  -- Jovem: pode inserir apenas seu próprio cadastro (incluindo quando usuario_id é null)
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND (u.id = jovens.usuario_id OR jovens.usuario_id IS NULL))
);

-- Política para UPDATE (atualização)
CREATE POLICY "jovens_update_by_hierarchy" ON public.jovens
FOR UPDATE TO authenticated
USING (
  -- Administrador: pode atualizar qualquer jovem
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
  OR
  -- Líderes nacionais: podem atualizar qualquer jovem
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju'))
  OR
  -- Líderes estaduais: podem atualizar jovens do seu estado
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') AND u.estado_id = jovens.estado_id)
  OR
  -- Líderes de bloco: podem atualizar jovens do seu bloco
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') AND u.bloco_id = jovens.bloco_id)
  OR
  -- Líder regional: pode atualizar jovens da sua região
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_regional_iurd' AND u.regiao_id = jovens.regiao_id)
  OR
  -- Líder de igreja: pode atualizar jovens da sua igreja
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_igreja_iurd' AND u.igreja_id = jovens.igreja_id)
  OR
  -- Colaborador: pode atualizar jovens que cadastrou
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'colaborador' AND u.id = jovens.usuario_id)
  OR
  -- Jovem: pode atualizar apenas seus próprios dados (incluindo quando usuario_id é null)
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND (u.id = jovens.usuario_id OR jovens.usuario_id IS NULL))
)
WITH CHECK (
  -- Mesmas condições para WITH CHECK
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju'))
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') AND u.estado_id = jovens.estado_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') AND u.bloco_id = jovens.bloco_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_regional_iurd' AND u.regiao_id = jovens.regiao_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_igreja_iurd' AND u.igreja_id = jovens.igreja_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'colaborador' AND u.id = jovens.usuario_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND (u.id = jovens.usuario_id OR jovens.usuario_id IS NULL))
);

-- Política para DELETE (exclusão) - apenas administradores
CREATE POLICY "jovens_delete_admin_only" ON public.jovens
FOR DELETE TO authenticated
USING (
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
);

-- ============================================
-- 4. VERIFICAÇÃO FINAL
-- ============================================

-- Verificar políticas criadas
SELECT 
  'POLICIES CRIADAS:' as status,
  policyname as nome_politica,
  cmd as comando,
  permissive as permissiva,
  roles as roles_aplicadas
FROM pg_policies 
WHERE tablename = 'jovens'
ORDER BY policyname;

-- Verificar se RLS está habilitado
SELECT 
  'RLS HABILITADO:' as status,
  rowsecurity as rls_ativo
FROM pg_tables 
WHERE tablename = 'jovens';

-- Contar políticas por comando
SELECT 
  cmd as comando,
  COUNT(*) as total_politicas
FROM pg_policies 
WHERE tablename = 'jovens'
GROUP BY cmd
ORDER BY cmd;
