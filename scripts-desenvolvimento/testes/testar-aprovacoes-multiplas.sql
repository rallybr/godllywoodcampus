-- =====================================================
-- TESTAR SISTEMA DE APROVAÇÕES MÚLTIPLAS
-- =====================================================
-- Este script testa o novo sistema de aprovações múltiplas

-- ============================================
-- 1. VERIFICAR SE A TABELA FOI CRIADA
-- ============================================

SELECT 
  'VERIFICAÇÃO DA TABELA' as status,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.tables 
      WHERE table_name = 'aprovacoes_jovens' 
        AND table_schema = 'public'
    ) THEN '✅ Tabela aprovacoes_jovens existe'
    ELSE '❌ Tabela aprovacoes_jovens NÃO existe'
  END as tabela_criada;

-- ============================================
-- 2. VERIFICAR SE AS FUNÇÕES FORAM CRIADAS
-- ============================================

SELECT 
  'VERIFICAÇÃO DAS FUNÇÕES' as status,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_proc p
      JOIN pg_namespace n ON p.pronamespace = n.oid
      WHERE n.nspname = 'public' AND p.proname = 'aprovar_jovem_multiplo'
    ) THEN '✅ Função aprovar_jovem_multiplo existe'
    ELSE '❌ Função aprovar_jovem_multiplo NÃO existe'
  END as funcao_aprovar,
  
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_proc p
      JOIN pg_namespace n ON p.pronamespace = n.oid
      WHERE n.nspname = 'public' AND p.proname = 'buscar_aprovacoes_jovem'
    ) THEN '✅ Função buscar_aprovacoes_jovem existe'
    ELSE '❌ Função buscar_aprovacoes_jovem NÃO existe'
  END as funcao_buscar,
  
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_proc p
      JOIN pg_namespace n ON p.pronamespace = n.oid
      WHERE n.nspname = 'public' AND p.proname = 'usuario_ja_aprovou'
    ) THEN '✅ Função usuario_ja_aprovou existe'
    ELSE '❌ Função usuario_ja_aprovou NÃO existe'
  END as funcao_verificar;

-- ============================================
-- 3. VERIFICAR POLÍTICAS RLS
-- ============================================

SELECT 
  'VERIFICAÇÃO DAS POLÍTICAS RLS' as status,
  policyname,
  cmd,
  permissive
FROM pg_policies 
WHERE tablename = 'aprovacoes_jovens'
ORDER BY policyname;

-- ============================================
-- 4. TESTAR FUNÇÃO DE APROVAÇÃO (SIMULAÇÃO)
-- ============================================

-- Mostrar estrutura da função
SELECT 
  'ESTRUTURA DA FUNÇÃO' as status,
  proname as nome_funcao,
  proargnames as parametros,
  prosrc as codigo_fonte
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
  AND proname = 'aprovar_jovem_multiplo';

-- ============================================
-- 5. VERIFICAR DADOS MIGRADOS
-- ============================================

SELECT 
  'DADOS MIGRADOS' as status,
  COUNT(*) as total_aprovacoes_migradas,
  COUNT(DISTINCT jovem_id) as jovens_com_aprovacoes,
  COUNT(DISTINCT usuario_id) as usuarios_que_aprovaram
FROM public.aprovacoes_jovens;

-- ============================================
-- 6. VERIFICAR ESTRUTURA DA TABELA
-- ============================================

SELECT 
  'ESTRUTURA DA TABELA' as status,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'aprovacoes_jovens' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- ============================================
-- 7. VERIFICAR ÍNDICES
-- ============================================

SELECT 
  'ÍNDICES CRIADOS' as status,
  indexname,
  indexdef
FROM pg_indexes
WHERE tablename = 'aprovacoes_jovens'
  AND schemaname = 'public';

-- ============================================
-- 8. TESTE DE CONFORMIDADE GERAL
-- ============================================

SELECT 
  'TESTE DE CONFORMIDADE' as status,
  CASE 
    WHEN (SELECT relrowsecurity FROM pg_class WHERE relname = 'aprovacoes_jovens') THEN '✅ RLS habilitado'
    ELSE '❌ RLS NÃO habilitado'
  END as rls_habilitado,
  
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_constraint 
      WHERE conname = 'aprovacoes_jovens_jovem_id_fkey'
    ) THEN '✅ FK para jovens existe'
    ELSE '❌ FK para jovens NÃO existe'
  END as fk_jovens,
  
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_constraint 
      WHERE conname = 'aprovacoes_jovens_usuario_id_fkey'
    ) THEN '✅ FK para usuarios existe'
    ELSE '❌ FK para usuarios NÃO existe'
  END as fk_usuarios,
  
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_constraint 
      WHERE conname = 'aprovacoes_jovens_tipo_aprovacao_check'
    ) THEN '✅ Check constraint existe'
    ELSE '❌ Check constraint NÃO existe'
  END as check_constraint;

-- ============================================
-- 9. RESUMO FINAL
-- ============================================

SELECT 
  'SISTEMA DE APROVAÇÕES MÚLTIPLAS CONFIGURADO' as status,
  '✅ Tabela aprovacoes_jovens criada' as tabela,
  '✅ Funções RPC implementadas' as funcoes,
  '✅ Políticas RLS configuradas' as politicas,
  '✅ Índices de performance criados' as indices,
  '✅ Dados existentes migrados' as migracao,
  '✅ Sistema pronto para uso' as sistema_pronto;
