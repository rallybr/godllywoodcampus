-- Criação da tabela dados_nucleo para armazenar informações sobre núcleos de oração dos jovens
-- Esta tabela está relacionada com a tabela jovens através do campo jovem_id

CREATE TABLE IF NOT EXISTS public.dados_nucleo (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    jovem_id UUID NOT NULL REFERENCES public.jovens(id) ON DELETE CASCADE,
    
    -- Pergunta principal
    faz_nucleo BOOLEAN DEFAULT NULL,
    ja_fez_nucleo BOOLEAN DEFAULT NULL,
    
    -- Campos quando faz núcleo
    dias_semana JSONB DEFAULT NULL, -- Array com os dias da semana: ["segunda", "terca", "quarta", "quinta", "sexta", "sabado", "domingo"]
    ha_quanto_tempo TEXT DEFAULT NULL,
    foi_voce_que_iniciou BOOLEAN DEFAULT NULL,
    media_pessoas INTEGER DEFAULT NULL,
    
    -- Fotos do núcleo (máximo 5)
    foto_1 TEXT DEFAULT NULL,
    foto_2 TEXT DEFAULT NULL,
    foto_3 TEXT DEFAULT NULL,
    foto_4 TEXT DEFAULT NULL,
    foto_5 TEXT DEFAULT NULL,
    
    -- Vídeo do núcleo
    video_link TEXT DEFAULT NULL,
    video_plataforma TEXT DEFAULT NULL, -- youtube, google_drive, instagram, facebook
    
    -- Campos sobre obreiros e ajuda
    tem_obreiros BOOLEAN DEFAULT NULL,
    quantos_obreiros INTEGER DEFAULT NULL,
    alguem_ajuda BOOLEAN DEFAULT NULL,
    quem_ajuda TEXT DEFAULT NULL,
    
    -- Campos sobre frequência e experiência
    quantas_pessoas_vao_igreja INTEGER DEFAULT NULL,
    maior_experiencia TEXT DEFAULT NULL,
    observacao_geral TEXT DEFAULT NULL,
    
    -- Campos de controle
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    criado_por UUID REFERENCES public.usuarios(id),
    atualizado_por UUID REFERENCES public.usuarios(id)
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_dados_nucleo_jovem_id ON public.dados_nucleo(jovem_id);
CREATE INDEX IF NOT EXISTS idx_dados_nucleo_faz_nucleo ON public.dados_nucleo(faz_nucleo);
CREATE INDEX IF NOT EXISTS idx_dados_nucleo_criado_em ON public.dados_nucleo(criado_em);

-- Trigger para atualizar campo atualizado_em
CREATE OR REPLACE FUNCTION update_dados_nucleo_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.atualizado_em = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_dados_nucleo_updated_at
    BEFORE UPDATE ON public.dados_nucleo
    FOR EACH ROW
    EXECUTE FUNCTION update_dados_nucleo_updated_at();

-- Comentários para documentação
COMMENT ON TABLE public.dados_nucleo IS 'Tabela para armazenar dados sobre núcleos de oração dos jovens';
COMMENT ON COLUMN public.dados_nucleo.jovem_id IS 'ID do jovem relacionado';
COMMENT ON COLUMN public.dados_nucleo.faz_nucleo IS 'Se o jovem faz núcleo atualmente';
COMMENT ON COLUMN public.dados_nucleo.ja_fez_nucleo IS 'Se o jovem já fez núcleo no passado';
COMMENT ON COLUMN public.dados_nucleo.dias_semana IS 'Array JSON com os dias da semana que o núcleo acontece';
COMMENT ON COLUMN public.dados_nucleo.ha_quanto_tempo IS 'Há quanto tempo faz núcleo';
COMMENT ON COLUMN public.dados_nucleo.foi_voce_que_iniciou IS 'Se foi o jovem que iniciou o núcleo';
COMMENT ON COLUMN public.dados_nucleo.media_pessoas IS 'Média de pessoas que participam do núcleo';
COMMENT ON COLUMN public.dados_nucleo.foto_1 IS 'URL da foto 1 do núcleo';
COMMENT ON COLUMN public.dados_nucleo.foto_2 IS 'URL da foto 2 do núcleo';
COMMENT ON COLUMN public.dados_nucleo.foto_3 IS 'URL da foto 3 do núcleo';
COMMENT ON COLUMN public.dados_nucleo.foto_4 IS 'URL da foto 4 do núcleo';
COMMENT ON COLUMN public.dados_nucleo.foto_5 IS 'URL da foto 5 do núcleo';
COMMENT ON COLUMN public.dados_nucleo.video_link IS 'Link do vídeo do núcleo';
COMMENT ON COLUMN public.dados_nucleo.video_plataforma IS 'Plataforma do vídeo (youtube, google_drive, instagram, facebook)';
COMMENT ON COLUMN public.dados_nucleo.tem_obreiros IS 'Se tem obreiros no núcleo';
COMMENT ON COLUMN public.dados_nucleo.quantos_obreiros IS 'Quantos obreiros tem no núcleo';
COMMENT ON COLUMN public.dados_nucleo.alguem_ajuda IS 'Se alguém ajuda no núcleo';
COMMENT ON COLUMN public.dados_nucleo.quem_ajuda IS 'Quem ajuda no núcleo';
COMMENT ON COLUMN public.dados_nucleo.quantas_pessoas_vao_igreja IS 'Quantas pessoas do núcleo vão à igreja';
COMMENT ON COLUMN public.dados_nucleo.maior_experiencia IS 'Maior experiência no núcleo';
COMMENT ON COLUMN public.dados_nucleo.observacao_geral IS 'Observação geral sobre o núcleo';
