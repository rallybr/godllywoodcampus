-- =====================================================
-- MIGRAÇÃO BANCO DE DADOS - INTELLIMEN CAMPUS
-- =====================================================
-- Este script atualiza a estrutura do banco de dados
-- conforme o roteiro atualizado do sistema

-- =====================================================
-- 1. CRIAR NOVAS TABELAS
-- =====================================================

-- Tabela de Edições
create table if not exists edicoes (
  id uuid primary key default gen_random_uuid(),
  numero int not null unique,
  nome text not null,
  data_inicio date,
  data_fim date,
  ativa boolean default true,
  criado_em timestamptz default now()
);

-- Tabela de Roles/Papéis
create table if not exists roles (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  nome text not null,
  descricao text,
  nivel_hierarquico int not null, -- 1=admin, 2=colab, 3=nacional, 4=estadual, 5=bloco, 6=regional, 7=igreja
  criado_em timestamptz default now()
);

-- Tabela de Relacionamento Usuário-Role-Localização
create table if not exists user_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references usuarios(id) on delete cascade,
  role_id uuid references roles(id) on delete cascade,
  estado_id uuid references estados(id),
  bloco_id uuid references blocos(id),
  regiao_id uuid references regioes(id),
  igreja_id uuid references igrejas(id),
  ativo boolean default true,
  criado_em timestamptz default now(),
  criado_por uuid references usuarios(id),
  unique(user_id, role_id, estado_id, bloco_id, regiao_id, igreja_id)
);

-- Tabela de Logs de Histórico
create table if not exists logs_historico (
  id uuid primary key default gen_random_uuid(),
  jovem_id uuid references jovens(id) on delete cascade,
  user_id uuid references usuarios(id),
  acao text not null, -- 'cadastro', 'edicao', 'avaliacao', 'aprovacao', 'transferencia_lideranca'
  detalhe text,
  dados_anteriores jsonb,
  dados_novos jsonb,
  created_at timestamptz default now()
);

-- =====================================================
-- 2. ADICIONAR CAMPOS FALTANTES NAS TABELAS EXISTENTES
-- =====================================================

-- Adicionar campos na tabela usuarios
alter table usuarios 
add column if not exists email text,
add column if not exists estado_bandeira text,
add column if not exists ativo boolean default true;

-- Adicionar campos na tabela jovens
alter table jovens
add column if not exists pastor_que_indicou text,
add column if not exists cresceu_na_igreja boolean,
add column if not exists experiencia_altar boolean,
add column if not exists foi_obreiro boolean,
add column if not exists foi_colaborador boolean,
add column if not exists afastou boolean,
add column if not exists quando_afastou date,
add column if not exists motivo_afastou text,
add column if not exists quando_voltou date,
add column if not exists pais_sao_igreja boolean,
add column if not exists obs_pais text,
add column if not exists familiares_igreja boolean,
add column if not exists deseja_altar boolean,
add column if not exists observacao_text text,
add column if not exists testemunho_text text,
add column if not exists edicao_id uuid references edicoes(id);

-- Renomear apenas campos que realmente precisam ser renomeados
alter table jovens rename column numero_whatsapp to whatsapp;
alter table jovens rename column link_instagram to instagram;
alter table jovens rename column link_facebook to facebook;
alter table jovens rename column link_tiktok to tiktok;
alter table jovens rename column observacao_redes to obs_redes;

-- Adicionar campos na tabela avaliacoes
alter table avaliacoes
add column if not exists data timestamp default now();

-- =====================================================
-- 3. INSERIR DADOS INICIAIS
-- =====================================================

-- Inserir edições (1ª a 10ª)
insert into edicoes (numero, nome, ativa) values
(1, '1ª Edição IntelliMen Campus', false),
(2, '2ª Edição IntelliMen Campus', false),
(3, '3ª Edição IntelliMen Campus', true),
(4, '4ª Edição IntelliMen Campus', false),
(5, '5ª Edição IntelliMen Campus', false),
(6, '6ª Edição IntelliMen Campus', false),
(7, '7ª Edição IntelliMen Campus', false),
(8, '8ª Edição IntelliMen Campus', false),
(9, '9ª Edição IntelliMen Campus', false),
(10, '10ª Edição IntelliMen Campus', false)
on conflict (numero) do nothing;

