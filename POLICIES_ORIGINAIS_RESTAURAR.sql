-- =====================================================
-- SCRIPT PARA RESTAURAR POLICIES ORIGINAIS FUNCIONAIS
-- =====================================================

-- Limpeza das policies existentes
DROP POLICY IF EXISTS allow_read_aprovacoes_jovens ON aprovacoes_jovens;
DROP POLICY IF EXISTS "Allow all for admin" ON avaliacoes;
DROP POLICY IF EXISTS "Allow insert for authenticated users" ON avaliacoes;
DROP POLICY IF EXISTS "Allow read for authenticated users" ON avaliacoes;
DROP POLICY IF EXISTS "Allow update for authenticated users" ON avaliacoes;
DROP POLICY IF EXISTS avaliacoes_insert_by_level ON avaliacoes;
DROP POLICY IF EXISTS avaliacoes_select_by_level ON avaliacoes;
DROP POLICY IF EXISTS avaliacoes_update_by_level ON avaliacoes;
DROP POLICY IF EXISTS blocos_delete_admin ON blocos;
DROP POLICY IF EXISTS blocos_insert_admin ON blocos;
DROP POLICY IF EXISTS blocos_select_all ON blocos;
DROP POLICY IF EXISTS blocos_update_admin ON blocos;
DROP POLICY IF EXISTS allow_read_configuracoes_sistema ON configuracoes_sistema;
DROP POLICY IF EXISTS "Acesso Geral" ON dados_viagem;
DROP POLICY IF EXISTS "Allow all for admin" ON dados_viagem;
DROP POLICY IF EXISTS "Allow insert for authenticated users" ON dados_viagem;
DROP POLICY IF EXISTS "Allow update for authenticated users" ON dados_viagem;
DROP POLICY IF EXISTS "Edições são visíveis para todos" ON edicoes;
DROP POLICY IF EXISTS allow_read_all_edicoes ON edicoes;
DROP POLICY IF EXISTS "Estados são visíveis para todos" ON estados;
DROP POLICY IF EXISTS allow_read_all_estados ON estados;
DROP POLICY IF EXISTS igrejas_delete_admin ON igrejas;
DROP POLICY IF EXISTS igrejas_insert_admin ON igrejas;
DROP POLICY IF EXISTS igrejas_select_all ON igrejas;
DROP POLICY IF EXISTS igrejas_update_admin ON igrejas;
DROP POLICY IF EXISTS "Allow all for admin" ON jovens;
DROP POLICY IF EXISTS "Allow insert for authenticated users" ON jovens;
DROP POLICY IF EXISTS "Allow update for authenticated users" ON jovens;
DROP POLICY IF EXISTS jovens_read_authenticated_scoped ON jovens;
DROP POLICY IF EXISTS "Allow all for admin" ON logs_auditoria;
DROP POLICY IF EXISTS "Allow read for authenticated users" ON logs_auditoria;
DROP POLICY IF EXISTS "Allow all for admin" ON notificacoes;
DROP POLICY IF EXISTS "Allow insert for authenticated users" ON notificacoes;
DROP POLICY IF EXISTS "Allow read for authenticated users" ON notificacoes;
DROP POLICY IF EXISTS "Allow update for authenticated users" ON notificacoes;
DROP POLICY IF EXISTS regioes_delete_admin ON regioes;
DROP POLICY IF EXISTS regioes_insert_admin ON regioes;
DROP POLICY IF EXISTS regioes_select_all ON regioes;
DROP POLICY IF EXISTS regioes_update_admin ON regioes;
DROP POLICY IF EXISTS "Allow all for admin" ON roles;
DROP POLICY IF EXISTS "Allow read for authenticated users" ON roles;
DROP POLICY IF EXISTS allow_read_sessoes_usuario ON sessoes_usuario;
DROP POLICY IF EXISTS "Allow all for admin" ON user_roles;
DROP POLICY IF EXISTS "Allow delete for admin" ON user_roles;
DROP POLICY IF EXISTS "Allow insert for admin" ON user_roles;
DROP POLICY IF EXISTS "Allow read for authenticated users" ON user_roles;
DROP POLICY IF EXISTS "Allow update for admin" ON user_roles;
DROP POLICY IF EXISTS "Allow admin all access" ON usuarios;
DROP POLICY IF EXISTS "Allow insert for signup" ON usuarios;
DROP POLICY IF EXISTS "Allow select own profile" ON usuarios;
DROP POLICY IF EXISTS "Allow update own profile" ON usuarios;

