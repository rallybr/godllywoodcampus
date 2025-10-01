-- =====================================================
-- SCRIPT PARA RESTAURAR ESTRUTURA ORIGINAL DO BANCO
-- =====================================================
-- Este script restaura a estrutura completa que estava funcionando
-- Execute este script no seu banco de dados Supabase

-- =====================================================
-- PARTE 1: LIMPEZA INICIAL (OPCIONAL)
-- =====================================================
-- Descomente as linhas abaixo se quiser limpar tudo antes de restaurar
-- DROP SCHEMA public CASCADE;
-- CREATE SCHEMA public;
-- GRANT ALL ON SCHEMA public TO postgres;
-- GRANT ALL ON SCHEMA public TO public;

-- =====================================================
-- PARTE 2: CRIAR ENUMS NECESSÁRIOS
-- =====================================================
-- Criar enums se não existirem
DO $$ 
BEGIN
    -- Enum para status de aprovação
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'intellimen_aprovado_enum') THEN
        CREATE TYPE intellimen_aprovado_enum AS ENUM ('pre_aprovado', 'aprovado');
    END IF;
    
    -- Enum para avaliações (espírito, disposição, caráter)
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'avaliacao_espirito_enum') THEN
        CREATE TYPE avaliacao_espirito_enum AS ENUM ('excelente', 'bom', 'regular', 'ruim');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'avaliacao_disposicao_enum') THEN
        CREATE TYPE avaliacao_disposicao_enum AS ENUM ('excelente', 'bom', 'regular', 'ruim');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'avaliacao_caractere_enum') THEN
        CREATE TYPE avaliacao_caractere_enum AS ENUM ('excelente', 'bom', 'regular', 'ruim');
    END IF;
END $$;

-- =====================================================
-- PARTE 3: CRIAR TABELAS
-- =====================================================

-- Tabela aprovacoes_jovens
CREATE TABLE IF NOT EXISTS public.aprovacoes_jovens (
  atualizado_em timestamp with time zone DEFAULT now(),
  tipo_aprovacao text NOT NULL,
  observacao text,
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  jovem_id uuid NOT NULL,
  usuario_id uuid NOT NULL,
  criado_em timestamp with time zone DEFAULT now()
);

-- Tabela avaliacoes
CREATE TABLE IF NOT EXISTS public.avaliacoes (
  espirito avaliacao_espirito_enum,
  user_id uuid,
  jovem_id uuid,
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  avaliacao_texto text,
  data timestamp without time zone DEFAULT now(),
  criado_em timestamp with time zone DEFAULT now(),
  nota integer,
  disposicao avaliacao_disposicao_enum,
  caractere avaliacao_caractere_enum
);

-- Tabela blocos
CREATE TABLE IF NOT EXISTS public.blocos (
  estado_id uuid,
  nome text NOT NULL,
  id uuid NOT NULL DEFAULT gen_random_uuid()
);

-- Tabela configuracoes_sistema
CREATE TABLE IF NOT EXISTS public.configuracoes_sistema (
  atualizado_em timestamp with time zone DEFAULT now(),
  categoria character varying DEFAULT 'geral'::character varying,
  chave character varying NOT NULL,
  descricao text,
  criado_em timestamp with time zone DEFAULT now(),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  valor jsonb NOT NULL
);

-- Tabela dados_viagem
CREATE TABLE IF NOT EXISTS public.dados_viagem (
  comprovante_passagem_volta text,
  data_passagem_ida timestamp with time zone,
  pagou_despesas boolean NOT NULL DEFAULT false,
  usuario_id uuid,
  data_cadastro timestamp with time zone NOT NULL DEFAULT now(),
  atualizado_em timestamp with time zone NOT NULL DEFAULT now(),
  data_passagem_volta timestamp with time zone,
  comprovante_pagamento text,
  edicao_id uuid NOT NULL,
  jovem_id uuid NOT NULL,
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  comprovante_passagem_ida text
);

-- Tabela edicoes
CREATE TABLE IF NOT EXISTS public.edicoes (
  nome text NOT NULL,
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  numero integer NOT NULL,
  data_inicio date,
  data_fim date,
  ativa boolean DEFAULT true,
  criado_em timestamp with time zone DEFAULT now()
);

