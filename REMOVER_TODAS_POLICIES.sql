-- REMOVER TODAS AS POLICIES PROBLEMÁTICAS
-- Deixa o sistema limpo para você recriar as policies corretas

-- ============================================
-- 1. REMOVER TODAS AS POLICIES DAS 3 TABELAS
-- ============================================

-- Remover TODAS as policies da tabela usuarios
DROP POLICY IF EXISTS "usuarios_select_by_hierarchy" ON public.usuarios;
DROP POLICY IF EXISTS "usuarios_update_by_hierarchy" ON public.usuarios;
DROP POLICY IF EXISTS "usuarios_insert_by_hierarchy" ON public.usuarios;
DROP POLICY IF EXISTS "usuarios_delete_by_hierarchy" ON public.usuarios;

-- Remover TODAS as policies da tabela jovens
DROP POLICY IF EXISTS "jovens_select_by_hierarchy" ON public.jovens;
DROP POLICY IF EXISTS "jovens_insert_by_hierarchy" ON public.jovens;
DROP POLICY IF EXISTS "jovens_update_by_hierarchy" ON public.jovens;
DROP POLICY IF EXISTS "jovens_delete_by_hierarchy" ON public.jovens;
DROP POLICY IF EXISTS "jovens_delete_admin_only" ON public.jovens;

-- Remover TODAS as policies da tabela dados_viagem
DROP POLICY IF EXISTS "dados_viagem_select_by_hierarchy" ON public.dados_viagem;
DROP POLICY IF EXISTS "dados_viagem_insert_by_hierarchy" ON public.dados_viagem;
DROP POLICY IF EXISTS "dados_viagem_update_by_hierarchy" ON public.dados_viagem;
DROP POLICY IF EXISTS "dados_viagem_delete_by_hierarchy" ON public.dados_viagem;

-- ============================================
-- 2. REMOVER QUALQUER POLICY RESTANTE
-- ============================================

-- Remover TODAS as policies restantes (método mais seguro)
DO $$
DECLARE
    policy_record RECORD;
BEGIN
    -- Remover policies da tabela usuarios
    FOR policy_record IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'usuarios'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.usuarios', policy_record.policyname);
    END LOOP;
    
    -- Remover policies da tabela jovens
    FOR policy_record IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'jovens'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.jovens', policy_record.policyname);
    END LOOP;
    
    -- Remover policies da tabela dados_viagem
    FOR policy_record IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'dados_viagem'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.dados_viagem', policy_record.policyname);
    END LOOP;
END $$;

-- ============================================
-- 3. VERIFICAÇÃO
-- ============================================

-- Verificar se todas as policies foram removidas
SELECT 
  'Políticas removidas com sucesso!' as status,
  COUNT(*) as total_policies_restantes
FROM pg_policies 
WHERE tablename IN ('usuarios', 'jovens', 'dados_viagem');

-- Mostrar policies restantes (se houver)
SELECT 
  'Políticas restantes:' as status,
  tablename,
  policyname
FROM pg_policies 
WHERE tablename IN ('usuarios', 'jovens', 'dados_viagem')
ORDER BY tablename, policyname;