-- Inserir roles/papéis
insert into roles (slug, nome, descricao, nivel_hierarquico) values
('administrador', 'Administrador', 'Acesso total ao sistema', 1),
('colaborador', 'Colaborador', 'Acesso amplo para colaboração', 2),
('lider_nacional_iurd', 'Líder Nacional IURD', 'Responsável nacional IURD pelo projeto', 3),
('lider_nacional_fju', 'Líder Nacional FJU', 'Responsável nacional FJU pelo projeto', 3),
('lider_estadual_iurd', 'Líder Estadual IURD', 'Líder estadual IURD', 4),
('lider_estadual_fju', 'Líder Estadual FJU', 'Líder estadual FJU', 4),
('lider_bloco_iurd', 'Líder Bloco IURD', 'Líder de bloco IURD', 5),
('lider_bloco_fju', 'Líder Bloco FJU', 'Líder de bloco FJU', 5),
('lider_regional_iurd', 'Líder Regional IURD', 'Líder regional IURD', 6),
('lider_igreja_iurd', 'Líder Igreja IURD', 'Líder de igreja IURD', 7)
on conflict (slug) do nothing;

-- =====================================================
-- 4. MIGRAR DADOS EXISTENTES
-- =====================================================

-- Migrar usuários existentes para o novo sistema de roles
-- Assumindo que usuários existentes com nivel 'administrador' ou 'colaborador' mantêm seus papéis
insert into user_roles (user_id, role_id, ativo, criado_por)
select 
  u.id,
  r.id,
  true,
  u.id
from usuarios u
join roles r on r.slug = u.nivel
where u.nivel in ('administrador', 'colaborador')
on conflict do nothing;

-- Migrar usuários com níveis de liderança
insert into user_roles (user_id, role_id, estado_id, bloco_id, regiao_id, igreja_id, ativo, criado_por)
select 
  u.id,
  r.id,
  u.estado_id,
  u.bloco_id,
  u.regiao_id,
  u.igreja_id,
  true,
  u.id
from usuarios u
join roles r on r.slug = u.nivel
where u.nivel like 'lider_%'
on conflict do nothing;

-- Migrar jovens existentes para a edição ativa (3ª edição)
update jovens 
set edicao_id = (select id from edicoes where numero = 3 and ativa = true)
where edicao_id is null;

-- =====================================================
-- 5. ATUALIZAR RLS POLICIES
-- =====================================================

-- Ativar RLS nas novas tabelas
alter table edicoes enable row level security;
alter table roles enable row level security;
alter table user_roles enable row level security;
alter table logs_historico enable row level security;

-- Policies para edicoes (todos podem ver)
create policy "edicoes_select_all" on edicoes
  for select using (true);

-- Policies para roles (todos podem ver)
create policy "roles_select_all" on roles
  for select using (true);

-- Policies para user_roles
create policy "user_roles_admin_full" on user_roles
  for all
  using (exists (
    select 1 from usuarios u 
    where u.id_auth = auth.uid() 
    and u.nivel in ('administrador', 'colaborador')
  ));

create policy "user_roles_self_select" on user_roles
  for select
  using (user_id = (select id from usuarios where id_auth = auth.uid()));

-- Policies para logs_historico
create policy "logs_admin_colab" on logs_historico
  for all
  using (exists (
    select 1 from usuarios u 
    where u.id_auth = auth.uid() 
    and u.nivel in ('administrador', 'colaborador')
  ));