-- Tabela estados
CREATE TABLE IF NOT EXISTS public.estados (
  bandeira text,
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  nome text NOT NULL,
  sigla text NOT NULL
);

-- Tabela igrejas
CREATE TABLE IF NOT EXISTS public.igrejas (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  regiao_id uuid,
  nome text NOT NULL,
  endereco text
);

-- Tabela jovens
CREATE TABLE IF NOT EXISTS public.jovens (
  formado_intellimen boolean DEFAULT false,
  tem_filho boolean,
  trabalha boolean,
  tem_dividas boolean,
  batizado_aguas boolean,
  data_batismo_aguas date,
  batizado_es boolean,
  data_batismo_es date,
  disposto_servir boolean,
  ja_obra_altar boolean,
  ja_obreiro boolean,
  ja_colaborador boolean,
  afastado boolean,
  data_afastamento date,
  data_retorno date,
  pais_na_igreja boolean,
  familiares_igreja boolean,
  deseja_altar boolean,
  aprovado intellimen_aprovado_enum DEFAULT 'null'::intellimen_aprovado_enum,
  cresceu_na_igreja boolean,
  experiencia_altar boolean,
  foi_obreiro boolean,
  foi_colaborador boolean,
  afastou boolean,
  quando_afastou date,
  quando_voltou date,
  pais_sao_igreja boolean,
  edicao_id uuid,
  idade integer,
  fazendo_desafios boolean DEFAULT false,
  valor_divida numeric,
  usuario_id uuid,
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  estado_id uuid,
  bloco_id uuid,
  regiao_id uuid,
  igreja_id uuid,
  data_nasc date NOT NULL,
  data_cadastro timestamp with time zone DEFAULT now(),
  namora boolean,
  motivo_afastamento text,
  qual_desafio text,
  observacao_pais text,
  condicao_campus text,
  observacao text,
  testemunho text,
  instagram text,
  facebook text,
  tiktok text,
  obs_redes text,
  pastor_que_indicou text,
  edicao text NOT NULL,
  foto text,
  nome_completo text NOT NULL,
  whatsapp text,
  estado_civil text,
  motivo_afastou text,
  local_trabalho text,
  escolaridade text,
  formacao text,
  tempo_igreja text,
  obs_pais text,
  observacao_text text,
  testemunho_text text,
  condicao text,
  tempo_condicao text,
  responsabilidade_igreja text,
  sexo text,
  observacao_redes text
);

-- Tabela jovens_view (view materializada)
CREATE TABLE IF NOT EXISTS public.jovens_view (
  formacao text,
  escolaridade text,
  local_trabalho text,
  edicao text,
  foto text,
  nome_completo text,
  numero_whatsapp text,
  estado_civil text,
  afastado boolean,
  ja_colaborador boolean,
  ja_obreiro boolean,
  idade integer,
  aprovado intellimen_aprovado_enum,
  deseja_altar boolean,
  ja_obra_altar boolean,
  familiares_igreja boolean,
  pais_na_igreja boolean,
  disposto_servir boolean,
  data_batismo_es date,
  batizado_es boolean,
  data_batismo_aguas date,
  batizado_aguas boolean,
  tem_dividas boolean,
  trabalha boolean,
  tem_filho boolean,
  namora boolean,
  data_cadastro timestamp with time zone,
  observacao text,
  testemunho text,
  link_instagram text,
  link_facebook text,
  link_tiktok text,
  observacao_redes text,
  data_nasc date,
  igreja_id uuid,
  regiao_id uuid,
  bloco_id uuid,
  estado_id uuid,
  id uuid,
  data_retorno date,
  observacao_pais text,
  motivo_afastamento text,
  data_afastamento date,
  responsabilidade_igreja text,
  tempo_condicao text,
  condicao text,
  tempo_igreja text
);

-- Tabela logs_auditoria
CREATE TABLE IF NOT EXISTS public.logs_auditoria (
  dados_novos jsonb,
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  usuario_id uuid,
  dados_antigos jsonb,
  ip_address inet,
  criado_em timestamp with time zone DEFAULT now(),
  user_agent text,
  acao character varying NOT NULL,
  detalhe text NOT NULL
);

-- Tabela logs_historico
CREATE TABLE IF NOT EXISTS public.logs_historico (
  acao text NOT NULL,
  dados_novos jsonb,
  detalhe text,
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  created_at timestamp with time zone DEFAULT now(),
  jovem_id uuid,
  user_id uuid,
  dados_anteriores jsonb
);

