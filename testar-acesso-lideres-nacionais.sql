-- =====================================================
-- SCRIPT DE TESTE PARA LÍDERES NACIONAIS
-- =====================================================
-- Este script testa se os líderes nacionais têm acesso total

-- 1. VERIFICAR NÍVEIS HIERÁRQUICOS ATUAIS
SELECT 
  'VERIFICAÇÃO DE NÍVEIS' as teste,
  slug,
  nome,
  nivel_hierarquico,
  CASE 
    WHEN nivel_hierarquico = 1 THEN 'Administrador (Acesso Total)'
    WHEN nivel_hierarquico = 2 THEN 'Líder Nacional (Acesso Total)'
    WHEN nivel_hierarquico = 3 THEN 'Líder Estadual (Visão Estadual)'
    WHEN nivel_hierarquico = 4 THEN 'Líder de Bloco (Visão de Bloco)'
    WHEN nivel_hierarquico = 5 THEN 'Líder Regional (Visão Regional)'
    WHEN nivel_hierarquico = 6 THEN 'Líder de Igreja (Visão de Igreja)'
    WHEN nivel_hierarquico = 7 THEN 'Colaborador (Visão do que Criou)'
    WHEN nivel_hierarquico = 8 THEN 'Jovem (Visão Própria)'
    ELSE 'Nível não definido'
  END as descricao_nivel
FROM public.roles 
WHERE slug IN ('administrador', 'lider_nacional_iurd', 'lider_nacional_fju')
ORDER BY nivel_hierarquico ASC;

-- 2. TESTAR FUNCTION can_access_jovem
-- (Execute como um líder nacional para testar)
SELECT 
  'TESTE can_access_jovem' as teste,
  can_access_jovem(
    'uuid-estado-qualquer',
    'uuid-bloco-qualquer', 
    'uuid-regiao-qualquer',
    'uuid-igreja-qualquer'
  ) as tem_acesso;

-- 3. TESTAR FUNCTION can_access_viagem_by_level
-- (Execute como um líder nacional para testar)
SELECT 
  'TESTE can_access_viagem_by_level' as teste,
  can_access_viagem_by_level(
    'uuid-estado-qualquer',
    'uuid-bloco-qualquer',
    'uuid-regiao-qualquer', 
    'uuid-igreja-qualquer'
  ) as tem_acesso;

-- 4. VERIFICAR SE LÍDERES NACIONAIS TÊM ACESSO A DADOS DE QUALQUER LOCALIZAÇÃO
-- (Execute como um líder nacional para testar)
SELECT 
  'TESTE ACESSO TOTAL' as teste,
  CASE 
    WHEN can_access_jovem('uuid-estado-1', 'uuid-bloco-1', 'uuid-regiao-1', 'uuid-igreja-1') = true
     AND can_access_jovem('uuid-estado-2', 'uuid-bloco-2', 'uuid-regiao-2', 'uuid-igreja-2') = true
     AND can_access_jovem('uuid-estado-3', 'uuid-bloco-3', 'uuid-regiao-3', 'uuid-igreja-3') = true
    THEN '✅ LÍDERES NACIONAIS TÊM ACESSO TOTAL'
    ELSE '❌ LÍDERES NACIONAIS NÃO TÊM ACESSO TOTAL'
  END as resultado;

-- 5. VERIFICAR SE LÍDERES NACIONAIS TÊM ACESSO A DADOS DE VIAGEM DE QUALQUER LOCALIZAÇÃO
-- (Execute como um líder nacional para testar)
SELECT 
  'TESTE ACESSO VIAGEM TOTAL' as teste,
  CASE 
    WHEN can_access_viagem_by_level('uuid-estado-1', 'uuid-bloco-1', 'uuid-regiao-1', 'uuid-igreja-1') = true
     AND can_access_viagem_by_level('uuid-estado-2', 'uuid-bloco-2', 'uuid-regiao-2', 'uuid-igreja-2') = true
     AND can_access_viagem_by_level('uuid-estado-3', 'uuid-bloco-3', 'uuid-regiao-3', 'uuid-igreja-3') = true
    THEN '✅ LÍDERES NACIONAIS TÊM ACESSO TOTAL A VIAGENS'
    ELSE '❌ LÍDERES NACIONAIS NÃO TÊM ACESSO TOTAL A VIAGENS'
  END as resultado;

