-- Script para ANÁLISE COMPLETA do sistema antes de qualquer alteração
-- Execute este script no Supabase SQL Editor para entender o estado atual

-- ============================================
-- 1. ANÁLISE DA TABELA JOVENS
-- ============================================

-- Verificar estrutura da tabela
SELECT 
  column_name as coluna,
  data_type as tipo,
  udt_name as tipo_udt,
  is_nullable as nullable,
  column_default as default_value
FROM information_schema.columns 
WHERE table_name = 'jovens' 
ORDER BY ordinal_position;

-- Verificar especificamente a coluna aprovado
SELECT 
  column_name as coluna,
  data_type as tipo,
  udt_name as tipo_udt,
  is_nullable as nullable,
  column_default as default_value
FROM information_schema.columns 
WHERE table_name = 'jovens' 
  AND column_name = 'aprovado';

-- Verificar se RLS está habilitado
SELECT 
  'RLS habilitado:' as status, 
  rowsecurity as rls_ativo,
  'Tabela jovens' as tabela
FROM pg_tables 
WHERE tablename = 'jovens';

-- ============================================
-- 2. ANÁLISE DAS POLÍTICAS EXISTENTES
-- ============================================

-- Contar políticas por comando
SELECT 
  cmd as comando,
  COUNT(*) as total_politicas,
  STRING_AGG(policyname, ', ') as nomes_politicas
FROM pg_policies 
WHERE tablename = 'jovens'
GROUP BY cmd
ORDER BY cmd;

-- Detalhes completos das políticas
SELECT 
  policyname as nome_politica,
  cmd as comando,
  permissive as permissiva,
  roles as roles_aplicadas,
  CASE 
    WHEN qual IS NULL THEN 'Sem condição USING'
    ELSE 'Com condição USING'
  END as tem_condicao_using,
  CASE 
    WHEN with_check IS NULL THEN 'Sem condição CHECK'
    ELSE 'Com condição CHECK'
  END as tem_condicao_check
FROM pg_policies 
WHERE tablename = 'jovens'
ORDER BY policyname;

-- ============================================
-- 3. ANÁLISE DA FUNÇÃO can_access_jovem
-- ============================================

-- Verificar se a função existe
SELECT 
  'Função can_access_jovem existe:' as status,
  EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' AND p.proname = 'can_access_jovem'
  ) as existe;

-- Se existir, mostrar detalhes
SELECT 
  p.proname as nome_funcao,
  pg_get_function_result(p.oid) as tipo_retorno,
  pg_get_function_arguments(p.oid) as argumentos,
  p.prosrc as codigo_fonte
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' AND p.proname = 'can_access_jovem';

-- ============================================
-- 4. ANÁLISE DAS ROLES DO SISTEMA
-- ============================================

-- Verificar todas as roles disponíveis
SELECT 
  r.id,
  r.slug,
  r.nome,
  r.descricao,
  r.nivel_hierarquico,
  COUNT(ur.id) as usuarios_com_esta_role
FROM public.roles r
LEFT JOIN public.user_roles ur ON ur.role_id = r.id AND ur.ativo = true
GROUP BY r.id, r.slug, r.nome, r.descricao, r.nivel_hierarquico
ORDER BY r.nivel_hierarquico DESC;

-- ============================================
-- 5. ANÁLISE DO USUÁRIO ATUAL
-- ============================================

-- Verificar usuário atual
SELECT 
  u.id as usuario_id,
  u.nome,
  u.email,
  u.ativo as usuario_ativo,
  auth.uid() as auth_uid,
  CASE 
    WHEN u.id_auth = auth.uid() THEN 'Usuário autenticado corretamente'
    ELSE 'PROBLEMA: IDs não coincidem'
  END as status_autenticacao
FROM public.usuarios u
WHERE u.id_auth = auth.uid();

-- Verificar roles do usuário atual
SELECT 
  ur.id as user_role_id,
  r.slug as role_slug,
  r.nome as role_nome,
  r.nivel_hierarquico,
  ur.ativo as role_ativa,
  ur.estado_id,
  ur.bloco_id,
  ur.regiao_id,
  ur.igreja_id,
  CASE 
    WHEN ur.ativo = true THEN 'Role ativa'
    ELSE 'Role inativa'
  END as status_role
FROM public.user_roles ur
JOIN public.roles r ON r.id = ur.role_id
WHERE ur.user_id = (SELECT id FROM public.usuarios WHERE id_auth = auth.uid())
ORDER BY r.nivel_hierarquico DESC;

-- ============================================
-- 6. ANÁLISE DE DADOS DE TESTE
-- ============================================

-- Verificar valores válidos do enum aprovado
SELECT 
  t.typname as nome_enum,
  e.enumlabel as valor_enum
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid  
WHERE t.typname LIKE '%aprovado%'
ORDER BY e.enumsortorder;

-- Contar jovens por status de aprovação
SELECT 
  COALESCE(aprovado::text, 'NULL') as status_aprovacao,
  COUNT(*) as total_jovens
FROM public.jovens
GROUP BY aprovado
ORDER BY 
  CASE 
    WHEN aprovado IS NULL THEN 1
    WHEN aprovado::text = 'pre_aprovado' THEN 2
    WHEN aprovado::text = 'aprovado' THEN 3
    ELSE 4
  END;

-- Verificar jovens com usuario_id preenchido
SELECT 
  'Jovens com usuario_id:' as status,
  COUNT(*) as total
FROM public.jovens
WHERE usuario_id IS NOT NULL;

-- Verificar jovens sem usuario_id
SELECT 
  'Jovens sem usuario_id:' as status,
  COUNT(*) as total
FROM public.jovens
WHERE usuario_id IS NULL;

-- ============================================
-- 7. ANÁLISE DE OUTRAS TABELAS RELACIONADAS
-- ============================================

-- Verificar se outras tabelas usam RLS
SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_habilitado,
  CASE 
    WHEN rowsecurity = true THEN 'RLS ativo'
    ELSE 'RLS inativo'
  END as status_rls
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('usuarios', 'user_roles', 'roles', 'estados', 'blocos', 'regioes', 'igrejas', 'edicoes', 'avaliacoes')
ORDER BY tablename;

-- ============================================
-- 8. RESUMO EXECUTIVO
-- ============================================

-- Resumo das políticas da tabela jovens
SELECT 
  'RESUMO: Políticas da tabela jovens' as categoria,
  COUNT(*) as total_politicas,
  COUNT(DISTINCT cmd) as tipos_comando_diferentes,
  STRING_AGG(DISTINCT cmd, ', ') as comandos_disponiveis
FROM pg_policies 
WHERE tablename = 'jovens';

-- Verificar se há políticas duplicadas
SELECT 
  cmd as comando,
  COUNT(*) as total_politicas,
  CASE 
    WHEN COUNT(*) > 1 THEN 'ATENÇÃO: Múltiplas políticas para o mesmo comando'
    ELSE 'OK: Uma política por comando'
  END as status
FROM pg_policies 
WHERE tablename = 'jovens'
GROUP BY cmd
ORDER BY total_politicas DESC;