-- Tabela notificacoes
CREATE TABLE IF NOT EXISTS public.notificacoes (
  remetente_id uuid,
  acao_url text,
  mensagem text NOT NULL,
  titulo character varying NOT NULL,
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  destinatario_id uuid NOT NULL,
  tipo character varying NOT NULL,
  jovem_id uuid,
  lida boolean DEFAULT false,
  lida_em timestamp with time zone,
  criado_em timestamp with time zone DEFAULT now(),
  atualizado_em timestamp with time zone DEFAULT now()
);

-- Tabela regioes
CREATE TABLE IF NOT EXISTS public.regioes (
  nome text NOT NULL,
  bloco_id uuid,
  id uuid NOT NULL DEFAULT gen_random_uuid()
);

-- Tabela roles
CREATE TABLE IF NOT EXISTS public.roles (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  slug text NOT NULL,
  nome text NOT NULL,
  nivel_hierarquico integer NOT NULL,
  descricao text,
  criado_em timestamp with time zone DEFAULT now()
);

-- Tabela sessoes_usuario
CREATE TABLE IF NOT EXISTS public.sessoes_usuario (
  ativo boolean DEFAULT true,
  user_agent text,
  atualizado_em timestamp with time zone DEFAULT now(),
  criado_em timestamp with time zone DEFAULT now(),
  expira_em timestamp with time zone NOT NULL,
  ip_address inet,
  token_hash character varying NOT NULL,
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  usuario_id uuid NOT NULL
);

-- Tabela user_roles
CREATE TABLE IF NOT EXISTS public.user_roles (
  estado_id uuid,
  ativo boolean DEFAULT true,
  igreja_id uuid,
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  regiao_id uuid,
  bloco_id uuid,
  user_id uuid,
  criado_por uuid,
  criado_em timestamp with time zone DEFAULT now(),
  role_id uuid
);

-- Tabela usuarios
CREATE TABLE IF NOT EXISTS public.usuarios (
  criado_em timestamp with time zone DEFAULT now(),
  igreja_id uuid,
  regiao_id uuid,
  foto text,
  estado_id uuid,
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  estado_bandeira text,
  email text,
  bloco_id uuid,
  nivel text NOT NULL,
  sexo text,
  id_auth uuid,
  nome text NOT NULL,
  ultimo_acesso timestamp with time zone,
  ativo boolean DEFAULT true
);

-- =====================================================
-- PARTE 4: CRIAR CHAVES PRIMÁRIAS E ESTRANGEIRAS
-- =====================================================

-- Chaves primárias
ALTER TABLE public.aprovacoes_jovens ADD CONSTRAINT aprovacoes_jovens_pkey PRIMARY KEY (id);
ALTER TABLE public.avaliacoes ADD CONSTRAINT avaliacoes_pkey PRIMARY KEY (id);
ALTER TABLE public.blocos ADD CONSTRAINT blocos_pkey PRIMARY KEY (id);
ALTER TABLE public.configuracoes_sistema ADD CONSTRAINT configuracoes_sistema_pkey PRIMARY KEY (id);
ALTER TABLE public.dados_viagem ADD CONSTRAINT dados_viagem_pkey PRIMARY KEY (id);
ALTER TABLE public.edicoes ADD CONSTRAINT edicoes_pkey PRIMARY KEY (id);
ALTER TABLE public.estados ADD CONSTRAINT estados_pkey PRIMARY KEY (id);
ALTER TABLE public.igrejas ADD CONSTRAINT igrejas_pkey PRIMARY KEY (id);
ALTER TABLE public.jovens ADD CONSTRAINT jovens_pkey PRIMARY KEY (id);
ALTER TABLE public.logs_auditoria ADD CONSTRAINT logs_auditoria_pkey PRIMARY KEY (id);
ALTER TABLE public.logs_historico ADD CONSTRAINT logs_historico_pkey PRIMARY KEY (id);
ALTER TABLE public.notificacoes ADD CONSTRAINT notificacoes_pkey PRIMARY KEY (id);
ALTER TABLE public.regioes ADD CONSTRAINT regioes_pkey PRIMARY KEY (id);
ALTER TABLE public.roles ADD CONSTRAINT roles_pkey PRIMARY KEY (id);
ALTER TABLE public.sessoes_usuario ADD CONSTRAINT sessoes_usuario_pkey PRIMARY KEY (id);
ALTER TABLE public.user_roles ADD CONSTRAINT user_roles_pkey PRIMARY KEY (id);
ALTER TABLE public.usuarios ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id);

