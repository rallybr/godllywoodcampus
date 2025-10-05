-- Script para testar as políticas hierárquicas da tabela dados_nucleo
-- Execute este script para verificar se o controle de acesso está funcionando

-- 1. Verificar o usuário atual e seu nível
SELECT 
  u.id as user_id,
  u.nivel,
  u.nome,
  u.estado_id,
  u.bloco_id,
  u.regiao_id,
  u.igreja_id
FROM usuarios u 
WHERE u.id_auth = auth.uid();

-- 2. Verificar quantos registros de dados_nucleo existem
SELECT COUNT(*) as total_registros FROM dados_nucleo;

-- 3. Testar acesso SELECT para o usuário atual
SELECT 
  dn.id,
  dn.jovem_id,
  dn.faz_nucleo,
  j.nome_completo as jovem_nome,
  j.estado_id as jovem_estado,
  j.bloco_id as jovem_bloco,
  j.regiao_id as jovem_regiao,
  j.igreja_id as jovem_igreja
FROM dados_nucleo dn
JOIN jovens j ON j.id = dn.jovem_id
ORDER BY j.nome_completo;

-- 4. Verificar se as políticas estão bloqueando acesso inadequado
-- (Este teste deve retornar apenas registros que o usuário tem permissão para ver)

-- 5. Testar inserção de dados (apenas se for jovem, colaborador ou administrador)
-- Descomente as linhas abaixo para testar inserção:
/*
INSERT INTO dados_nucleo (
  jovem_id,
  faz_nucleo,
  ha_quanto_tempo,
  media_pessoas
) VALUES (
  'ID_DO_JOVEM_AQUI', -- Substitua pelo ID de um jovem
  true,
  '1 ano',
  10
);
*/

-- 6. Verificar políticas específicas por nível
-- Administrador deve ver todos os registros
-- Líder estadual deve ver apenas registros do seu estado
-- Líder de bloco deve ver apenas registros do seu bloco
-- Líder regional deve ver apenas registros da sua região
-- Líder de igreja deve ver apenas registros da sua igreja
-- Colaborador deve ver apenas registros dos jovens que cadastrou
-- Jovem deve ver apenas seus próprios registros