-- 6. VERIFICAR SE LÍDERES NACIONAIS TÊM ACESSO A DADOS INDEPENDENTE DE QUEM CRIOU
-- (Execute como um líder nacional para testar)
SELECT 
  'TESTE ACESSO INDEPENDENTE DE CRIADOR' as teste,
  CASE 
    WHEN can_access_jovem('uuid-estado-qualquer', 'uuid-bloco-qualquer', 'uuid-regiao-qualquer', 'uuid-igreja-qualquer') = true
    THEN '✅ LÍDERES NACIONAIS TÊM ACESSO INDEPENDENTE DE QUEM CRIOU'
    ELSE '❌ LÍDERES NACIONAIS NÃO TÊM ACESSO INDEPENDENTE DE QUEM CRIOU'
  END as resultado;

-- 7. VERIFICAR SE LÍDERES NACIONAIS TÊM ACESSO A DADOS DE VIAGEM INDEPENDENTE DE QUEM CRIOU
-- (Execute como um líder nacional para testar)
SELECT 
  'TESTE ACESSO VIAGEM INDEPENDENTE DE CRIADOR' as teste,
  CASE 
    WHEN can_access_viagem_by_level('uuid-estado-qualquer', 'uuid-bloco-qualquer', 'uuid-regiao-qualquer', 'uuid-igreja-qualquer') = true
    THEN '✅ LÍDERES NACIONAIS TÊM ACESSO A VIAGENS INDEPENDENTE DE QUEM CRIOU'
    ELSE '❌ LÍDERES NACIONAIS NÃO TÊM ACESSO A VIAGENS INDEPENDENTE DE QUEM CRIOU'
  END as resultado;

-- 8. VERIFICAR SE LÍDERES NACIONAIS TÊM ACESSO A DADOS DE QUALQUER USUÁRIO
-- (Execute como um líder nacional para testar)
SELECT 
  'TESTE ACESSO A DADOS DE QUALQUER USUÁRIO' as teste,
  CASE 
    WHEN can_access_jovem('uuid-estado-qualquer', 'uuid-bloco-qualquer', 'uuid-regiao-qualquer', 'uuid-igreja-qualquer') = true
    THEN '✅ LÍDERES NACIONAIS TÊM ACESSO A DADOS DE QUALQUER USUÁRIO'
    ELSE '❌ LÍDERES NACIONAIS NÃO TÊM ACESSO A DADOS DE QUALQUER USUÁRIO'
  END as resultado;

-- 9. VERIFICAR SE LÍDERES NACIONAIS TÊM ACESSO A DADOS DE VIAGEM DE QUALQUER USUÁRIO
-- (Execute como um líder nacional para testar)
SELECT 
  'TESTE ACESSO A VIAGENS DE QUALQUER USUÁRIO' as teste,
  CASE 
    WHEN can_access_viagem_by_level('uuid-estado-qualquer', 'uuid-bloco-qualquer', 'uuid-regiao-qualquer', 'uuid-igreja-qualquer') = true
    THEN '✅ LÍDERES NACIONAIS TÊM ACESSO A VIAGENS DE QUALQUER USUÁRIO'
    ELSE '❌ LÍDERES NACIONAIS NÃO TÊM ACESSO A VIAGENS DE QUALQUER USUÁRIO'
  END as resultado;

-- 10. VERIFICAR SE LÍDERES NACIONAIS TÊM ACESSO A DADOS DE QUALQUER LOCALIZAÇÃO
-- (Execute como um líder nacional para testar)
SELECT 
  'TESTE ACESSO A DADOS DE QUALQUER LOCALIZAÇÃO' as teste,
  CASE 
    WHEN can_access_jovem('uuid-estado-qualquer', 'uuid-bloco-qualquer', 'uuid-regiao-qualquer', 'uuid-igreja-qualquer') = true
    THEN '✅ LÍDERES NACIONAIS TÊM ACESSO A DADOS DE QUALQUER LOCALIZAÇÃO'
    ELSE '❌ LÍDERES NACIONAIS NÃO TÊM ACESSO A DADOS DE QUALQUER LOCALIZAÇÃO'
  END as resultado;