-- Chaves estrangeiras (se necessário)
-- Adicione as foreign keys conforme sua estrutura de relacionamentos

-- =====================================================
-- PARTE 5: CRIAR ÍNDICES
-- =====================================================

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_aprovacoes_jovem_id ON public.aprovacoes_jovens(jovem_id);
CREATE INDEX IF NOT EXISTS idx_aprovacoes_usuario_id ON public.aprovacoes_jovens(usuario_id);
CREATE INDEX IF NOT EXISTS idx_avaliacoes_jovem_id ON public.avaliacoes(jovem_id);
CREATE INDEX IF NOT EXISTS idx_avaliacoes_user_id ON public.avaliacoes(user_id);
CREATE INDEX IF NOT EXISTS idx_jovens_estado_id ON public.jovens(estado_id);
CREATE INDEX IF NOT EXISTS idx_jovens_bloco_id ON public.jovens(bloco_id);
CREATE INDEX IF NOT EXISTS idx_jovens_regiao_id ON public.jovens(regiao_id);
CREATE INDEX IF NOT EXISTS idx_jovens_igreja_id ON public.jovens(igreja_id);
CREATE INDEX IF NOT EXISTS idx_jovens_usuario_id ON public.jovens(usuario_id);
CREATE INDEX IF NOT EXISTS idx_usuarios_id_auth ON public.usuarios(id_auth);
CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON public.user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role_id ON public.user_roles(role_id);

-- =====================================================
-- PARTE 6: HABILITAR RLS
-- =====================================================

-- Habilitar Row Level Security em todas as tabelas
ALTER TABLE public.aprovacoes_jovens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.avaliacoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blocos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.configuracoes_sistema ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dados_viagem ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.edicoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.estados ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.igrejas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jovens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.logs_auditoria ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.logs_historico ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notificacoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.regioes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessoes_usuario ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- PARTE 7: CRIAR FUNÇÕES AUXILIARES BÁSICAS
-- =====================================================

-- Função has_role
CREATE OR REPLACE FUNCTION public.has_role(role_slug text)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_roles ur
    JOIN public.roles r ON r.id = ur.role_id
    WHERE ur.user_id = (SELECT id FROM public.usuarios WHERE id_auth = auth.uid())
      AND r.slug = role_slug
  );
$$;

-- Função para atualizar timestamp
CREATE OR REPLACE FUNCTION public.atualizar_timestamp()
RETURNS trigger
LANGUAGE plpgsql
AS $$
begin 
  new.atualizado_em = now(); 
  return new; 
end $$;

-- Função para atualizar timestamp de aprovações
CREATE OR REPLACE FUNCTION public.atualizar_timestamp_aprovacoes()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.atualizado_em = now();
  RETURN NEW;
END;
$$;

-- Função para recalcular idade
CREATE OR REPLACE FUNCTION public.recalcular_idade()
RETURNS trigger
LANGUAGE plpgsql
AS $$
begin
  new.idade = date_part('year', age(new.data_nasc))::int;
  return new;
end;
$$;

-- Função para setar usuario_id automaticamente
CREATE OR REPLACE FUNCTION public.set_usuario_id_on_insert()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NEW.usuario_id IS NULL THEN
    NEW.usuario_id := (SELECT id FROM public.usuarios WHERE id_auth = auth.uid());
  END IF;
  RETURN NEW;
END;
$$;

-- Função para setar usuario_id em dados_viagem
CREATE OR REPLACE FUNCTION public.set_usuario_id_dados_viagem()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
begin
  if new.usuario_id is null then
    new.usuario_id := (select id from public.usuarios where id_auth = auth.uid());
  end if;
  return new;
end;
$$;

-- =====================================================
-- PARTE 8: CRIAR TRIGGERS
-- =====================================================

-- Triggers para atualizar timestamp
CREATE TRIGGER trigger_atualizar_timestamp_usuarios
  BEFORE UPDATE ON public.usuarios
  FOR EACH ROW
  EXECUTE FUNCTION public.atualizar_timestamp();