-- =====================================================
-- CRIAR POLICIES ORIGINAIS
-- =====================================================

-- APROVACOES_JOVENS
CREATE POLICY allow_read_aprovacoes_jovens ON aprovacoes_jovens FOR SELECT USING (true);

-- AVALIACOES
CREATE POLICY "Allow all for admin" ON avaliacoes USING (has_role('administrador'::text));
CREATE POLICY "Allow insert for authenticated users" ON avaliacoes FOR INSERT WITH CHECK ((auth.role() = 'authenticated'::text));
CREATE POLICY "Allow read for authenticated users" ON avaliacoes FOR SELECT USING ((auth.role() = 'authenticated'::text));
CREATE POLICY "Allow update for authenticated users" ON avaliacoes FOR UPDATE USING ((auth.role() = 'authenticated'::text));

-- AVALIACOES - POLICIES COMPLEXAS
CREATE POLICY avaliacoes_insert_by_level ON avaliacoes FOR INSERT TO authenticated WITH CHECK ((EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND ((u.nivel = 'administrador'::text) OR (u.nivel = ANY (ARRAY['lider_nacional_iurd'::text, 'lider_nacional_fju'::text])) OR ((u.nivel = ANY (ARRAY['lider_estadual_iurd'::text, 'lider_estadual_fju'::text])) AND (u.estado_id = ( SELECT j.estado_id
           FROM jovens j
          WHERE (j.id = avaliacoes.jovem_id)))) OR ((u.nivel = ANY (ARRAY['lider_bloco_iurd'::text, 'lider_bloco_fju'::text])) AND (u.bloco_id = ( SELECT j.bloco_id
           FROM jovens j
          WHERE (j.id = avaliacoes.jovem_id)))) OR ((u.nivel = 'lider_regional_iurd'::text) AND (u.regiao_id = ( SELECT j.regiao_id
           FROM jovens j
          WHERE (j.id = avaliacoes.jovem_id)))) OR ((u.nivel = 'lider_igreja_iurd'::text) AND (u.igreja_id = ( SELECT j.igreja_id
           FROM jovens j
          WHERE (j.id = avaliacoes.jovem_id)))) OR (u.nivel = 'colaborador'::text) OR ((u.nivel = 'jovem'::text) AND (u.id = avaliacoes.user_id)))))));

CREATE POLICY avaliacoes_select_by_level ON avaliacoes FOR SELECT TO authenticated USING (((EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = 'administrador'::text)))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_nacional_iurd'::text, 'lider_nacional_fju'::text]))))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_estadual_iurd'::text, 'lider_estadual_fju'::text])) AND (u.estado_id = ( SELECT j.estado_id
           FROM jovens j
          WHERE (j.id = avaliacoes.jovem_id)))))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_bloco_iurd'::text, 'lider_bloco_fju'::text])) AND (u.bloco_id = ( SELECT j.bloco_id
           FROM jovens j
          WHERE (j.id = avaliacoes.jovem_id)))))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = 'lider_regional_iurd'::text) AND (u.regiao_id = ( SELECT j.regiao_id
           FROM jovens j
          WHERE (j.id = avaliacoes.jovem_id)))))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = 'lider_igreja_iurd'::text) AND (u.igreja_id = ( SELECT j.igreja_id
           FROM jovens j
          WHERE (j.id = avaliacoes.jovem_id)))))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = 'colaborador'::text) AND (u.id = avaliacoes.user_id)))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = 'jovem'::text) AND (u.id = avaliacoes.user_id))))));

