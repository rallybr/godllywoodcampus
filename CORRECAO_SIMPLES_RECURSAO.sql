-- =====================================================
-- CORREÇÃO SIMPLES - RECURSÃO INFINITA RLS
-- =====================================================
-- Data: 2024-12-19
-- Problema: Recursão infinita na política usuarios_admin_full
-- Solução: Apenas remover a política problemática

-- =====================================================
-- 1. CRIAR FUNÇÃO AUXILIAR (SE NÃO EXISTIR)
-- =====================================================

-- Função que verifica se o usuário atual é administrador
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
-- 2. REMOVER APENAS A POLÍTICA PROBLEMÁTICA
-- =====================================================

-- Remover apenas a política que causa recursão
drop policy if exists "usuarios_admin_full" on usuarios;

-- =====================================================
-- 3. CRIAR NOVA POLÍTICA SEM RECURSÃO
-- =====================================================

-- Política para administradores (usando função auxiliar)
create policy "usuarios_admin_policy" on usuarios
  for all
  using (is_admin_user());

-- =====================================================
-- 4. VERIFICAÇÃO
-- =====================================================

-- Verificar se a política foi criada
select policyname, cmd, qual 
from pg_policies 
where tablename = 'usuarios' 
and policyname = 'usuarios_admin_policy';

-- Teste da função auxiliar
select is_admin_user() as is_admin;

-- Teste básico (deve executar sem recursão)
select count(*) as total_usuarios from usuarios where id_auth = auth.uid();

-- Mensagem de sucesso
select 'Correção aplicada com sucesso! Recursão infinita resolvida.' as status;
