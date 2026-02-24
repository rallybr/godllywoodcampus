-- =============================================================================
-- GODLLYWOOD CAMPUS - Ajuste RLS namorados: líder pode acessar OU jovem pode
-- editar o namorado do próprio perfil (jovens.usuario_id = usuário logado).
-- =============================================================================

-- Remover policies antigas para recriar com regra que inclui "próprio perfil"
DROP POLICY IF EXISTS "namorados_select" ON public.namorados;
DROP POLICY IF EXISTS "namorados_insert" ON public.namorados;
DROP POLICY IF EXISTS "namorados_update" ON public.namorados;
DROP POLICY IF EXISTS "namorados_delete" ON public.namorados;

-- Helper: jovem pertence ao usuário logado (jovem pode editar seu próprio perfil)
-- usuários.id_auth = auth.uid() e jovens.usuario_id = usuários.id
CREATE OR REPLACE FUNCTION public.namorado_jovem_pertence_ao_usuario(p_jovem_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.jovens j
    INNER JOIN public.usuarios u ON u.id = j.usuario_id AND u.id_auth = auth.uid()
    WHERE j.id = p_jovem_id
  );
$$;

COMMENT ON FUNCTION public.namorado_jovem_pertence_ao_usuario(uuid) IS 'True se o jovem pertence ao usuário logado (jovens.usuario_id = usuarios.id onde id_auth = auth.uid())';

-- SELECT: líder (can_access_jovem) OU dona do perfil
CREATE POLICY "namorados_select"
ON public.namorados FOR SELECT
TO authenticated
USING (
  public.can_access_jovem(
    (SELECT j.estado_id FROM public.jovens j WHERE j.id = namorados.jovem_id),
    (SELECT j.bloco_id FROM public.jovens j WHERE j.id = namorados.jovem_id),
    (SELECT j.regiao_id FROM public.jovens j WHERE j.id = namorados.jovem_id),
    (SELECT j.igreja_id FROM public.jovens j WHERE j.id = namorados.jovem_id)
  )
  OR public.namorado_jovem_pertence_ao_usuario(namorados.jovem_id)
);

-- INSERT: líder OU dona do perfil (jovem_id é o da linha sendo inserida)
CREATE POLICY "namorados_insert"
ON public.namorados FOR INSERT
TO authenticated
WITH CHECK (
  public.can_access_jovem(
    (SELECT j.estado_id FROM public.jovens j WHERE j.id = jovem_id),
    (SELECT j.bloco_id FROM public.jovens j WHERE j.id = jovem_id),
    (SELECT j.regiao_id FROM public.jovens j WHERE j.id = jovem_id),
    (SELECT j.igreja_id FROM public.jovens j WHERE j.id = jovem_id)
  )
  OR public.namorado_jovem_pertence_ao_usuario(jovem_id)
);

-- UPDATE: líder OU dona do perfil
CREATE POLICY "namorados_update"
ON public.namorados FOR UPDATE
TO authenticated
USING (
  public.can_access_jovem(
    (SELECT j.estado_id FROM public.jovens j WHERE j.id = namorados.jovem_id),
    (SELECT j.bloco_id FROM public.jovens j WHERE j.id = namorados.jovem_id),
    (SELECT j.regiao_id FROM public.jovens j WHERE j.id = namorados.jovem_id),
    (SELECT j.igreja_id FROM public.jovens j WHERE j.id = namorados.jovem_id)
  )
  OR public.namorado_jovem_pertence_ao_usuario(namorados.jovem_id)
);

-- DELETE: líder OU dona do perfil
CREATE POLICY "namorados_delete"
ON public.namorados FOR DELETE
TO authenticated
USING (
  public.can_access_jovem(
    (SELECT j.estado_id FROM public.jovens j WHERE j.id = namorados.jovem_id),
    (SELECT j.bloco_id FROM public.jovens j WHERE j.id = namorados.jovem_id),
    (SELECT j.regiao_id FROM public.jovens j WHERE j.id = namorados.jovem_id),
    (SELECT j.igreja_id FROM public.jovens j WHERE j.id = namorados.jovem_id)
  )
  OR public.namorado_jovem_pertence_ao_usuario(namorados.jovem_id)
);
