-- RESTAURAR SISTEMA ORIGINAL
-- Baseado na estrutura de functions e policies fornecida

-- ============================================
-- 1. REMOVER TODAS AS POLICIES ATUAIS
-- ============================================

-- Remover TODAS as policies existentes
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
    
    -- Remover policies da tabela avaliacoes
    FOR policy_record IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'avaliacoes'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.avaliacoes', policy_record.policyname);
    END LOOP;
    
    -- Remover policies da tabela logs_auditoria
    FOR policy_record IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'logs_auditoria'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.logs_auditoria', policy_record.policyname);
    END LOOP;
    
    -- Remover policies da tabela notificacoes
    FOR policy_record IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'notificacoes'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.notificacoes', policy_record.policyname);
    END LOOP;
    
    -- Remover policies da tabela roles
    FOR policy_record IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'roles'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.roles', policy_record.policyname);
    END LOOP;
    
    -- Remover policies da tabela user_roles
    FOR policy_record IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'user_roles'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.user_roles', policy_record.policyname);
    END LOOP;
END $$;

-- ============================================
-- 2. CRIAR POLICIES ORIGINAIS
-- ============================================

-- USUARIOS - Políticas originais
CREATE POLICY "Allow all for admin" ON public.usuarios
USING (has_role('administrador'));

CREATE POLICY "Allow read for authenticated users" ON public.usuarios
FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Allow update for own profile" ON public.usuarios
FOR UPDATE USING (id = (SELECT usuarios_1.id FROM usuarios usuarios_1 WHERE usuarios_1.id_auth = auth.uid()));

-- JOVENS - Políticas originais
CREATE POLICY "Allow all for admin" ON public.jovens
USING (has_role('administrador'));

CREATE POLICY "Allow insert for authenticated users" ON public.jovens
FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Allow read for authenticated users" ON public.jovens
FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Allow update for authenticated users" ON public.jovens
FOR UPDATE USING (auth.role() = 'authenticated');

-- DADOS_VIAGEM - Políticas originais
CREATE POLICY "Allow all for admin" ON public.dados_viagem
USING (has_role('administrador'));

CREATE POLICY "Allow insert for authenticated users" ON public.dados_viagem
FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Allow read for authenticated users" ON public.dados_viagem
FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Allow update for authenticated users" ON public.dados_viagem
FOR UPDATE USING (auth.role() = 'authenticated');

-- AVALIACOES - Políticas originais
CREATE POLICY "Allow all for admin" ON public.avaliacoes
USING (has_role('administrador'));

CREATE POLICY "Allow insert for authenticated users" ON public.avaliacoes
FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Allow read for authenticated users" ON public.avaliacoes
FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Allow update for authenticated users" ON public.avaliacoes
FOR UPDATE USING (auth.role() = 'authenticated');

-- LOGS_AUDITORIA - Políticas originais
CREATE POLICY "Allow all for admin" ON public.logs_auditoria
USING (has_role('administrador'));

CREATE POLICY "Allow read for authenticated users" ON public.logs_auditoria
FOR SELECT USING (auth.role() = 'authenticated');

-- NOTIFICACOES - Políticas originais
CREATE POLICY "Allow all for admin" ON public.notificacoes
USING (has_role('administrador'));

CREATE POLICY "Allow insert for authenticated users" ON public.notificacoes
FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Allow read for authenticated users" ON public.notificacoes
FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Allow update for authenticated users" ON public.notificacoes
FOR UPDATE USING (auth.role() = 'authenticated');

-- ROLES - Políticas originais
CREATE POLICY "Allow all for admin" ON public.roles
USING (has_role('administrador'));

CREATE POLICY "Allow read for authenticated users" ON public.roles
FOR SELECT USING (auth.role() = 'authenticated');

-- USER_ROLES - Políticas originais
CREATE POLICY "Allow all for admin" ON public.user_roles
USING (has_role('administrador'));

CREATE POLICY "Allow delete for admin" ON public.user_roles
FOR DELETE USING (has_role('administrador'));

CREATE POLICY "Allow insert for admin" ON public.user_roles
FOR INSERT WITH CHECK (has_role('administrador'));

CREATE POLICY "Allow read for authenticated users" ON public.user_roles
FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Allow update for admin" ON public.user_roles
FOR UPDATE USING (has_role('administrador'));

-- ============================================
-- 3. VERIFICAÇÃO
-- ============================================

SELECT 'Sistema original restaurado com sucesso!' as status;
