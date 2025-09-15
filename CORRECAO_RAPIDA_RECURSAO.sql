-- =====================================================
-- CORREÇÃO RÁPIDA - RECURSÃO INFINITA RLS
-- =====================================================
-- Data: 2024-12-19
-- Problema: Recursão infinita na política usuarios_admin_full
-- Solução: Simplificar políticas para evitar consultas circulares

-- =====================================================
-- 1. REMOVER POLÍTICA PROBLEMÁTICA
-- =====================================================

-- Remover a política que causa recursão
drop policy if exists "usuarios_admin_full" on usuarios;

-- =====================================================
-- 2. CRIAR POLÍTICA SIMPLIFICADA
-- =====================================================

-- Política simplificada para administradores (sem recursão)
create policy "usuarios_admin_simple" on usuarios
  for all
  using (
    -- Verificar se o usuário tem role de administrador
    exists (
      select 1 from user_roles ur
      join roles r on r.id = ur.role_id
      where ur.user_id = (select id from usuarios where id_auth = auth.uid())
      and r.slug = 'administrador'
      and ur.ativo = true
    )
    -- OU se é o próprio usuário (para operações em si mesmo)
    or id_auth = auth.uid()
  );

-- =====================================================
-- 3. MANTER POLÍTICAS EXISTENTES (SEM ALTERAÇÃO)
-- =====================================================

-- As políticas usuarios_self_select e usuarios_self_update já estão corretas
-- e não causam recursão

-- =====================================================
-- 4. VERIFICAÇÃO
-- =====================================================

-- Verificar se a política foi criada
select policyname, cmd, qual 
from pg_policies 
where tablename = 'usuarios' 
and policyname = 'usuarios_admin_simple';

-- Teste básico (deve executar sem recursão)
select count(*) from usuarios where id_auth = auth.uid();
