-- =====================================================
-- SCRIPT PARA LIMPAR POLICIES DUPLICADAS DE dados_viagem
-- =====================================================
-- Este script remove policies redundantes mantendo apenas as essenciais
-- Execute com cuidado e teste em ambiente de desenvolvimento primeiro

-- 1. BACKUP DAS POLICIES ATUAIS (para rollback se necessário)
-- Execute este comando para ver as policies atuais:
-- SELECT policyname, cmd, qual, with_check FROM pg_policies WHERE tablename = 'dados_viagem';

-- 2. REMOVER POLICIES DUPLICADAS/REDUNDANTES
-- Manteremos apenas as policies essenciais:
-- - dados_viagem_select_by_level
-- - dados_viagem_update_by_level  
-- - dados_viagem_insert_by_level
-- - dados_viagem_delete_admin

-- Remover policies duplicadas de SELECT
DROP POLICY IF EXISTS "dados_viagem_select_scoped" ON dados_viagem;
DROP POLICY IF EXISTS "jovem pode ver seus dados de viagem" ON dados_viagem;
DROP POLICY IF EXISTS "lideres podem ver dados de viagem" ON dados_viagem;

-- Remover policies duplicadas de UPDATE
DROP POLICY IF EXISTS "dados_viagem_update_scoped" ON dados_viagem;
DROP POLICY IF EXISTS "jovem pode atualizar seus dados de viagem" ON dados_viagem;
DROP POLICY IF EXISTS "lideres podem atualizar dados de viagem" ON dados_viagem;

-- Remover policies duplicadas de INSERT
DROP POLICY IF EXISTS "dados_viagem_insert_scoped" ON dados_viagem;

-- 3. VERIFICAR POLICIES RESTANTES
-- Execute este comando para verificar as policies que restaram:
-- SELECT policyname, cmd, qual, with_check FROM pg_policies WHERE tablename = 'dados_viagem' ORDER BY policyname;

-- 4. TESTAR FUNCIONALIDADES
-- Após executar este script, teste:
-- - SELECT de dados_viagem (deve funcionar)
-- - INSERT de dados_viagem (deve funcionar)  
-- - UPDATE de dados_viagem (deve funcionar)
-- - DELETE de dados_viagem (deve funcionar apenas para admins)

-- 5. ROLLBACK (se necessário)
-- Se algo der errado, você pode recriar as policies removidas:
-- (Execute apenas se necessário)

-- Recriar policy de SELECT para jovens
-- CREATE POLICY "jovem pode ver seus dados de viagem" ON dados_viagem
-- FOR SELECT USING (
--   jovem_id IN (
--     SELECT j.id FROM jovens j
--     JOIN usuarios u ON u.id = j.usuario_id
--     WHERE u.id_auth = auth.uid()
--   )
-- );

-- Recriar policy de UPDATE para jovens  
-- CREATE POLICY "jovem pode atualizar seus dados de viagem" ON dados_viagem
-- FOR UPDATE USING (
--   jovem_id IN (
--     SELECT j.id FROM jovens j
--     JOIN usuarios u ON u.id = j.usuario_id
--     WHERE u.id_auth = auth.uid()
--   )
-- ) WITH CHECK (
--   jovem_id IN (
--     SELECT j.id FROM jovens j
--     JOIN usuarios u ON u.id = j.usuario_id
--     WHERE u.id_auth = auth.uid()
--   )
-- );

-- Recriar policy de SELECT para líderes
-- CREATE POLICY "lideres podem ver dados de viagem" ON dados_viagem
-- FOR SELECT USING (
--   EXISTS (
--     SELECT 1 FROM jovens j
--     WHERE j.id = dados_viagem.jovem_id 
--     AND can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id)
--   )
-- );

-- Recriar policy de UPDATE para líderes
-- CREATE POLICY "lideres podem atualizar dados de viagem" ON dados_viagem
-- FOR UPDATE USING (
--   EXISTS (
--     SELECT 1 FROM jovens j
--     WHERE j.id = dados_viagem.jovem_id 
--     AND can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id)
--   )
-- ) WITH CHECK (
--   EXISTS (
--     SELECT 1 FROM jovens j
--     WHERE j.id = dados_viagem.jovem_id 
--     AND can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id)
--   )
-- );

-- Recriar policy de INSERT scoped
-- CREATE POLICY "dados_viagem_insert_scoped" ON dados_viagem
-- FOR INSERT WITH CHECK (
--   EXISTS (
--     SELECT 1 FROM jovens j
--     WHERE j.id = dados_viagem.jovem_id 
--     AND (can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id) 
--          OR j.usuario_id = (SELECT usuarios.id FROM usuarios WHERE usuarios.id_auth = auth.uid()))
--   )
-- );

-- Recriar policy de SELECT scoped
-- CREATE POLICY "dados_viagem_select_scoped" ON dados_viagem
-- FOR SELECT USING (
--   EXISTS (
--     SELECT 1 FROM jovens j
--     WHERE j.id = dados_viagem.jovem_id 
--     AND (can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id) 
--          OR j.usuario_id = (SELECT usuarios.id FROM usuarios WHERE usuarios.id_auth = auth.uid()))
--   )
-- );

-- Recriar policy de UPDATE scoped
-- CREATE POLICY "dados_viagem_update_scoped" ON dados_viagem
-- FOR UPDATE USING (
--   EXISTS (
--     SELECT 1 FROM jovens j
--     WHERE j.id = dados_viagem.jovem_id 
--     AND (can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id) 
--          OR j.usuario_id = (SELECT usuarios.id FROM usuarios WHERE usuarios.id_auth = auth.uid()))
--   )
-- ) WITH CHECK (
--   EXISTS (
--     SELECT 1 FROM jovens j
--     WHERE j.id = dados_viagem.jovem_id 
--     AND (can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id) 
--          OR j.usuario_id = (SELECT usuarios.id FROM usuarios WHERE usuarios.id_auth = auth.uid()))
--   )
-- );

-- =====================================================
-- FIM DO SCRIPT
-- =====================================================