create policy "logs_lider_hierarchy" on logs_historico
  for select
  using (exists (
    select 1 from usuarios u 
    join user_roles ur on ur.user_id = u.id
    where u.id_auth = auth.uid() 
    and ur.ativo = true
    and (
      (ur.role_id = (select id from roles where slug = 'lider_estadual_iurd') and ur.estado_id = (select estado_id from jovens where id = logs_historico.jovem_id)) or
      (ur.role_id = (select id from roles where slug = 'lider_estadual_fju') and ur.estado_id = (select estado_id from jovens where id = logs_historico.jovem_id)) or
      (ur.role_id = (select id from roles where slug = 'lider_bloco_iurd') and ur.bloco_id = (select bloco_id from jovens where id = logs_historico.jovem_id)) or
      (ur.role_id = (select id from roles where slug = 'lider_bloco_fju') and ur.bloco_id = (select bloco_id from jovens where id = logs_historico.jovem_id)) or
      (ur.role_id = (select id from roles where slug = 'lider_regional_iurd') and ur.regiao_id = (select regiao_id from jovens where id = logs_historico.jovem_id)) or
      (ur.role_id = (select id from roles where slug = 'lider_igreja_iurd') and ur.igreja_id = (select igreja_id from jovens where id = logs_historico.jovem_id))
    )
  ));

-- =====================================================
-- 6. ATUALIZAR POLICIES EXISTENTES PARA NOVO SISTEMA
-- =====================================================

-- Remover policies antigas
drop policy if exists "usuarios_admin_full" on usuarios;
drop policy if exists "jovens_admin_colab" on jovens;
drop policy if exists "jovens_lider_estadual" on jovens;
drop policy if exists "jovens_lider_bloco" on jovens;
drop policy if exists "jovens_lider_regiao" on jovens;
drop policy if exists "jovens_lider_igreja" on jovens;
drop policy if exists "avaliacoes_admin_colab" on avaliacoes;

-- Criar novas policies baseadas no sistema de roles
create policy "usuarios_admin_full" on usuarios
  for all
  using (exists (
    select 1 from user_roles ur
    join roles r on r.id = ur.role_id
    where ur.user_id = (select id from usuarios where id_auth = auth.uid())
    and r.slug = 'administrador'
    and ur.ativo = true
  ));

create policy "usuarios_self_select" on usuarios
  for select
  using (id_auth = auth.uid());

create policy "usuarios_self_update" on usuarios
  for update
  using (id_auth = auth.uid());

-- Policies para jovens baseadas no novo sistema de roles
create policy "jovens_admin_colab" on jovens
  for all
  using (exists (
    select 1 from user_roles ur
    join roles r on r.id = ur.role_id
    where ur.user_id = (select id from usuarios where id_auth = auth.uid())
    and r.slug in ('administrador', 'colaborador')
    and ur.ativo = true
  ));

create policy "jovens_lider_estadual" on jovens
  for all
  using (exists (
    select 1 from user_roles ur
    join roles r on r.id = ur.role_id
    where ur.user_id = (select id from usuarios where id_auth = auth.uid())
    and r.slug in ('lider_estadual_iurd', 'lider_estadual_fju')
    and ur.estado_id = jovens.estado_id
    and ur.ativo = true
  ));

create policy "jovens_lider_bloco" on jovens
  for all
  using (exists (
    select 1 from user_roles ur
    join roles r on r.id = ur.role_id
    where ur.user_id = (select id from usuarios where id_auth = auth.uid())
    and r.slug in ('lider_bloco_iurd', 'lider_bloco_fju')
    and ur.bloco_id = jovens.bloco_id
    and ur.ativo = true
  ));

create policy "jovens_lider_regional" on jovens
  for all
  using (exists (
    select 1 from user_roles ur
    join roles r on r.id = ur.role_id
    where ur.user_id = (select id from usuarios where id_auth = auth.uid())
    and r.slug = 'lider_regional_iurd'
    and ur.regiao_id = jovens.regiao_id
    and ur.ativo = true
  ));

create policy "jovens_lider_igreja" on jovens
  for all
  using (exists (
    select 1 from user_roles ur
    join roles r on r.id = ur.role_id
    where ur.user_id = (select id from usuarios where id_auth = auth.uid())
    and r.slug = 'lider_igreja_iurd'
    and ur.igreja_id = jovens.igreja_id
    and ur.ativo = true
  ));

