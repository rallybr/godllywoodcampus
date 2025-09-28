-- =====================================================
-- VERIFICAR E CORRIGIR FUNÇÃO get_jovem_completo
-- =====================================================

-- 1. VERIFICAR SE A FUNÇÃO EXISTE
-- =====================================================
SELECT 
  proname as nome_funcao,
  proargnames as argumentos,
  prosrc as codigo_fonte
FROM pg_proc 
WHERE proname = 'get_jovem_completo';

-- 2. SE A FUNÇÃO NÃO EXISTIR, CRIAR ELA
-- =====================================================
CREATE OR REPLACE FUNCTION public.get_jovem_completo(p_jovem_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  resultado jsonb;
BEGIN
  -- Verificar se o jovem existe
  IF NOT EXISTS (SELECT 1 FROM public.jovens WHERE id = p_jovem_id) THEN
    RETURN NULL;
  END IF;

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
    'estado', CASE 
      WHEN e.id IS NOT NULL THEN jsonb_build_object(
        'id', e.id,
        'nome', e.nome,
        'sigla', e.sigla,
        'bandeira', e.bandeira
      )
      ELSE NULL
    END,
    'bloco', CASE 
      WHEN b.id IS NOT NULL THEN jsonb_build_object(
        'id', b.id,
        'nome', b.nome
      )
      ELSE NULL
    END,
    'regiao', CASE 
      WHEN r.id IS NOT NULL THEN jsonb_build_object(
        'id', r.id,
        'nome', r.nome
      )
      ELSE NULL
    END,
    'igreja', CASE 
      WHEN i.id IS NOT NULL THEN jsonb_build_object(
        'id', i.id,
        'nome', i.nome,
        'endereco', i.endereco
      )
      ELSE NULL
    END
  ) INTO resultado
  FROM public.jovens j
  LEFT JOIN public.estados e ON e.id = j.estado_id
  LEFT JOIN public.blocos b ON b.id = j.bloco_id
  LEFT JOIN public.regioes r ON r.id = j.regiao_id
  LEFT JOIN public.igrejas i ON i.id = j.igreja_id
  WHERE j.id = p_jovem_id;
  
  RETURN resultado;
END;
$function$;

-- 3. TESTAR A FUNÇÃO
-- =====================================================
SELECT public.get_jovem_completo('0e1bc378-2cd2-476b-9551-d11d444bf499');

-- 4. VERIFICAR PERMISSÕES
-- =====================================================
-- Garantir que a função tenha as permissões corretas
GRANT EXECUTE ON FUNCTION public.get_jovem_completo(uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.get_jovem_completo(uuid) TO authenticated;