CREATE POLICY avaliacoes_update_by_level ON avaliacoes FOR UPDATE TO authenticated USING ((EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND ((u.nivel = 'administrador'::text) OR (u.nivel = ANY (ARRAY['lider_nacional_iurd'::text, 'lider_nacional_fju'::text])) OR ((u.nivel = ANY (ARRAY['lider_estadual_iurd'::text, 'lider_estadual_fju'::text])) AND (u.estado_id = ( SELECT j.estado_id
           FROM jovens j
          WHERE (j.id = avaliacoes.jovem_id)))) OR ((u.nivel = ANY (ARRAY['lider_bloco_iurd'::text, 'lider_bloco_fju'::text])) AND (u.bloco_id = ( SELECT j.bloco_id
           FROM jovens j
          WHERE (j.id = avaliacoes.jovem_id)))) OR ((u.nivel = 'lider_regional_iurd'::text) AND (u.regiao_id = ( SELECT j.regiao_id
           FROM jovens j
          WHERE (j.id = avaliacoes.jovem_id)))) OR ((u.nivel = 'lider_igreja_iurd'::text) AND (u.igreja_id = ( SELECT j.igreja_id
           FROM jovens j
          WHERE (j.id = avaliacoes.jovem_id)))) OR ((u.nivel = 'colaborador'::text) AND (u.id = avaliacoes.user_id)) OR ((u.nivel = 'jovem'::text) AND (u.id = avaliacoes.user_id))))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND ((u.nivel = 'administrador'::text) OR (u.nivel = ANY (ARRAY['lider_nacional_iurd'::text, 'lider_nacional_fju'::text])) OR ((u.nivel = ANY (ARRAY['lider_estadual_iurd'::text, 'lider_estadual_fju'::text])) AND (u.estado_id = ( SELECT j.estado_id
           FROM jovens j
          WHERE (j.id = avaliacoes.jovem_id)))) OR ((u.nivel = ANY (ARRAY['lider_bloco_iurd'::text, 'lider_bloco_fju'::text])) AND (u.bloco_id = ( SELECT j.bloco_id
           FROM jovens j
          WHERE (j.id = avaliacoes.jovem_id)))) OR ((u.nivel = 'lider_regional_iurd'::text) AND (u.regiao_id = ( SELECT j.regiao_id
           FROM jovens j
          WHERE (j.id = avaliacoes.jovem_id)))) OR ((u.nivel = 'lider_igreja_iurd'::text) AND (u.igreja_id = ( SELECT j.igreja_id
           FROM jovens j
          WHERE (j.id = avaliacoes.jovem_id)))) OR ((u.nivel = 'colaborador'::text) AND (u.id = avaliacoes.user_id)) OR ((u.nivel = 'jovem'::text) AND (u.id = avaliacoes.user_id)))))));

-- BLOCOS
CREATE POLICY blocos_delete_admin ON blocos FOR DELETE USING ((EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = 'administrador'::text)))));

CREATE POLICY blocos_insert_admin ON blocos FOR INSERT WITH CHECK (((EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = 'administrador'::text)))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_nacional_iurd'::text, 'lider_nacional_fju'::text]))))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_estadual_iurd'::text, 'lider_estadual_fju'::text])) AND (u.estado_id = blocos.estado_id))))));

CREATE POLICY blocos_select_all ON blocos FOR SELECT USING (true);

CREATE POLICY blocos_update_admin ON blocos FOR UPDATE USING (((EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = 'administrador'::text)))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_nacional_iurd'::text, 'lider_nacional_fju'::text]))))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_estadual_iurd'::text, 'lider_estadual_fju'::text])) AND (u.estado_id = blocos.estado_id)))))) WITH CHECK (((EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = 'administrador'::text)))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_nacional_iurd'::text, 'lider_nacional_fju'::text]))))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_estadual_iurd'::text, 'lider_estadual_fju'::text])) AND (u.estado_id = blocos.estado_id))))));

-- CONFIGURACOES_SISTEMA
CREATE POLICY allow_read_configuracoes_sistema ON configuracoes_sistema FOR SELECT USING (true);

-- DADOS_VIAGEM
CREATE POLICY "Acesso Geral" ON dados_viagem USING (true) WITH CHECK (true);
CREATE POLICY "Allow all for admin" ON dados_viagem USING (has_role('administrador'::text));
CREATE POLICY "Allow insert for authenticated users" ON dados_viagem FOR INSERT WITH CHECK ((auth.role() = 'authenticated'::text));
CREATE POLICY "Allow update for authenticated users" ON dados_viagem FOR UPDATE USING ((auth.role() = 'authenticated'::text));

-- EDICOES
CREATE POLICY "Edições são visíveis para todos" ON edicoes FOR SELECT TO authenticated USING (true);
CREATE POLICY allow_read_all_edicoes ON edicoes FOR SELECT USING (true);

