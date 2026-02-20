-- =============================================================================
-- GODLLYWOOD CAMPUS - STORAGE: BUCKETS E POLICIES
-- =============================================================================
-- Este script configura o Storage do Supabase para o projeto Godllywood Campus.
--
-- BUCKETS NECESSÁRIOS:
--   1. fotos_usuarios  - Fotos de perfil dos usuários (public)
--   2. fotos_jovens   - Fotos de perfil das moças/jovens (public)
--   3. viagens        - Comprovantes de pagamento e passagens (public)
--   4. fotos_nucleos  - Fotos do módulo "Dados de Núcleo" (public)
--
-- COMO CRIAR OS BUCKETS:
--   Opção A - Dashboard: Storage > New bucket, para cada um com Name exato acima,
--             Public bucket ON, File size limit 5MB (viagens 10MB), MIME: image/* e application/pdf.
--   Opção B - Script Node: Defina SUPABASE_SERVICE_ROLE_KEY no .env.local e execute:
--             node supabase/scripts/create-storage-buckets.js
--
-- Depois de criar os buckets, execute as policies abaixo no SQL Editor do Supabase.
-- =============================================================================

-- Remover policies antigas se existirem (para idempotência)
DROP POLICY IF EXISTS "fotos_usuarios_select" ON storage.objects;
DROP POLICY IF EXISTS "fotos_usuarios_insert" ON storage.objects;
DROP POLICY IF EXISTS "fotos_usuarios_update" ON storage.objects;
DROP POLICY IF EXISTS "fotos_usuarios_delete" ON storage.objects;

DROP POLICY IF EXISTS "fotos_jovens_select" ON storage.objects;
DROP POLICY IF EXISTS "fotos_jovens_insert" ON storage.objects;
DROP POLICY IF EXISTS "fotos_jovens_update" ON storage.objects;
DROP POLICY IF EXISTS "fotos_jovens_delete" ON storage.objects;

DROP POLICY IF EXISTS "viagens_select" ON storage.objects;
DROP POLICY IF EXISTS "viagens_insert" ON storage.objects;
DROP POLICY IF EXISTS "viagens_update" ON storage.objects;
DROP POLICY IF EXISTS "viagens_delete" ON storage.objects;

DROP POLICY IF EXISTS "fotos_nucleos_select" ON storage.objects;
DROP POLICY IF EXISTS "fotos_nucleos_insert" ON storage.objects;
DROP POLICY IF EXISTS "fotos_nucleos_update" ON storage.objects;
DROP POLICY IF EXISTS "fotos_nucleos_delete" ON storage.objects;

-- =============================================================================
-- BUCKET: fotos_usuarios (fotos de perfil dos usuários)
-- =============================================================================

-- Leitura: público (bucket público - URLs são acessíveis sem login)
CREATE POLICY "fotos_usuarios_select"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'fotos_usuarios');

-- Upload: usuários autenticados podem enviar na própria pasta (nome = {user_id}/...)
CREATE POLICY "fotos_usuarios_insert"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'fotos_usuarios'
  AND (storage.foldername(name))[1] = (SELECT id::text FROM public.usuarios WHERE id_auth = auth.uid() LIMIT 1)
);

-- Atualizar: apenas o dono do arquivo (owner) ou na própria pasta
CREATE POLICY "fotos_usuarios_update"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'fotos_usuarios'
  AND (
    owner = auth.uid()
    OR (storage.foldername(name))[1] = (SELECT id::text FROM public.usuarios WHERE id_auth = auth.uid() LIMIT 1)
  )
);

-- Deletar: mesmo critério do update
CREATE POLICY "fotos_usuarios_delete"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'fotos_usuarios'
  AND (
    owner = auth.uid()
    OR (storage.foldername(name))[1] = (SELECT id::text FROM public.usuarios WHERE id_auth = auth.uid() LIMIT 1)
  )
);

-- =============================================================================
-- BUCKET: fotos_jovens (fotos de perfil das moças/jovens)
-- =============================================================================

-- Leitura: público (bucket público)
CREATE POLICY "fotos_jovens_select"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'fotos_jovens');

-- Upload: autenticados (a aplicação controla quem pode editar qual jovem)
CREATE POLICY "fotos_jovens_insert"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'fotos_jovens');

-- Atualizar: autenticados
CREATE POLICY "fotos_jovens_update"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'fotos_jovens');

-- Deletar: autenticados
CREATE POLICY "fotos_jovens_delete"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'fotos_jovens');

-- =============================================================================
-- BUCKET: viagens (comprovantes de pagamento e passagens ida/volta)
-- =============================================================================

-- Leitura: público (comprovantes visíveis via link)
CREATE POLICY "viagens_select"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'viagens');

-- Upload: autenticados (paths: {jovem_id}/{edicao_id}/pagamento|ida|volta)
CREATE POLICY "viagens_insert"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'viagens');

-- Atualizar: autenticados
CREATE POLICY "viagens_update"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'viagens');

-- Deletar: autenticados (usado ao remover comprovante)
CREATE POLICY "viagens_delete"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'viagens');

-- =============================================================================
-- BUCKET: fotos_nucleos (fotos do módulo Dados de Núcleo)
-- =============================================================================

-- Leitura: público
CREATE POLICY "fotos_nucleos_select"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'fotos_nucleos');

-- Upload: autenticados
CREATE POLICY "fotos_nucleos_insert"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'fotos_nucleos');

-- Atualizar: autenticados
CREATE POLICY "fotos_nucleos_update"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'fotos_nucleos');

-- Deletar: autenticados
CREATE POLICY "fotos_nucleos_delete"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'fotos_nucleos');
