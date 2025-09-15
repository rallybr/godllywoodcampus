-- =====================================================
-- SOLUÇÃO DEFINITIVA - RECURSÃO INFINITA RLS (V2)
-- =====================================================
-- Data: 2024-12-19
-- Problema: Recursão infinita na política usuarios_admin_full
-- Solução: Usar função auxiliar para evitar recursão
-- Versão: 2.0 - Com verificação de políticas existentes

-- =====================================================
-- 1. CRIAR FUNÇÃO AUXILIAR PARA EVITAR RECURSÃO
-- =====================================================

-- Função que verifica se o usuário atual é administrador
-- sem causar recursão
create or replace function is_admin_user()
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1 from user_roles ur
    join roles r on r.id = ur.role_id
    where ur.user_id = (select id from usuarios where id_auth = auth.uid())
    and r.slug = 'administrador'
    and ur.ativo = true
  );
$$;

-- =====================================================
-- 2. REMOVER POLÍTICAS PROBLEMÁTICAS
-- =====================================================

-- Remover todas as políticas que podem causar recursão
drop policy if exists "usuarios_admin_full" on usuarios;
drop policy if exists "usuarios_admin_simple" on usuarios;
drop policy if exists "usuarios_admin_policy" on usuarios;

-- =====================================================
-- 3. CRIAR POLÍTICAS CORRIGIDAS (COM VERIFICAÇÃO)
-- =====================================================

-- Política para administradores (usando função auxiliar)
create policy "usuarios_admin_policy" on usuarios
  for all
  using (is_admin_user());

-- Política para usuários verem seus próprios dados (apenas se não existir)
do $$
begin
  if not exists (select 1 from pg_policies where tablename = 'usuarios' and policyname = 'usuarios_self_select') then
    create policy "usuarios_self_select" on usuarios
      for select
      using (id_auth = auth.uid());
  else
    raise notice 'Política usuarios_self_select já existe, pulando criação.';
  end if;
end $$;

-- Política para usuários atualizarem seus próprios dados (apenas se não existir)
do $$
begin
  if not exists (select 1 from pg_policies where tablename = 'usuarios' and policyname = 'usuarios_self_update') then
    create policy "usuarios_self_update" on usuarios
      for update
      using (id_auth = auth.uid());
  else
    raise notice 'Política usuarios_self_update já existe, pulando criação.';
  end if;
end $$;

-- =====================================================
-- 4. VERIFICAÇÃO E TESTE
-- =====================================================

-- Verificar se as políticas foram criadas
select policyname, cmd, qual 
from pg_policies 
where tablename = 'usuarios'
order by policyname;

-- Teste da função auxiliar
select is_admin_user() as is_admin;

-- Teste básico (deve executar sem recursão)
select count(*) as total_usuarios from usuarios where id_auth = auth.uid();

-- Mostrar mensagem de sucesso
do $$
begin
  raise notice 'Script executado com sucesso! Recursão infinita corrigida.';
end $$;