-- ESTADOS
CREATE POLICY "Estados são visíveis para todos" ON estados FOR SELECT TO authenticated USING (true);
CREATE POLICY allow_read_all_estados ON estados FOR SELECT USING (true);

-- IGREJAS
CREATE POLICY igrejas_delete_admin ON igrejas FOR DELETE USING ((EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = 'administrador'::text)))));

CREATE POLICY igrejas_insert_admin ON igrejas FOR INSERT WITH CHECK (((EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = 'administrador'::text)))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_nacional_iurd'::text, 'lider_nacional_fju'::text]))))) OR (EXISTS ( SELECT 1
   FROM (usuarios u
     JOIN blocos b ON ((b.id = ( SELECT r.bloco_id
           FROM regioes r
          WHERE (r.id = igrejas.regiao_id)))))
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_estadual_iurd'::text, 'lider_estadual_fju'::text])) AND (u.estado_id = b.estado_id)))) OR (EXISTS ( SELECT 1
   FROM (usuarios u
     JOIN regioes r ON ((r.id = igrejas.regiao_id)))
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_bloco_iurd'::text, 'lider_bloco_fju'::text])) AND (u.bloco_id = r.bloco_id)))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = 'lider_regional_iurd'::text) AND (u.regiao_id = igrejas.regiao_id))))));

CREATE POLICY igrejas_select_all ON igrejas FOR SELECT USING (true);

CREATE POLICY igrejas_update_admin ON igrejas FOR UPDATE USING (((EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = 'administrador'::text)))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_nacional_iurd'::text, 'lider_nacional_fju'::text]))))) OR (EXISTS ( SELECT 1
   FROM (usuarios u
     JOIN blocos b ON ((b.id = ( SELECT r.bloco_id
           FROM regioes r
          WHERE (r.id = igrejas.regiao_id)))))
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_estadual_iurd'::text, 'lider_estadual_fju'::text])) AND (u.estado_id = b.estado_id)))) OR (EXISTS ( SELECT 1
   FROM (usuarios u
     JOIN regioes r ON ((r.id = igrejas.regiao_id)))
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_bloco_iurd'::text, 'lider_bloco_fju'::text])) AND (u.bloco_id = r.bloco_id)))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = 'lider_regional_iurd'::text) AND (u.regiao_id = igrejas.regiao_id)))))) WITH CHECK (((EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = 'administrador'::text)))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_nacional_iurd'::text, 'lider_nacional_fju'::text]))))) OR (EXISTS ( SELECT 1
   FROM (usuarios u
     JOIN blocos b ON ((b.id = ( SELECT r.bloco_id
           FROM regioes r
          WHERE (r.id = igrejas.regiao_id)))))
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_estadual_iurd'::text, 'lider_estadual_fju'::text])) AND (u.estado_id = b.estado_id)))) OR (EXISTS ( SELECT 1
   FROM (usuarios u
     JOIN regioes r ON ((r.id = igrejas.regiao_id)))
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_bloco_iurd'::text, 'lider_bloco_fju'::text])) AND (u.bloco_id = r.bloco_id)))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = 'lider_regional_iurd'::text) AND (u.regiao_id = igrejas.regiao_id))))));

-- JOVENS
CREATE POLICY "Allow all for admin" ON jovens USING (has_role('administrador'::text));
CREATE POLICY "Allow insert for authenticated users" ON jovens FOR INSERT WITH CHECK ((auth.role() = 'authenticated'::text));
CREATE POLICY "Allow update for authenticated users" ON jovens FOR UPDATE USING ((auth.role() = 'authenticated'::text));
CREATE POLICY jovens_read_authenticated_scoped ON jovens FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND ((u.nivel <> 'jovem'::text) OR ((u.nivel = 'jovem'::text) AND ((u.id = jovens.usuario_id) OR (jovens.usuario_id IS NULL))))))));

-- LOGS_AUDITORIA
CREATE POLICY "Allow all for admin" ON logs_auditoria USING (has_role('administrador'::text));
CREATE POLICY "Allow read for authenticated users" ON logs_auditoria FOR SELECT USING ((auth.role() = 'authenticated'::text));

