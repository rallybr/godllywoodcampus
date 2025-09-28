-- =====================================================
-- DIAGNÓSTICO COMPLETO DO SISTEMA DE NÍVEIS
-- =====================================================
-- Este script identifica inconsistências entre níveis e papéis

-- ============================================
-- 1. VERIFICAR USUÁRIO ATUAL E SEUS DADOS
-- ============================================

SELECT 
  'DADOS COMPLETOS DO USUÁRIO ATUAL' as categoria,
  u.id,
  u.nome,
  u.nivel,
  u.estado_id,
  u.bloco_id,
  u.regiao_id,
  u.igreja_id,
  e.nome as estado_nome,
  b.nome as bloco_nome,
  r.nome as regiao_nome,
  i.nome as igreja_nome
FROM public.usuarios u
LEFT JOIN public.estados e ON e.id = u.estado_id
LEFT JOIN public.blocos b ON b.id = u.bloco_id
LEFT JOIN public.regioes r ON r.id = u.regiao_id
LEFT JOIN public.igrejas i ON i.id = u.igreja_id
WHERE u.id_auth = auth.uid();

-- ============================================
-- 2. VERIFICAR PAPÉIS ATRIBUÍDOS AO USUÁRIO
-- ============================================

SELECT 
  'PAPÉIS ATRIBUÍDOS AO USUÁRIO ATUAL' as categoria,
  ur.id as papel_id,
  r.nome as papel_nome,
  r.slug as papel_slug,
  r.nivel_hierarquico,
  ur.ativo,
  ur.estado_id as papel_estado_id,
  ur.bloco_id as papel_bloco_id,
  ur.regiao_id as papel_regiao_id,
  ur.igreja_id as papel_igreja_id,
  e.nome as papel_estado_nome,
  b.nome as papel_bloco_nome,
  r2.nome as papel_regiao_nome,
  i.nome as papel_igreja_nome
FROM public.user_roles ur
JOIN public.roles r ON r.id = ur.role_id
LEFT JOIN public.estados e ON e.id = ur.estado_id
LEFT JOIN public.blocos b ON b.id = ur.bloco_id
LEFT JOIN public.regioes r2 ON r2.id = ur.regiao_id
LEFT JOIN public.igrejas i ON i.id = ur.igreja_id
WHERE ur.user_id = (SELECT id FROM public.usuarios WHERE id_auth = auth.uid())
ORDER BY r.nivel_hierarquico;

-- ============================================
-- 3. VERIFICAR INCONSISTÊNCIAS ENTRE NÍVEL E PAPÉIS
-- ============================================

SELECT 
  'VERIFICAÇÃO DE INCONSISTÊNCIAS' as categoria,
  CASE 
    WHEN u.nivel = 'administrador' AND NOT EXISTS (
      SELECT 1 FROM public.user_roles ur 
      JOIN public.roles r ON r.id = ur.role_id 
      WHERE ur.user_id = u.id AND r.slug = 'administrador' AND ur.ativo = true
    ) THEN '❌ PROBLEMA: Nível administrador mas sem papel administrador'
    
    WHEN u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') AND NOT EXISTS (
      SELECT 1 FROM public.user_roles ur 
      JOIN public.roles r ON r.id = ur.role_id 
      WHERE ur.user_id = u.id AND r.slug IN ('lider_estadual_iurd', 'lider_estadual_fju') AND ur.ativo = true
    ) THEN '❌ PROBLEMA: Nível estadual mas sem papel estadual'
    
    WHEN u.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') AND NOT EXISTS (
      SELECT 1 FROM public.user_roles ur 
      JOIN public.roles r ON r.id = ur.role_id 
      WHERE ur.user_id = u.id AND r.slug IN ('lider_bloco_iurd', 'lider_bloco_fju') AND ur.ativo = true
    ) THEN '❌ PROBLEMA: Nível bloco mas sem papel bloco'
    
    WHEN u.nivel = 'lider_regional_iurd' AND NOT EXISTS (
      SELECT 1 FROM public.user_roles ur 
      JOIN public.roles r ON r.id = ur.role_id 
      WHERE ur.user_id = u.id AND r.slug = 'lider_regional_iurd' AND ur.ativo = true
    ) THEN '❌ PROBLEMA: Nível regional mas sem papel regional'
    
    WHEN u.nivel = 'lider_igreja_iurd' AND NOT EXISTS (
      SELECT 1 FROM public.user_roles ur 
      JOIN public.roles r ON r.id = ur.role_id 
      WHERE ur.user_id = u.id AND r.slug = 'lider_igreja_iurd' AND ur.ativo = true
    ) THEN '❌ PROBLEMA: Nível igreja mas sem papel igreja'
    
    ELSE '✅ OK: Nível e papéis consistentes'
  END as status_consistencia
