-- =============================================================================
-- GODLLYWOOD CAMPUS - Tabela namorados (dados do pastor/namorado da jovem)
-- =============================================================================
-- Relação 1:1 com jovens (uma jovem pode ter no máximo um registro de namorado).
-- Acesso controlado pelas mesmas regras do jovem (RLS via can_access_jovem).
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.namorados (
  id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
  jovem_id uuid NOT NULL REFERENCES public.jovens(id) ON DELETE CASCADE,
  nome text,
  foto text,
  idade integer,
  tempo_obra text,
  tempo_namoro text,
  como_se_conheceram text,
  quanto_tempo_se_conhece text,
  onde_esta_atualmente text,
  atribuicao_atual text,
  observacao_namoro text,
  criado_em timestamptz DEFAULT now(),
  atualizado_em timestamptz DEFAULT now(),
  CONSTRAINT namorados_jovem_id_unique UNIQUE (jovem_id)
);

ALTER TABLE public.namorados OWNER TO postgres;

COMMENT ON TABLE public.namorados IS 'Dados do namorado (pastor) da jovem do Godllywood Campus';
COMMENT ON COLUMN public.namorados.nome IS 'Nome do namorado';
COMMENT ON COLUMN public.namorados.foto IS 'URL da foto do namorado (Storage)';
COMMENT ON COLUMN public.namorados.idade IS 'Idade do namorado';
COMMENT ON COLUMN public.namorados.tempo_obra IS 'Tempo de obra';
COMMENT ON COLUMN public.namorados.tempo_namoro IS 'Tempo de namoro';
COMMENT ON COLUMN public.namorados.como_se_conheceram IS 'Como se conheceram';
COMMENT ON COLUMN public.namorados.quanto_tempo_se_conhece IS 'Há quanto tempo se conhecem';
COMMENT ON COLUMN public.namorados.onde_esta_atualmente IS 'Onde está atualmente';
COMMENT ON COLUMN public.namorados.atribuicao_atual IS 'Atribuição atual (pastor, etc.)';
COMMENT ON COLUMN public.namorados.observacao_namoro IS 'Observação sobre o namoro';

CREATE INDEX IF NOT EXISTS idx_namorados_jovem_id ON public.namorados(jovem_id);

-- Trigger para atualizar atualizado_em
CREATE OR REPLACE FUNCTION public.atualizar_namorados_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.atualizado_em = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_namorados_updated_at ON public.namorados;
CREATE TRIGGER trigger_namorados_updated_at
  BEFORE UPDATE ON public.namorados
  FOR EACH ROW EXECUTE PROCEDURE public.atualizar_namorados_updated_at();

-- RLS: mesmo critério de acesso do jovem (quem pode ver/editar o jovem pode ver/editar o namorado)
ALTER TABLE public.namorados ENABLE ROW LEVEL SECURITY;

-- Política SELECT: usuário que pode acessar o jovem pode ver o namorado
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
);

-- Política INSERT: quem pode acessar o jovem pode criar registro de namorado
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
);

-- Política UPDATE: quem pode acessar o jovem pode atualizar o namorado
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
);

-- Política DELETE: quem pode acessar o jovem pode remover o namorado
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
);