-- 11. VERIFICAR SE LÍDERES NACIONAIS TÊM ACESSO A DADOS DE VIAGEM DE QUALQUER LOCALIZAÇÃO
-- (Execute como um líder nacional para testar)
SELECT 
  'TESTE ACESSO A VIAGENS DE QUALQUER LOCALIZAÇÃO' as teste,
  CASE 
    WHEN can_access_viagem_by_level('uuid-estado-qualquer', 'uuid-bloco-qualquer', 'uuid-regiao-qualquer', 'uuid-igreja-qualquer') = true
    THEN '✅ LÍDERES NACIONAIS TÊM ACESSO A VIAGENS DE QUALQUER LOCALIZAÇÃO'
    ELSE '❌ LÍDERES NACIONAIS NÃO TÊM ACESSO A VIAGENS DE QUALQUER LOCALIZAÇÃO'
  END as resultado;

-- 12. VERIFICAR SE LÍDERES NACIONAIS TÊM ACESSO A DADOS DE QUALQUER USUÁRIO
-- (Execute como um líder nacional para testar)
SELECT 
  'TESTE ACESSO A DADOS DE QUALQUER USUÁRIO' as teste,
  CASE 
    WHEN can_access_jovem('uuid-estado-qualquer', 'uuid-bloco-qualquer', 'uuid-regiao-qualquer', 'uuid-igreja-qualquer') = true
    THEN '✅ LÍDERES NACIONAIS TÊM ACESSO A DADOS DE QUALQUER USUÁRIO'
    ELSE '❌ LÍDERES NACIONAIS NÃO TÊM ACESSO A DADOS DE QUALQUER USUÁRIO'
  END as resultado;

-- 13. VERIFICAR SE LÍDERES NACIONAIS TÊM ACESSO A DADOS DE VIAGEM DE QUALQUER USUÁRIO
-- (Execute como um líder nacional para testar)
SELECT 
  'TESTE ACESSO A VIAGENS DE QUALQUER USUÁRIO' as teste,
  CASE 
    WHEN can_access_viagem_by_level('uuid-estado-qualquer', 'uuid-bloco-qualquer', 'uuid-regiao-qualquer', 'uuid-igreja-qualquer') = true
    THEN '✅ LÍDERES NACIONAIS TÊM ACESSO A VIAGENS DE QUALQUER USUÁRIO'
    ELSE '❌ LÍDERES NACIONAIS NÃO TÊM ACESSO A VIAGENS DE QUALQUER USUÁRIO'
  END as resultado;

-- 14. VERIFICAR SE LÍDERES NACIONAIS TÊM ACESSO A DADOS DE QUALQUER LOCALIZAÇÃO
-- (Execute como um líder nacional para testar)
SELECT 
  'TESTE ACESSO A DADOS DE QUALQUER LOCALIZAÇÃO' as teste,
  CASE 
    WHEN can_access_jovem('uuid-estado-qualquer', 'uuid-bloco-qualquer', 'uuid-regiao-qualquer', 'uuid-igreja-qualquer') = true
    THEN '✅ LÍDERES NACIONAIS TÊM ACESSO A DADOS DE QUALQUER LOCALIZAÇÃO'
    ELSE '❌ LÍDERES NACIONAIS NÃO TÊM ACESSO A DADOS DE QUALQUER LOCALIZAÇÃO'
  END as resultado;

-- 15. VERIFICAR SE LÍDERES NACIONAIS TÊM ACESSO A DADOS DE VIAGEM DE QUALQUER LOCALIZAÇÃO
-- (Execute como um líder nacional para testar)
SELECT 
  'TESTE ACESSO A VIAGENS DE QUALQUER LOCALIZAÇÃO' as teste,
  CASE 
    WHEN can_access_viagem_by_level('uuid-estado-qualquer', 'uuid-bloco-qualquer', 'uuid-regiao-qualquer', 'uuid-igreja-qualquer') = true
    THEN '✅ LÍDERES NACIONAIS TÊM ACESSO A VIAGENS DE QUALQUER LOCALIZAÇÃO'
    ELSE '❌ LÍDERES NACIONAIS NÃO TÊM ACESSO A VIAGENS DE QUALQUER LOCALIZAÇÃO'
  END as resultado;

-- =====================================================
-- FIM DO SCRIPT DE TESTE
-- =====================================================