-- NOTIFICACOES
CREATE POLICY "Allow all for admin" ON notificacoes USING (has_role('administrador'::text));
CREATE POLICY "Allow insert for authenticated users" ON notificacoes FOR INSERT WITH CHECK ((auth.role() = 'authenticated'::text));
CREATE POLICY "Allow read for authenticated users" ON notificacoes FOR SELECT USING ((auth.role() = 'authenticated'::text));
CREATE POLICY "Allow update for authenticated users" ON notificacoes FOR UPDATE USING ((auth.role() = 'authenticated'::text));

-- REGIOES
CREATE POLICY regioes_delete_admin ON regioes FOR DELETE USING ((EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = 'administrador'::text)))));

CREATE POLICY regioes_insert_admin ON regioes FOR INSERT WITH CHECK (((EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = 'administrador'::text)))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_nacional_iurd'::text, 'lider_nacional_fju'::text]))))) OR (EXISTS ( SELECT 1
   FROM (usuarios u
     JOIN blocos b ON ((b.id = regioes.bloco_id)))
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_estadual_iurd'::text, 'lider_estadual_fju'::text])) AND (u.estado_id = b.estado_id)))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_bloco_iurd'::text, 'lider_bloco_fju'::text])) AND (u.bloco_id = regioes.bloco_id))))));

CREATE POLICY regioes_select_all ON regioes FOR SELECT USING (true);

CREATE POLICY regioes_update_admin ON regioes FOR UPDATE USING (((EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = 'administrador'::text)))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_nacional_iurd'::text, 'lider_nacional_fju'::text]))))) OR (EXISTS ( SELECT 1
   FROM (usuarios u
     JOIN blocos b ON ((b.id = regioes.bloco_id)))
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_estadual_iurd'::text, 'lider_estadual_fju'::text])) AND (u.estado_id = b.estado_id)))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_bloco_iurd'::text, 'lider_bloco_fju'::text])) AND (u.bloco_id = regioes.bloco_id)))))) WITH CHECK (((EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = 'administrador'::text)))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_nacional_iurd'::text, 'lider_nacional_fju'::text]))))) OR (EXISTS ( SELECT 1
   FROM (usuarios u
     JOIN blocos b ON ((b.id = regioes.bloco_id)))
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_estadual_iurd'::text, 'lider_estadual_fju'::text])) AND (u.estado_id = b.estado_id)))) OR (EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = ANY (ARRAY['lider_bloco_iurd'::text, 'lider_bloco_fju'::text])) AND (u.bloco_id = regioes.bloco_id))))));

-- ROLES
CREATE POLICY "Allow all for admin" ON roles USING (has_role('administrador'::text));
CREATE POLICY "Allow read for authenticated users" ON roles FOR SELECT USING ((auth.role() = 'authenticated'::text));

-- SESSOES_USUARIO
CREATE POLICY allow_read_sessoes_usuario ON sessoes_usuario FOR SELECT USING (true);

-- USER_ROLES
CREATE POLICY "Allow all for admin" ON user_roles USING (has_role('administrador'::text));
CREATE POLICY "Allow delete for admin" ON user_roles FOR DELETE USING (has_role('administrador'::text));
CREATE POLICY "Allow insert for admin" ON user_roles FOR INSERT WITH CHECK (has_role('administrador'::text));
CREATE POLICY "Allow read for authenticated users" ON user_roles FOR SELECT USING ((auth.role() = 'authenticated'::text));
CREATE POLICY "Allow update for admin" ON user_roles FOR UPDATE USING (has_role('administrador'::text));

-- USUARIOS
CREATE POLICY "Allow admin all access" ON usuarios TO authenticated USING ((EXISTS ( SELECT 1
   FROM usuarios u
  WHERE ((u.id_auth = auth.uid()) AND (u.nivel = 'administrador'::text)))));
CREATE POLICY "Allow insert for signup" ON usuarios FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Allow select own profile" ON usuarios FOR SELECT TO authenticated USING ((id_auth = auth.uid()));
CREATE POLICY "Allow update own profile" ON usuarios FOR UPDATE TO authenticated USING ((id_auth = auth.uid())) WITH CHECK ((id_auth = auth.uid()));

-- =====================================================
-- FIM DO SCRIPT
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE 'POLICIES ORIGINAIS RESTAURADAS COM SUCESSO!';
    RAISE NOTICE 'Todas as policies que estavam funcionando perfeitamente foram restauradas.';
END $$;