-- =============================================================================
-- Atualizar get_jovem_completo para incluir namorado (objeto ou null)
-- =============================================================================
CREATE OR REPLACE FUNCTION public.get_jovem_completo(p_jovem_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  resultado jsonb;
BEGIN
  SELECT jsonb_build_object(
    'id', j.id,
    'nome_completo', j.nome_completo,
    'idade', j.idade,
    'aprovado', j.aprovado,
    'sexo', j.sexo,
    'whatsapp', j.whatsapp,
    'data_nasc', j.data_nasc,
    'data_cadastro', j.data_cadastro,
    'estado_civil', j.estado_civil,
    'namora', j.namora,
    'tem_filho', j.tem_filho,
    'trabalha', j.trabalha,
    'local_trabalho', j.local_trabalho,
    'escolaridade', j.escolaridade,
    'formacao', j.formacao,
    'tem_dividas', j.tem_dividas,
    'tempo_igreja', j.tempo_igreja,
    'batizado_aguas', j.batizado_aguas,
    'data_batismo_aguas', j.data_batismo_aguas,
    'batizado_es', j.batizado_es,
    'data_batismo_es', j.data_batismo_es,
    'condicao', j.condicao,
    'tempo_condicao', j.tempo_condicao,
    'responsabilidade_igreja', j.responsabilidade_igreja,
    'disposto_servir', j.disposto_servir,
    'ja_obra_altar', j.ja_obra_altar,
    'ja_obreiro', j.ja_obreiro,
    'ja_colaborador', j.ja_colaborador,
    'afastado', j.afastado,
    'data_afastamento', j.data_afastamento,
    'motivo_afastamento', j.motivo_afastamento,
    'data_retorno', j.data_retorno,
    'pais_na_igreja', j.pais_na_igreja,
    'observacao_pais', j.observacao_pais,
    'familiares_igreja', j.familiares_igreja,
    'deseja_altar', j.deseja_altar,
    'observacao', j.observacao,
    'testemunho', j.testemunho,
    'instagram', j.instagram,
    'facebook', j.facebook,
    'tiktok', j.tiktok,
    'obs_redes', j.obs_redes,
    'pastor_que_indicou', j.pastor_que_indicou,
    'cresceu_na_igreja', j.cresceu_na_igreja,
    'experiencia_altar', j.experiencia_altar,
    'foi_obreiro', j.foi_obreiro,
    'foi_colaborador', j.foi_colaborador,
    'afastou', j.afastou,
    'quando_afastou', j.quando_afastou,
    'motivo_afastou', j.motivo_afastou,
    'quando_voltou', j.quando_voltou,
    'pais_sao_igreja', j.pais_sao_igreja,
    'obs_pais', j.obs_pais,
    'observacao_text', j.observacao_text,
    'testemunho_text', j.testemunho_text,
    'edicao', j.edicao,
    'foto', j.foto,
    'observacao_redes', j.observacao_redes,
    'formado_intellimen', j.formado_intellimen,
    'fazendo_desafios', j.fazendo_desafios,
    'qual_desafio', j.qual_desafio,
    'valor_divida', j.valor_divida,
    'usuario_id', j.usuario_id,
    'condicao_campus', j.condicao_campus,
    'estado_id', j.estado_id,
    'bloco_id', j.bloco_id,
    'regiao_id', j.regiao_id,
    'igreja_id', j.igreja_id,
    'edicao_id', j.edicao_id,
    'estado', jsonb_build_object(
      'id', e.id,
      'nome', e.nome,
      'sigla', e.sigla,
      'bandeira', e.bandeira
    ),
    'bloco', jsonb_build_object(
      'id', b.id,
      'nome', b.nome
    ),
    'regiao', jsonb_build_object(
      'id', r.id,
      'nome', r.nome
    ),
    'igreja', jsonb_build_object(
      'id', i.id,
      'nome', i.nome,
      'endereco', i.endereco
    ),
    'namorado', CASE
      WHEN n.id IS NOT NULL THEN jsonb_build_object(
        'id', n.id,
        'nome', n.nome,
        'foto', n.foto,
        'idade', n.idade,
        'tempo_obra', n.tempo_obra,
        'tempo_namoro', n.tempo_namoro,
        'como_se_conheceram', n.como_se_conheceram,
        'quanto_tempo_se_conhece', n.quanto_tempo_se_conhece,
        'onde_esta_atualmente', n.onde_esta_atualmente,
        'atribuicao_atual', n.atribuicao_atual,
        'observacao_namoro', n.observacao_namoro
      )
      ELSE NULL
    END
  ) INTO resultado
  FROM public.jovens j
  LEFT JOIN public.estados e ON e.id = j.estado_id
  LEFT JOIN public.blocos b ON b.id = j.bloco_id
  LEFT JOIN public.regioes r ON r.id = j.regiao_id
  LEFT JOIN public.igrejas i ON i.id = j.igreja_id
  LEFT JOIN public.namorados n ON n.jovem_id = j.id
  WHERE j.id = p_jovem_id;

  RETURN resultado;
END;
$$;
ALTER FUNCTION public.get_jovem_completo(uuid) OWNER TO postgres;