FROM public.usuarios u
WHERE u.id_auth = auth.uid();

-- ============================================
-- 4. TESTAR FUNÇÃO can_access_jovem
-- ============================================

-- Teste da função com dados reais
SELECT 
  'TESTE DA FUNÇÃO can_access_jovem' as categoria,
  COUNT(*) as total_jovens,
  COUNT(CASE WHEN can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id) THEN 1 END) as jovens_acessiveis,
  ROUND(
    (COUNT(CASE WHEN can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id) THEN 1 END) * 100.0 / COUNT(*)), 
    2
  ) as percentual_acesso
FROM public.jovens;

-- ============================================
-- 5. VERIFICAR DADOS GEOGRÁFICOS DO USUÁRIO
-- ============================================

-- Verificar se o usuário tem dados geográficos corretos
SELECT 
  'VERIFICAÇÃO DE DADOS GEOGRÁFICOS' as categoria,
  CASE 
    WHEN u.estado_id IS NULL THEN '❌ PROBLEMA: Usuário sem estado_id'
    WHEN u.bloco_id IS NULL THEN '⚠️ AVISO: Usuário sem bloco_id'
    WHEN u.regiao_id IS NULL THEN '⚠️ AVISO: Usuário sem regiao_id'
    WHEN u.igreja_id IS NULL THEN '⚠️ AVISO: Usuário sem igreja_id'
    ELSE '✅ OK: Dados geográficos presentes'
  END as status_geografico,
  u.estado_id,
  u.bloco_id,
  u.regiao_id,
  u.igreja_id
FROM public.usuarios u
WHERE u.id_auth = auth.uid();

-- ============================================
-- 6. VERIFICAR JOVENS NA GEOGRAFIA DO USUÁRIO
-- ============================================

-- Verificar se existem jovens na geografia do usuário
SELECT 
  'JOVENS NA GEOGRAFIA DO USUÁRIO' as categoria,
  COUNT(*) as total_jovens_geografia,
  COUNT(CASE WHEN can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id) THEN 1 END) as jovens_acessiveis
FROM public.jovens j
WHERE j.estado_id = (SELECT estado_id FROM public.usuarios WHERE id_auth = auth.uid())
   OR j.bloco_id = (SELECT bloco_id FROM public.usuarios WHERE id_auth = auth.uid())
   OR j.regiao_id = (SELECT regiao_id FROM public.usuarios WHERE id_auth = auth.uid())
   OR j.igreja_id = (SELECT igreja_id FROM public.usuarios WHERE id_auth = auth.uid());

-- ============================================
-- 7. LISTAR JOVENS ACESSÍVEIS
-- ============================================

-- Listar jovens que o usuário deveria ver
SELECT 
  'JOVENS QUE O USUÁRIO DEVERIA VER' as categoria,
  j.id,
  j.nome_completo,
  j.estado_id,
  j.bloco_id,
  j.regiao_id,
  j.igreja_id,
  e.nome as estado_nome,
  b.nome as bloco_nome,
  r.nome as regiao_nome,
  i.nome as igreja_nome,
  can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id) as tem_acesso
FROM public.jovens j
LEFT JOIN public.estados e ON e.id = j.estado_id
LEFT JOIN public.blocos b ON b.id = j.bloco_id
LEFT JOIN public.regioes r ON r.id = j.regiao_id
LEFT JOIN public.igrejas i ON i.id = j.igreja_id
WHERE can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id)
ORDER BY j.nome_completo
LIMIT 10;

-- ============================================
-- 8. RESUMO DO DIAGNÓSTICO
-- ============================================

SELECT 
  'RESUMO DO DIAGNÓSTICO' as status,
  'Execute este script para identificar problemas específicos' as instrucao,
  'Verifique inconsistências entre nível e papéis' as verificacao_1,
  'Confirme dados geográficos do usuário' as verificacao_2,
  'Teste acesso a jovens da geografia' as verificacao_3;