CREATE TRIGGER trigger_atualizar_timestamp_notificacoes
  BEFORE UPDATE ON public.notificacoes
  FOR EACH ROW
  EXECUTE FUNCTION public.atualizar_timestamp();

CREATE TRIGGER trigger_atualizar_timestamp_configuracoes
  BEFORE UPDATE ON public.configuracoes_sistema
  FOR EACH ROW
  EXECUTE FUNCTION public.atualizar_timestamp();

CREATE TRIGGER trigger_atualizar_timestamp_aprovacoes
  BEFORE UPDATE ON public.aprovacoes_jovens
  FOR EACH ROW
  EXECUTE FUNCTION public.atualizar_timestamp_aprovacoes();

-- Triggers para recalcular idade
CREATE TRIGGER trigger_recalcular_idade
  BEFORE INSERT OR UPDATE ON public.jovens
  FOR EACH ROW
  EXECUTE FUNCTION public.recalcular_idade();

-- Triggers para setar usuario_id
CREATE TRIGGER trigger_set_usuario_id_jovens
  BEFORE INSERT ON public.jovens
  FOR EACH ROW
  EXECUTE FUNCTION public.set_usuario_id_on_insert();

CREATE TRIGGER trigger_set_usuario_id_avaliacoes
  BEFORE INSERT ON public.avaliacoes
  FOR EACH ROW
  EXECUTE FUNCTION public.set_usuario_id_on_insert();

CREATE TRIGGER trigger_set_usuario_id_dados_viagem
  BEFORE INSERT ON public.dados_viagem
  FOR EACH ROW
  EXECUTE FUNCTION public.set_usuario_id_dados_viagem();

-- =====================================================
-- PARTE 9: CRIAR POLICIES BÁSICAS
-- =====================================================

-- Policies para aprovacoes_jovens
CREATE POLICY allow_read_aprovacoes_jovens ON aprovacoes_jovens FOR r USING (true);

-- Policies para avaliacoes
CREATE POLICY Allow all for admin ON avaliacoes USING (has_role('administrador'::text));
CREATE POLICY Allow insert for authenticated users ON avaliacoes FOR a WITH CHECK ((auth.role() = 'authenticated'::text));
CREATE POLICY Allow read for authenticated users ON avaliacoes FOR r USING ((auth.role() = 'authenticated'::text));
CREATE POLICY Allow update for authenticated users ON avaliacoes FOR w USING ((auth.role() = 'authenticated'::text));

-- Policies para blocos
CREATE POLICY blocos_select_all ON blocos FOR r USING (true);
CREATE POLICY blocos_insert_admin ON blocos FOR a WITH CHECK (((EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = 'administrador'::text)))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_nacional_iurd'::text, 'lider_nacional_fju'::text]))))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_estadual_iurd'::text, 'lider_estadual_fju'::text])) AND (u.estado_id = blocos.estado_id))))));
CREATE POLICY blocos_update_admin ON blocos FOR w USING (((EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = 'administrador'::text)))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_nacional_iurd'::text, 'lider_nacional_fju'::text]))))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_estadual_iurd'::text, 'lider_estadual_fju'::text])) AND (u.estado_id = blocos.estado_id)))))) WITH CHECK (((EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = 'administrador'::text)))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_nacional_iurd'::text, 'lider_nacional_fju'::text]))))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_estadual_iurd'::text, 'lider_estadual_fju'::text])) AND (u.estado_id = blocos.estado_id))))));
CREATE POLICY blocos_delete_admin ON blocos FOR d USING ((EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = 'administrador'::text)))));

-- Policies para configuracoes_sistema
CREATE POLICY allow_read_configuracoes_sistema ON configuracoes_sistema FOR r USING (true);

-- Policies para dados_viagem
CREATE POLICY Acesso Geral ON dados_viagem USING (true) WITH CHECK (true);
CREATE POLICY Allow all for admin ON dados_viagem USING (has_role('administrador'::text));
CREATE POLICY Allow insert for authenticated users ON dados_viagem FOR a WITH CHECK ((auth.role() = 'authenticated'::text));
CREATE POLICY Allow update for authenticated users ON dados_viagem FOR w USING ((auth.role() = 'authenticated'::text));

