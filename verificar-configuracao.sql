-- Script de verificação pós-correção
-- Execute este script para verificar se tudo foi configurado corretamente

-- ============================================
-- 1. VERIFICAR ESTRUTURA DA TABELA
-- ============================================

SELECT 'Estrutura da tabela dados_viagem:' as verificacao;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'dados_viagem' 
ORDER BY ordinal_position;

-- ============================================
-- 2. VERIFICAR RLS
-- ============================================

SELECT 'RLS habilitado:' as verificacao, rowsecurity 
FROM pg_tables 
WHERE tablename = 'dados_viagem';

-- ============================================
-- 3. VERIFICAR POLÍTICAS
-- ============================================

SELECT 'Políticas RLS criadas:' as verificacao;
SELECT policyname, cmd, permissive, roles
FROM pg_policies 
WHERE tablename = 'dados_viagem'
ORDER BY policyname;

-- ============================================
-- 4. VERIFICAR FUNÇÃO can_access_jovem
-- ============================================

SELECT 'Função can_access_jovem existe:' as verificacao,
       EXISTS (
         SELECT 1 FROM pg_proc p
         JOIN pg_namespace n ON p.pronamespace = n.oid
         WHERE n.nspname = 'public' AND p.proname = 'can_access_jovem'
       ) as existe;

-- ============================================
-- 5. VERIFICAR TRIGGER
-- ============================================

SELECT 'Trigger criado:' as verificacao,
       EXISTS (
         SELECT 1 FROM pg_trigger t
         JOIN pg_class c ON t.tgrelid = c.oid
         WHERE c.relname = 'dados_viagem' 
         AND t.tgname = 'trigger_set_usuario_id_dados_viagem'
       ) as existe;

-- ============================================
-- 6. VERIFICAR ÍNDICES
-- ============================================

SELECT 'Índices da tabela:' as verificacao;
SELECT indexname, indexdef
FROM pg_indexes 
WHERE tablename = 'dados_viagem';

-- ============================================
-- 7. VERIFICAR DADOS EXISTENTES
-- ============================================

SELECT 'Total de registros na tabela:' as verificacao, COUNT(*) as total
FROM public.dados_viagem;

-- ============================================
-- 8. TESTE DE PERMISSÕES (OPCIONAL)
-- ============================================

-- Este teste verifica se o usuário atual pode acessar a tabela
SELECT 'Usuário atual pode acessar dados_viagem:' as verificacao,
       has_table_privilege('public.dados_viagem', 'SELECT') as pode_select,
       has_table_privilege('public.dados_viagem', 'INSERT') as pode_insert,
       has_table_privilege('public.dados_viagem', 'UPDATE') as pode_update,
       has_table_privilege('public.dados_viagem', 'DELETE') as pode_delete;

SELECT 'Verificação concluída!' as status;
