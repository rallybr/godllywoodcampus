-- Script para reabilitar RLS e recriar as policies necessárias

-- 1. Reabilitar RLS em todas as tabelas principais
ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jovens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.avaliacoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.estados ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blocos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.regioes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.igrejas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.edicoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dados_viagem ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notificacoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.logs_auditoria ENABLE ROW LEVEL SECURITY;

-- 2. Recriar policies básicas para usuarios
CREATE POLICY "Allow all for admin" ON public.usuarios FOR ALL USING (has_role('administrador'));
CREATE POLICY "Allow read for authenticated users" ON public.usuarios FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Allow update for own profile" ON public.usuarios FOR UPDATE USING (id = (SELECT id FROM public.usuarios WHERE id_auth = auth.uid()));

-- 3. Recriar policies básicas para jovens
CREATE POLICY "Allow all for admin" ON public.jovens FOR ALL USING (has_role('administrador'));
CREATE POLICY "Allow read for authenticated users" ON public.jovens FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Allow insert for authenticated users" ON public.jovens FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Allow update for authenticated users" ON public.jovens FOR UPDATE USING (auth.role() = 'authenticated');

-- 4. Recriar policies básicas para avaliacoes
CREATE POLICY "Allow all for admin" ON public.avaliacoes FOR ALL USING (has_role('administrador'));
CREATE POLICY "Allow read for authenticated users" ON public.avaliacoes FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Allow insert for authenticated users" ON public.avaliacoes FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Allow update for authenticated users" ON public.avaliacoes FOR UPDATE USING (auth.role() = 'authenticated');

-- 5. Recriar policies básicas para user_roles
CREATE POLICY "Allow all for admin" ON public.user_roles FOR ALL USING (has_role('administrador'));
CREATE POLICY "Allow read for authenticated users" ON public.user_roles FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Allow insert for admin" ON public.user_roles FOR INSERT WITH CHECK (has_role('administrador'));
CREATE POLICY "Allow update for admin" ON public.user_roles FOR UPDATE USING (has_role('administrador'));
CREATE POLICY "Allow delete for admin" ON public.user_roles FOR DELETE USING (has_role('administrador'));

-- 6. Recriar policies básicas para roles
CREATE POLICY "Allow all for admin" ON public.roles FOR ALL USING (has_role('administrador'));
CREATE POLICY "Allow read for authenticated users" ON public.roles FOR SELECT USING (auth.role() = 'authenticated');

-- 7. Recriar policies básicas para dados_viagem
CREATE POLICY "Allow all for admin" ON public.dados_viagem FOR ALL USING (has_role('administrador'));
CREATE POLICY "Allow read for authenticated users" ON public.dados_viagem FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Allow insert for authenticated users" ON public.dados_viagem FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Allow update for authenticated users" ON public.dados_viagem FOR UPDATE USING (auth.role() = 'authenticated');

-- 8. Recriar policies básicas para notificacoes
CREATE POLICY "Allow all for admin" ON public.notificacoes FOR ALL USING (has_role('administrador'));
CREATE POLICY "Allow read for authenticated users" ON public.notificacoes FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Allow insert for authenticated users" ON public.notificacoes FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Allow update for authenticated users" ON public.notificacoes FOR UPDATE USING (auth.role() = 'authenticated');

-- 9. Recriar policies básicas para logs_auditoria
CREATE POLICY "Allow all for admin" ON public.logs_auditoria FOR ALL USING (has_role('administrador'));
CREATE POLICY "Allow read for authenticated users" ON public.logs_auditoria FOR SELECT USING (auth.role() = 'authenticated');

-- 10. Verificar se RLS está habilitado
SELECT 
    schemaname, 
    tablename, 
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('usuarios', 'jovens', 'avaliacoes', 'user_roles', 'roles', 'dados_viagem', 'notificacoes', 'logs_auditoria')
ORDER BY tablename;

-- 11. Verificar policies criadas
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
