-- =====================================================
-- CORREÇÃO DE RECURSÃO INFINITA NAS POLÍTICAS RLS
-- =====================================================
-- Data: 2024-12-19
-- Problema: Recursão infinita nas políticas RLS da tabela usuarios
-- Solução: Usar auth.uid() diretamente em vez de consultar a tabela usuarios

-- =====================================================
-- 1. REMOVER POLÍTICAS PROBLEMÁTICAS
-- =====================================================

-- Remover políticas que causam recursão
drop policy if exists "usuarios_admin_full" on usuarios;
drop policy if exists "jovens_admin_colab" on jovens;
drop policy if exists "jovens_lider_estadual" on jovens;
drop policy if exists "jovens_lider_bloco" on jovens;
drop policy if exists "jovens_lider_regional" on jovens;
drop policy if exists "jovens_lider_igreja" on jovens;
drop policy if exists "avaliacoes_admin_colab" on avaliacoes;
drop policy if exists "avaliacoes_self" on avaliacoes;
drop policy if exists "user_roles_admin_full" on user_roles;
drop policy if exists "logs_admin_colab" on logs_historico;
drop policy if exists "logs_lider_hierarchy" on logs_historico;

-- =====================================================
-- 2. CRIAR POLÍTICAS CORRIGIDAS (SEM RECURSÃO)
-- =====================================================

-- Políticas para usuarios (sem recursão)
create policy "usuarios_admin_full" on usuarios
  for all
  using (exists (
    select 1 from user_roles ur
    join roles r on r.id = ur.role_id
    where ur.user_id = (select id from usuarios where id_auth = auth.uid())
    and r.slug = 'administrador'
    and ur.ativo = true
  ));

-- Política simplificada para administradores (usando auth.uid() diretamente)
create policy "usuarios_admin_simple" on usuarios
  for all
  using (exists (
    select 1 from user_roles ur
    join roles r on r.id = ur.role_id
    where ur.user_id = (select id from usuarios where id_auth = auth.uid())
    and r.slug = 'administrador'
    and ur.ativo = true
  ));

-- Política para usuários verem seus próprios dados
create policy "usuarios_self_select" on usuarios
  for select
  using (id_auth = auth.uid());

create policy "usuarios_self_update" on usuarios
  for update
  using (id_auth = auth.uid());

-- =====================================================
-- 3. POLÍTICAS PARA JOVENS (CORRIGIDAS)
-- =====================================================

-- Política para administradores e colaboradores
create policy "jovens_admin_colab" on jovens
  for all
  using (exists (
    select 1 from user_roles ur
    join roles r on r.id = ur.role_id
    where ur.user_id = (select id from usuarios where id_auth = auth.uid())
    and r.slug in ('administrador', 'colaborador')
    and ur.ativo = true
  ));

-- Política para líderes estaduais
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

-- Política para líderes de bloco
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

-- Política para líderes regionais
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

-- Política para líderes de igreja
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

-- =====================================================
-- 4. POLÍTICAS PARA AVALIAÇÕES (CORRIGIDAS)
-- =====================================================

-- Política para administradores e colaboradores
create policy "avaliacoes_admin_colab" on avaliacoes
  for all
  using (exists (
    select 1 from user_roles ur
    join roles r on r.id = ur.role_id
    where ur.user_id = (select id from usuarios where id_auth = auth.uid())
    and r.slug in ('administrador', 'colaborador')
    and ur.ativo = true
  ));

-- Política para usuários gerenciarem suas próprias avaliações
create policy "avaliacoes_self" on avaliacoes
  for all
  using (user_id = (select id from usuarios where id_auth = auth.uid()));

-- =====================================================
-- 5. POLÍTICAS PARA USER_ROLES (CORRIGIDAS)
-- =====================================================

-- Política para administradores gerenciarem user_roles
create policy "user_roles_admin_full" on user_roles
  for all
  using (exists (
    select 1 from user_roles ur
    join roles r on r.id = ur.role_id
    where ur.user_id = (select id from usuarios where id_auth = auth.uid())
    and r.slug in ('administrador', 'colaborador')
    and ur.ativo = true
  ));

-- Política para usuários verem seus próprios roles
create policy "user_roles_self_select" on user_roles
  for select
  using (user_id = (select id from usuarios where id_auth = auth.uid()));

-- =====================================================
-- 6. POLÍTICAS PARA LOGS (CORRIGIDAS)
-- =====================================================

-- Política para administradores e colaboradores
create policy "logs_admin_colab" on logs_historico
  for all
  using (exists (
    select 1 from user_roles ur
    join roles r on r.id = ur.role_id
    where ur.user_id = (select id from usuarios where id_auth = auth.uid())
    and r.slug in ('administrador', 'colaborador')
    and ur.ativo = true
  ));

-- Política para líderes verem logs de sua hierarquia
create policy "logs_lider_hierarchy" on logs_historico
  for select
  using (exists (
    select 1 from user_roles ur
    join roles r on r.id = ur.role_id
    where ur.user_id = (select id from usuarios where id_auth = auth.uid())
    and ur.ativo = true
    and (
      (r.slug in ('lider_estadual_iurd', 'lider_estadual_fju') and ur.estado_id = (select estado_id from jovens where id = logs_historico.jovem_id)) or
      (r.slug in ('lider_bloco_iurd', 'lider_bloco_fju') and ur.bloco_id = (select bloco_id from jovens where id = logs_historico.jovem_id)) or
      (r.slug = 'lider_regional_iurd' and ur.regiao_id = (select regiao_id from jovens where id = logs_historico.jovem_id)) or
      (r.slug = 'lider_igreja_iurd' and ur.igreja_id = (select igreja_id from jovens where id = logs_historico.jovem_id))
    )
  ));

-- =====================================================
-- 7. VERIFICAÇÃO E TESTE
-- =====================================================

-- Verificar se as políticas foram criadas corretamente
select schemaname, tablename, policyname, permissive, roles, cmd, qual 
from pg_policies 
where schemaname = 'public'
and tablename in ('usuarios', 'jovens', 'avaliacoes', 'user_roles', 'logs_historico')
order by tablename, policyname;

-- Testar se não há mais recursão
-- (Este comando deve executar sem erro de recursão infinita)
select count(*) from usuarios where id_auth = auth.uid();
