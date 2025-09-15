-- =====================================================
-- MIGRAÇÃO FINAL - INTELLIMEN CAMPUS
-- =====================================================
-- Script que verifica o estado atual e aplica apenas as mudanças necessárias

-- =====================================================
-- 1. VERIFICAR E CRIAR NOVAS TABELAS
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
  nivel_hierarquico int not null,
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
  acao text not null,
  detalhe text,
  dados_anteriores jsonb,
  dados_novos jsonb,
  created_at timestamptz default now()
);

-- =====================================================
-- 2. ADICIONAR CAMPOS FALTANTES (APENAS OS QUE NÃO EXISTEM)
-- =====================================================

-- Adicionar campos na tabela usuarios
do $$
begin
  -- Verificar e adicionar email
  if not exists (select 1 from information_schema.columns where table_name = 'usuarios' and column_name = 'email') then
    alter table usuarios add column email text;
  end if;
  
  -- Verificar e adicionar estado_bandeira
  if not exists (select 1 from information_schema.columns where table_name = 'usuarios' and column_name = 'estado_bandeira') then
    alter table usuarios add column estado_bandeira text;
  end if;
  
  -- Verificar e adicionar ativo
  if not exists (select 1 from information_schema.columns where table_name = 'usuarios' and column_name = 'ativo') then
    alter table usuarios add column ativo boolean default true;
  end if;
end $$;

-- Adicionar campos na tabela jovens
do $$
begin
  -- Verificar e adicionar campos novos
  if not exists (select 1 from information_schema.columns where table_name = 'jovens' and column_name = 'pastor_que_indicou') then
    alter table jovens add column pastor_que_indicou text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_name = 'jovens' and column_name = 'cresceu_na_igreja') then
    alter table jovens add column cresceu_na_igreja boolean;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_name = 'jovens' and column_name = 'experiencia_altar') then
    alter table jovens add column experiencia_altar boolean;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_name = 'jovens' and column_name = 'foi_obreiro') then
    alter table jovens add column foi_obreiro boolean;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_name = 'jovens' and column_name = 'foi_colaborador') then
    alter table jovens add column foi_colaborador boolean;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_name = 'jovens' and column_name = 'afastou') then
    alter table jovens add column afastou boolean;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_name = 'jovens' and column_name = 'quando_afastou') then
    alter table jovens add column quando_afastou date;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_name = 'jovens' and column_name = 'motivo_afastou') then
    alter table jovens add column motivo_afastou text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_name = 'jovens' and column_name = 'quando_voltou') then
    alter table jovens add column quando_voltou date;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_name = 'jovens' and column_name = 'pais_sao_igreja') then
    alter table jovens add column pais_sao_igreja boolean;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_name = 'jovens' and column_name = 'obs_pais') then
    alter table jovens add column obs_pais text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_name = 'jovens' and column_name = 'familiares_igreja') then
    alter table jovens add column familiares_igreja boolean;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_name = 'jovens' and column_name = 'deseja_altar') then
    alter table jovens add column deseja_altar boolean;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_name = 'jovens' and column_name = 'observacao_text') then
    alter table jovens add column observacao_text text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_name = 'jovens' and column_name = 'testemunho_text') then
    alter table jovens add column testemunho_text text;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_name = 'jovens' and column_name = 'edicao_id') then
    alter table jovens add column edicao_id uuid references edicoes(id);
  end if;
  
  if not exists (select 1 from information_schema.columns where table_name = 'jovens' and column_name = 'idade') then
    alter table jovens add column idade int;
  end if;
end $$;

-- Renomear campos que precisam ser renomeados (apenas se existirem)
do $$
begin
  -- Verificar e renomear numero_whatsapp para whatsapp
  if exists (select 1 from information_schema.columns where table_name = 'jovens' and column_name = 'numero_whatsapp') then
    alter table jovens rename column numero_whatsapp to whatsapp;
  end if;
  
  -- Verificar e renomear link_instagram para instagram
  if exists (select 1 from information_schema.columns where table_name = 'jovens' and column_name = 'link_instagram') then
    alter table jovens rename column link_instagram to instagram;
  end if;
  
  -- Verificar e renomear link_facebook para facebook
  if exists (select 1 from information_schema.columns where table_name = 'jovens' and column_name = 'link_facebook') then
    alter table jovens rename column link_facebook to facebook;
  end if;
  
  -- Verificar e renomear link_tiktok para tiktok
  if exists (select 1 from information_schema.columns where table_name = 'jovens' and column_name = 'link_tiktok') then
    alter table jovens rename column link_tiktok to tiktok;
  end if;
  
  -- Verificar e renomear observacao_redes para obs_redes
  if exists (select 1 from information_schema.columns where table_name = 'jovens' and column_name = 'observacao_redes') then
    alter table jovens rename column observacao_redes to obs_redes;
  end if;
end $$;

-- Adicionar campo data na tabela avaliacoes
do $$
begin
  if not exists (select 1 from information_schema.columns where table_name = 'avaliacoes' and column_name = 'data') then
    alter table avaliacoes add column data timestamp default now();
  end if;
end $$;

-- =====================================================
-- 3. INSERIR DADOS INICIAIS (APENAS SE NÃO EXISTIREM)
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
-- 4. MIGRAR DADOS EXISTENTES (APENAS SE NECESSÁRIO)
-- =====================================================

-- Migrar usuários existentes para o novo sistema de roles
insert into user_roles (user_id, role_id, ativo, criado_por)
select 
  u.id,
  r.id,
  true,
  u.id