-- Policies para edicoes
CREATE POLICY Edições são visíveis para todos ON edicoes FOR r TO authenticated USING (true);
CREATE POLICY allow_read_all_edicoes ON edicoes FOR r USING (true);

-- Policies para estados
CREATE POLICY Estados são visíveis para todos ON estados FOR r TO authenticated USING (true);
CREATE POLICY allow_read_all_estados ON estados FOR r USING (true);

-- Policies para igrejas
CREATE POLICY igrejas_select_all ON igrejas FOR r USING (true);
CREATE POLICY igrejas_insert_admin ON igrejas FOR a WITH CHECK (((EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = 'administrador'::text)))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_nacional_iurd'::text, 'lider_nacional_fju'::text]))))) OR (EXISTS ( SELECT 1
   FROM (usuarios u
     JOIN blocos b ON ((b.id = ( SELECT r.bloco_id
           FROM regioes r
          WHERE (r.id = igrejas.regiao_id)))))
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_estadual_iurd'::text, 'lider_estadual_fju'::text])) AND (u.estado_id = b.estado_id)))) OR (EXISTS ( SELECT 1
   FROM (usuarios u
     JOIN regioes r ON ((r.id = igrejas.regiao_id)))
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_bloco_iurd'::text, 'lider_bloco_fju'::text])) AND (u.bloco_id = r.bloco_id)))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = 'lider_regional_iurd'::text) AND (u.regiao_id = igrejas.regiao_id))))));
CREATE POLICY igrejas_update_admin ON igrejas FOR w USING (((EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = 'administrador'::text)))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_nacional_iurd'::text, 'lider_nacional_fju'::text]))))) OR (EXISTS ( SELECT 1
   FROM (usuarios u
     JOIN blocos b ON ((b.id = ( SELECT r.bloco_id
           FROM regioes r
          WHERE (r.id = igrejas.regiao_id)))))
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_estadual_iurd'::text, 'lider_estadual_fju'::text])) AND (u.estado_id = b.estado_id)))) OR (EXISTS ( SELECT 1
   FROM (usuarios u
     JOIN regioes r ON ((r.id = igrejas.regiao_id)))
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_bloco_iurd'::text, 'lider_bloco_fju'::text])) AND (u.bloco_id = r.bloco_id)))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = 'lider_regional_iurd'::text) AND (u.regiao_id = igrejas.regiao_id)))))) WITH CHECK (((EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = 'administrador'::text)))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_nacional_iurd'::text, 'lider_nacional_fju'::text]))))) OR (EXISTS ( SELECT 1
   FROM (usuarios u
     JOIN blocos b ON ((b.id = ( SELECT r.bloco_id
           FROM regioes r
          WHERE (r.id = igrejas.regiao_id)))))
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_estadual_iurd'::text, 'lider_estadual_fju'::text])) AND (u.estado_id = b.estado_id)))) OR (EXISTS ( SELECT 1
   FROM (usuarios u
     JOIN regioes r ON ((r.id = igrejas.regiao_id)))
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_bloco_iurd'::text, 'lider_bloco_fju'::text])) AND (u.bloco_id = r.bloco_id)))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = 'lider_regional_iurd'::text) AND (u.regiao_id = igrejas.regiao_id))))));
CREATE POLICY igrejas_delete_admin ON igrejas FOR d USING ((EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = 'administrador'::text)))));

-- Policies para jovens
CREATE POLICY Allow all for admin ON jovens USING (has_role('administrador'::text));
CREATE POLICY Allow insert for authenticated users ON jovens FOR a WITH CHECK ((auth.role() = 'authenticated'::text));
CREATE POLICY Allow update for authenticated users ON jovens FOR w USING ((auth.role() = 'authenticated'::text));
CREATE POLICY jovens_read_authenticated_scoped ON jovens FOR r TO authenticated USING ((EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND ((u.nivel <> 'jovem'::text) OR ((u.nivel = 'jovem'::text) AND ((u.id = jovens.usuario_id) OR (jovens.usuario_id IS NULL))))))));

-- Policies para logs_auditoria
CREATE POLICY Allow all for admin ON logs_auditoria USING (has_role('administrador'::text));
CREATE POLICY Allow read for authenticated users ON logs_auditoria FOR r USING ((auth.role() = 'authenticated'::text));

