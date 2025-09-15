-- =====================================================
-- CRIAR POLÍTICAS RLS PARA TABELA AVALIACOES
-- =====================================================

-- Habilitar RLS na tabela avaliacoes se não estiver habilitado
ALTER TABLE avaliacoes ENABLE ROW LEVEL SECURITY;

-- Remover políticas existentes se houver
DROP POLICY IF EXISTS "avaliacoes_select_policy" ON avaliacoes;
DROP POLICY IF EXISTS "avaliacoes_insert_policy" ON avaliacoes;
DROP POLICY IF EXISTS "avaliacoes_update_policy" ON avaliacoes;
DROP POLICY IF EXISTS "avaliacoes_delete_policy" ON avaliacoes;

-- Política para SELECT - baseada na hierarquia de acesso
CREATE POLICY "avaliacoes_select_policy" ON avaliacoes
FOR SELECT
USING (
  -- Administradores e líderes nacionais veem tudo
  EXISTS (
    SELECT 1 FROM user_roles ur
    JOIN roles r ON ur.role_id = r.id
    WHERE ur.user_id = auth.uid() 
    AND ur.ativo = true
    AND r.slug IN ('administrador', 'lider_nacional_iurd', 'lider_nacional_fju')
  )
  OR
  -- Líderes estaduais veem avaliações dos jovens do seu estado
  EXISTS (
    SELECT 1 FROM user_roles ur
    JOIN roles r ON ur.role_id = r.id
    JOIN jovens j ON j.estado_id = ur.estado_id
    WHERE ur.user_id = auth.uid() 
    AND ur.ativo = true
    AND r.slug IN ('lider_estadual_iurd', 'lider_estadual_fju')
    AND j.id = avaliacoes.jovem_id
  )
  OR
  -- Líderes de bloco veem avaliações dos jovens do seu bloco
  EXISTS (
    SELECT 1 FROM user_roles ur
    JOIN roles r ON ur.role_id = r.id
    JOIN jovens j ON j.bloco_id = ur.bloco_id
    WHERE ur.user_id = auth.uid() 
    AND ur.ativo = true
    AND r.slug IN ('lider_bloco_iurd', 'lider_bloco_fju')
    AND j.id = avaliacoes.jovem_id
  )
  OR
  -- Líderes regionais veem avaliações dos jovens da sua região
  EXISTS (
    SELECT 1 FROM user_roles ur
    JOIN roles r ON ur.role_id = r.id
    JOIN jovens j ON j.regiao_id = ur.regiao_id
    WHERE ur.user_id = auth.uid() 
    AND ur.ativo = true
    AND r.slug = 'lider_regional_iurd'
    AND j.id = avaliacoes.jovem_id
  )
  OR
  -- Líderes de igreja veem avaliações dos jovens da sua igreja
  EXISTS (
    SELECT 1 FROM user_roles ur
    JOIN roles r ON ur.role_id = r.id
    JOIN jovens j ON j.igreja_id = ur.igreja_id
    WHERE ur.user_id = auth.uid() 
    AND ur.ativo = true
    AND r.slug = 'lider_igreja_iurd'
    AND j.id = avaliacoes.jovem_id
  )
  OR
  -- Colaboradores veem apenas suas próprias avaliações
  EXISTS (
    SELECT 1 FROM user_roles ur
    JOIN roles r ON ur.role_id = r.id
    WHERE ur.user_id = auth.uid() 
    AND ur.ativo = true
    AND r.slug = 'colaborador'
    AND avaliacoes.user_id = auth.uid()
  )
);

-- Política para INSERT - todos os níveis podem criar avaliações
CREATE POLICY "avaliacoes_insert_policy" ON avaliacoes
FOR INSERT
WITH CHECK (
  -- Verificar se o usuário tem algum role ativo
  EXISTS (
    SELECT 1 FROM user_roles ur
    WHERE ur.user_id = auth.uid() 
    AND ur.ativo = true
  )
  AND
  -- Verificar se o jovem existe
  EXISTS (
    SELECT 1 FROM jovens j
    WHERE j.id = avaliacoes.jovem_id
  )
);

-- Política para UPDATE - apenas o próprio avaliador pode editar
CREATE POLICY "avaliacoes_update_policy" ON avaliacoes
FOR UPDATE
USING (
  -- Apenas o próprio avaliador pode editar
  user_id = auth.uid()
  OR
  -- Administradores e líderes nacionais podem editar qualquer avaliação
  EXISTS (
    SELECT 1 FROM user_roles ur
    JOIN roles r ON ur.role_id = r.id
    WHERE ur.user_id = auth.uid() 
    AND ur.ativo = true
    AND r.slug IN ('administrador', 'lider_nacional_iurd', 'lider_nacional_fju')
  )
);

-- Política para DELETE - apenas o próprio avaliador pode deletar
CREATE POLICY "avaliacoes_delete_policy" ON avaliacoes
FOR DELETE
USING (
  -- Apenas o próprio avaliador pode deletar
  user_id = auth.uid()
  OR
  -- Administradores e líderes nacionais podem deletar qualquer avaliação
  EXISTS (
    SELECT 1 FROM user_roles ur
    JOIN roles r ON ur.role_id = r.id
    WHERE ur.user_id = auth.uid() 
    AND ur.ativo = true
    AND r.slug IN ('administrador', 'lider_nacional_iurd', 'lider_nacional_fju')
  )
);

-- Verificar se as políticas foram criadas
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies 
WHERE tablename = 'avaliacoes'
ORDER BY policyname;