from usuarios u
join roles r on r.slug = u.nivel
where u.nivel in ('administrador', 'colaborador')
  and not exists (select 1 from user_roles ur where ur.user_id = u.id and ur.role_id = r.id)
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
  and not exists (select 1 from user_roles ur where ur.user_id = u.id and ur.role_id = r.id)
on conflict do nothing;

-- Migrar jovens existentes para a edição ativa (3ª edição)
update jovens 
set edicao_id = (select id from edicoes where numero = 3 and ativa = true)
where edicao_id is null;

-- =====================================================
-- 5. ATIVAR RLS NAS NOVAS TABELAS
-- =====================================================

alter table edicoes enable row level security;
alter table roles enable row level security;
alter table user_roles enable row level security;
alter table logs_historico enable row level security;

-- =====================================================
-- 6. CRIAR POLICIES (APENAS SE NÃO EXISTIREM)
-- =====================================================

-- Policies para edicoes
do $$
begin
  if not exists (select 1 from pg_policies where tablename = 'edicoes' and policyname = 'edicoes_select_all') then
    create policy "edicoes_select_all" on edicoes for select using (true);
  end if;
end $$;

-- Policies para roles
do $$
begin
  if not exists (select 1 from pg_policies where tablename = 'roles' and policyname = 'roles_select_all') then
    create policy "roles_select_all" on roles for select using (true);
  end if;
end $$;

-- Policies para user_roles
do $$
begin
  if not exists (select 1 from pg_policies where tablename = 'user_roles' and policyname = 'user_roles_admin_full') then
    create policy "user_roles_admin_full" on user_roles
      for all
      using (exists (
        select 1 from usuarios u 
        where u.id_auth = auth.uid() 
        and u.nivel in ('administrador', 'colaborador')
      ));
  end if;
  
  if not exists (select 1 from pg_policies where tablename = 'user_roles' and policyname = 'user_roles_self_select') then
    create policy "user_roles_self_select" on user_roles
      for select
      using (user_id = (select id from usuarios where id_auth = auth.uid()));
  end if;
end $$;

-- Policies para logs_historico
do $$
begin
  if not exists (select 1 from pg_policies where tablename = 'logs_historico' and policyname = 'logs_admin_colab') then
    create policy "logs_admin_colab" on logs_historico
      for all
      using (exists (
        select 1 from usuarios u 
        where u.id_auth = auth.uid() 
        and u.nivel in ('administrador', 'colaborador')
      ));
  end if;
  
  if not exists (select 1 from pg_policies where tablename = 'logs_historico' and policyname = 'logs_lider_hierarchy') then
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
  end if;
end $$;

-- =====================================================
-- 7. ATUALIZAR POLICIES EXISTENTES (APENAS SE NECESSÁRIO)
-- =====================================================

-- Verificar se as policies antigas existem e atualizá-las
do $$
begin
  -- Atualizar policy usuarios_admin_full se existir
  if exists (select 1 from pg_policies where tablename = 'usuarios' and policyname = 'usuarios_admin_full') then
    drop policy "usuarios_admin_full" on usuarios;
    create policy "usuarios_admin_full" on usuarios
      for all
      using (exists (
        select 1 from user_roles ur
        join roles r on r.id = ur.role_id
        where ur.user_id = (select id from usuarios where id_auth = auth.uid())
        and r.slug = 'administrador'
        and ur.ativo = true
      ));
  end if;
end $$;

-- Atualizar policies de jovens
do $$
begin
  if exists (select 1 from pg_policies where tablename = 'jovens' and policyname = 'jovens_admin_colab') then
    drop policy "jovens_admin_colab" on jovens;
    create policy "jovens_admin_colab" on jovens
      for all
      using (exists (
        select 1 from user_roles ur
        join roles r on r.id = ur.role_id
        where ur.user_id = (select id from usuarios where id_auth = auth.uid())
        and r.slug in ('administrador', 'colaborador')
        and ur.ativo = true
      ));
  end if;
  
  if exists (select 1 from pg_policies where tablename = 'jovens' and policyname = 'jovens_lider_estadual') then
    drop policy "jovens_lider_estadual" on jovens;
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
  end if;
  
  if exists (select 1 from pg_policies where tablename = 'jovens' and policyname = 'jovens_lider_bloco') then
    drop policy "jovens_lider_bloco" on jovens;
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
  end if;
  
  if exists (select 1 from pg_policies where tablename = 'jovens' and policyname = 'jovens_lider_regiao') then
    drop policy "jovens_lider_regiao" on jovens;
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
  end if;
  
  if exists (select 1 from pg_policies where tablename = 'jovens' and policyname = 'jovens_lider_igreja') then
    drop policy "jovens_lider_igreja" on jovens;
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
  end if;
end $$;

-- Atualizar policies de avaliações
do $$
begin
  if exists (select 1 from pg_policies where tablename = 'avaliacoes' and policyname = 'avaliacoes_admin_colab') then
    drop policy "avaliacoes_admin_colab" on avaliacoes;
    create policy "avaliacoes_admin_colab" on avaliacoes
      for all
      using (exists (
        select 1 from user_roles ur
        join roles r on r.id = ur.role_id
        where ur.user_id = (select id from usuarios where id_auth = auth.uid())
        and r.slug in ('administrador', 'colaborador')
        and ur.ativo = true
      ));
  end if;
end $$;

-- =====================================================
-- 8. CRIAR ÍNDICES (APENAS SE NÃO EXISTIREM)
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
-- 9. CRIAR FUNÇÕES AUXILIARES
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
-- MIGRAÇÃO CONCLUÍDA
-- =====================================================