-- Policies para notificacoes
CREATE POLICY Allow all for admin ON notificacoes USING (has_role('administrador'::text));
CREATE POLICY Allow insert for authenticated users ON notificacoes FOR a WITH CHECK ((auth.role() = 'authenticated'::text));
CREATE POLICY Allow read for authenticated users ON notificacoes FOR r USING ((auth.role() = 'authenticated'::text));
CREATE POLICY Allow update for authenticated users ON notificacoes FOR w USING ((auth.role() = 'authenticated'::text));

-- Policies para regioes
CREATE POLICY regioes_select_all ON regioes FOR r USING (true);
CREATE POLICY regioes_insert_admin ON regioes FOR a WITH CHECK (((EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = 'administrador'::text)))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_nacional_iurd'::text, 'lider_nacional_fju'::text]))))) OR (EXISTS ( SELECT 1
   FROM (usuarios u
     JOIN blocos b ON ((b.id = regioes.bloco_id)))
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_estadual_iurd'::text, 'lider_estadual_fju'::text])) AND (u.estado_id = b.estado_id)))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_bloco_iurd'::text, 'lider_bloco_fju'::text])) AND (u.bloco_id = regioes.bloco_id))))));
CREATE POLICY regioes_update_admin ON regioes FOR w USING (((EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = 'administrador'::text)))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_nacional_iurd'::text, 'lider_nacional_fju'::text]))))) OR (EXISTS ( SELECT 1
   FROM (usuarios u
     JOIN blocos b ON ((b.id = regioes.bloco_id)))
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_estadual_iurd'::text, 'lider_estadual_fju'::text])) AND (u.estado_id = b.estado_id)))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_bloco_iurd'::text, 'lider_bloco_fju'::text])) AND (u.bloco_id = regioes.bloco_id)))))) WITH CHECK (((EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = 'administrador'::text)))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_nacional_iurd'::text, 'lider_nacional_fju'::text]))))) OR (EXISTS ( SELECT 1
   FROM (usuarios u
     JOIN blocos b ON ((b.id = regioes.bloco_id)))
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_estadual_iurd'::text, 'lider_estadual_fju'::text])) AND (u.estado_id = b.estado_id)))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_bloco_iurd'::text, 'lider_bloco_fju'::text])) AND (u.bloco_id = regioes.bloco_id))))));
CREATE POLICY regioes_delete_admin ON regioes FOR d USING ((EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = 'administrador'::text)))));

-- Policies para roles
CREATE POLICY Allow all for admin ON roles USING (has_role('administrador'::text));
CREATE POLICY Allow read for authenticated users ON roles FOR r USING ((auth.role() = 'authenticated'::text));

-- Policies para sessoes_usuario
CREATE POLICY allow_read_sessoes_usuario ON sessoes_usuario FOR r USING (true);

-- Policies para user_roles
CREATE POLICY Allow all for admin ON user_roles USING (has_role('administrador'::text));
CREATE POLICY Allow delete for admin ON user_roles FOR d USING (has_role('administrador'::text));
CREATE POLICY Allow insert for admin ON user_roles FOR a WITH CHECK (has_role('administrador'::text));
CREATE POLICY Allow read for authenticated users ON user_roles FOR r USING ((auth.role() = 'authenticated'::text));
CREATE POLICY Allow update for admin ON user_roles FOR w USING (has_role('administrador'::text));

-- Policies para usuarios
CREATE POLICY Allow admin all access ON usuarios TO authenticated USING ((EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = 'administrador'::text)))));
CREATE POLICY Allow insert for signup ON usuarios FOR a TO authenticated WITH CHECK (true);
CREATE POLICY Allow select own profile ON usuarios FOR r TO authenticated USING ((id_auth = auth.uid()));
CREATE POLICY Allow update own profile ON usuarios FOR w TO authenticated USING ((id_auth = auth.uid())) WITH CHECK ((id_auth = auth.uid()));

-- =====================================================
-- FIM DO SCRIPT
-- =====================================================

-- Mensagem de sucesso
DO $$
BEGIN
    RAISE NOTICE 'Estrutura básica do banco de dados restaurada com sucesso!';
    RAISE NOTICE 'Próximo passo: Execute o script de funções completas.';
END $$;