-- Policies para avaliações
create policy "avaliacoes_admin_colab" on avaliacoes
  for all
  using (exists (
    select 1 from user_roles ur
    join roles r on r.id = ur.role_id
    where ur.user_id = (select id from usuarios where id_auth = auth.uid())
    and r.slug in ('administrador', 'colaborador')
    and ur.ativo = true
  ));

create policy "avaliacoes_self" on avaliacoes
  for all
  using (user_id = (select id from usuarios where id_auth = auth.uid()));

-- =====================================================
-- 7. CRIAR ÍNDICES PARA NOVAS TABELAS
-- =====================================================

-- Índices para edicoes
create index if not exists idx_edicoes_numero on edicoes(numero);
create index if not exists idx_edicoes_ativa on edicoes(ativa);

-- Índices para roles
create index if not exists idx_roles_slug on roles(slug);
create index if not exists idx_roles_nivel on roles(nivel_hierarquico);

-- Índices para user_roles
create index if not exists idx_user_roles_user_id on user_roles(user_id);
create index if not exists idx_user_roles_role_id on user_roles(role_id);
create index if not exists idx_user_roles_estado_id on user_roles(estado_id);
create index if not exists idx_user_roles_bloco_id on user_roles(bloco_id);
create index if not exists idx_user_roles_regiao_id on user_roles(regiao_id);
create index if not exists idx_user_roles_igreja_id on user_roles(igreja_id);
create index if not exists idx_user_roles_ativo on user_roles(ativo);

-- Índices para logs_historico
create index if not exists idx_logs_jovem_id on logs_historico(jovem_id);
create index if not exists idx_logs_user_id on logs_historico(user_id);
create index if not exists idx_logs_acao on logs_historico(acao);
create index if not exists idx_logs_created_at on logs_historico(created_at);

-- Índices adicionais para jovens
create index if not exists idx_jovens_edicao_id on jovens(edicao_id);
create index if not exists idx_jovens_aprovado on jovens(aprovado);

-- =====================================================
-- 8. CRIAR FUNÇÕES AUXILIARES
-- =====================================================

-- Função para recalcular idade
create or replace function recalcular_idade()
returns trigger as $$
begin
  new.idade = date_part('year', age(new.data_nasc))::int;
  return new;
end;
$$ language plpgsql;

-- Trigger para atualizar idade automaticamente
drop trigger if exists trigger_recalcular_idade on jovens;
create trigger trigger_recalcular_idade
  before insert or update on jovens
  for each row execute function recalcular_idade();

-- Função para criar log de auditoria
create or replace function criar_log_auditoria(
  p_jovem_id uuid,
  p_acao text,
  p_detalhe text default null,
  p_dados_anteriores jsonb default null,
  p_dados_novos jsonb default null
)
returns void as $$
begin
  insert into logs_historico (jovem_id, user_id, acao, detalhe, dados_anteriores, dados_novos)
  values (
    p_jovem_id,
    (select id from usuarios where id_auth = auth.uid()),
    p_acao,
    p_detalhe,
    p_dados_anteriores,
    p_dados_novos
  );
end;
$$ language plpgsql security definer;

-- =====================================================
-- 9. COMENTÁRIOS E DOCUMENTAÇÃO
-- =====================================================

comment on table edicoes is 'Edições do IntelliMen Campus (1ª a 10ª)';
comment on table roles is 'Papéis/Roles do sistema com hierarquia';
comment on table user_roles is 'Relacionamento usuário-papel-localização';
comment on table logs_historico is 'Logs de auditoria para todas as ações importantes';

comment on column edicoes.numero is 'Número da edição (1-10)';
comment on column edicoes.ativa is 'Se a edição está ativa para novos cadastros';
comment on column roles.nivel_hierarquico is 'Nível hierárquico: 1=admin, 2=colab, 3=nacional, 4=estadual, 5=bloco, 6=regional, 7=igreja';
comment on column user_roles.ativo is 'Se o papel está ativo para o usuário';
comment on column logs_historico.acao is 'Tipo de ação: cadastro, edicao, avaliacao, aprovacao, transferencia_lideranca';

-- =====================================================
-- MIGRAÇÃO CONCLUÍDA
-- =====================================================
