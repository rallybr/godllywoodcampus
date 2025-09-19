-- Script para configurar políticas do bucket 'viagens'
-- Execute este script no Supabase SQL Editor

-- ============================================
-- 1. VERIFICAR SE O BUCKET EXISTE
-- ============================================

SELECT 'Verificando bucket viagens...' as status;
SELECT * FROM storage.buckets WHERE name = 'viagens';

-- ============================================
-- 2. REMOVER POLÍTICAS EXISTENTES (SE HOUVER)
-- ============================================

-- Remover políticas existentes para o bucket viagens
DROP POLICY IF EXISTS "Permitir upload de comprovantes" ON storage.objects;
DROP POLICY IF EXISTS "Permitir visualização de comprovantes" ON storage.objects;
DROP POLICY IF EXISTS "Permitir exclusão de comprovantes" ON storage.objects;

-- ============================================
-- 3. CRIAR POLÍTICAS PARA O BUCKET VIAGENS
-- ============================================

-- Política para permitir upload de arquivos no bucket viagens
CREATE POLICY "Permitir upload de comprovantes" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'viagens' 
  AND auth.uid() IS NOT NULL
  AND (
    -- Administradores e colaboradores podem fazer upload
    EXISTS (
      SELECT 1 FROM public.user_roles ur
      JOIN public.roles r ON r.id = ur.role_id
      JOIN public.usuarios u ON u.id = ur.user_id
      WHERE u.id_auth = auth.uid()
        AND ur.ativo = true
        AND r.slug IN ('administrador', 'colaborador')
    )
    OR
    -- Jovens podem fazer upload de seus próprios comprovantes
    -- (assumindo que o path contém o jovem_id)
    EXISTS (
      SELECT 1 FROM public.jovens j
      JOIN public.usuarios u ON u.id = j.usuario_id
      WHERE u.id_auth = auth.uid()
        AND name LIKE j.id || '/%'
    )
  )
);

-- Política para permitir visualização de arquivos
CREATE POLICY "Permitir visualização de comprovantes" ON storage.objects
FOR SELECT TO authenticated
USING (
  bucket_id = 'viagens'
  AND auth.uid() IS NOT NULL
  AND (
    -- Administradores e colaboradores podem ver todos
    EXISTS (
      SELECT 1 FROM public.user_roles ur
      JOIN public.roles r ON r.id = ur.role_id
      JOIN public.usuarios u ON u.id = ur.user_id
      WHERE u.id_auth = auth.uid()
        AND ur.ativo = true
        AND r.slug IN ('administrador', 'colaborador')
    )
    OR
    -- Líderes podem ver comprovantes de jovens do seu escopo
    EXISTS (
      SELECT 1 FROM public.jovens j
      JOIN public.user_roles ur ON ur.user_id = (SELECT id FROM public.usuarios WHERE id_auth = auth.uid())
      JOIN public.roles r ON r.id = ur.role_id
      WHERE j.id::text = split_part(name, '/', 1)
        AND ur.ativo = true
        AND (
          (r.slug = 'lider_estadual' AND ur.estado_id = j.estado_id) OR
          (r.slug = 'lider_bloco' AND ur.bloco_id = j.bloco_id) OR
          (r.slug = 'lider_regional' AND ur.regiao_id = j.regiao_id) OR
          (r.slug = 'lider_igreja' AND ur.igreja_id = j.igreja_id)
        )
    )
    OR
    -- Jovens podem ver seus próprios comprovantes
    EXISTS (
      SELECT 1 FROM public.jovens j
      JOIN public.usuarios u ON u.id = j.usuario_id
      WHERE u.id_auth = auth.uid()
        AND j.id::text = split_part(name, '/', 1)
    )
  )
);

-- Política para permitir exclusão de arquivos
CREATE POLICY "Permitir exclusão de comprovantes" ON storage.objects
FOR DELETE TO authenticated
USING (
  bucket_id = 'viagens'
  AND auth.uid() IS NOT NULL
  AND (
    -- Apenas administradores podem deletar
    EXISTS (
      SELECT 1 FROM public.user_roles ur
      JOIN public.roles r ON r.id = ur.role_id
      JOIN public.usuarios u ON u.id = ur.user_id
      WHERE u.id_auth = auth.uid()
        AND ur.ativo = true
        AND r.slug = 'administrador'
    )
    OR
    -- Jovens podem deletar seus próprios comprovantes
    EXISTS (
      SELECT 1 FROM public.jovens j
      JOIN public.usuarios u ON u.id = j.usuario_id
      WHERE u.id_auth = auth.uid()
        AND j.id::text = split_part(name, '/', 1)
    )
  )
);

-- ============================================
-- 4. VERIFICAR POLÍTICAS CRIADAS
-- ============================================

SELECT 'Políticas criadas para o bucket viagens:' as status;
SELECT policyname, cmd, permissive, roles
FROM pg_policies 
WHERE tablename = 'objects' 
  AND schemaname = 'storage'
  AND policyname LIKE '%comprovantes%'
ORDER BY policyname;

-- ============================================
-- 5. TESTE DE ACESSO
-- ============================================

-- Verificar se o usuário atual tem permissões
SELECT 'Permissões do usuário atual:' as status;
SELECT 
  has_table_privilege('storage.objects', 'SELECT') as pode_select,
  has_table_privilege('storage.objects', 'INSERT') as pode_insert,
  has_table_privilege('storage.objects', 'DELETE') as pode_delete;

SELECT 'Configuração do bucket viagens concluída!' as resultado;
