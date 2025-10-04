-- =====================================================
-- TESTE: ASSOCIAÇÃO DE JOVENS PARA TODOS OS NÍVEIS
-- =====================================================
-- Script para testar se jovens associados aparecem para todos os níveis

-- ============================================
-- 1. VERIFICAR POLICIES ATIVAS
-- ============================================

SELECT 
  'POLICIES ATIVAS' as status,
  policyname,
  cmd,
  permissive,
  roles
FROM pg_policies 
WHERE tablename = 'jovens' 
ORDER BY policyname;

-- ============================================
-- 2. VERIFICAR ESTRUTURA DA TABELA JOVENS
-- ============================================

SELECT 
  'ESTRUTURA TABELA JOVENS' as status,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'jovens' 
  AND column_name IN ('id', 'usuario_id', 'estado_id', 'bloco_id', 'regiao_id', 'igreja_id')
ORDER BY ordinal_position;

-- ============================================
-- 3. TESTE DE ACESSO POR NÍVEL
-- ============================================

-- Simular acesso de diferentes níveis de usuário
-- (Este teste deve ser executado com diferentes usuários logados)

-- Teste 1: Verificar se jovens associados aparecem
SELECT 
  'TESTE: Jovens associados por nível' as status,
  u.nivel,
  u.nome as usuario_nome,
  COUNT(j.id) as total_jovens_associados
FROM public.usuarios u
LEFT JOIN public.jovens j ON j.usuario_id = u.id
WHERE u.nivel IN ('lider_estadual_fju', 'lider_bloco_fju', 'lider_regional_iurd', 'lider_igreja_iurd', 'colaborador')
GROUP BY u.nivel, u.nome, u.id
ORDER BY u.nivel, u.nome;

-- ============================================
-- 4. VERIFICAR JOVENS POR HIERARQUIA GEOGRÁFICA
-- ============================================

-- Teste 2: Verificar jovens por hierarquia geográfica
SELECT 
  'TESTE: Jovens por hierarquia' as status,
  e.nome as estado,
  b.nome as bloco,
  r.nome as regiao,
  i.nome as igreja,
  COUNT(j.id) as total_jovens
FROM public.jovens j
LEFT JOIN public.estados e ON e.id = j.estado_id
LEFT JOIN public.blocos b ON b.id = j.bloco_id
LEFT JOIN public.regioes r ON r.id = j.regiao_id
LEFT JOIN public.igrejas i ON i.id = j.igreja_id
GROUP BY e.nome, b.nome, r.nome, i.nome
ORDER BY e.nome, b.nome, r.nome, i.nome;

-- ============================================
-- 5. TESTE DE ASSOCIAÇÃO MANUAL
-- ============================================

-- Teste 3: Simular associação de jovem a usuário
-- (Execute este teste com um jovem e um usuário específico)

-- Exemplo: Associar jovem ID 'xxx' ao usuário ID 'yyy'
-- UPDATE public.jovens 
-- SET usuario_id = 'yyy' 
-- WHERE id = 'xxx';

-- ============================================
-- 6. VERIFICAR RESULTADO DA ASSOCIAÇÃO
-- ============================================

-- Verificar se o jovem associado aparece para o usuário
SELECT 
  'RESULTADO: Jovem associado aparece?' as status,
  j.id as jovem_id,
  j.nome_completo as jovem_nome,
  u.id as usuario_id,
  u.nome as usuario_nome,
  u.nivel as usuario_nivel
FROM public.jovens j
JOIN public.usuarios u ON u.id = j.usuario_id
WHERE j.usuario_id IS NOT NULL
ORDER BY u.nivel, u.nome, j.nome_completo;

-- ============================================
-- 7. INSTRUÇÕES PARA TESTE MANUAL
-- ============================================

/*
INSTRUÇÕES PARA TESTE MANUAL:

1. Execute o script CORRECAO_ASSOCIACAO_JOVENS.sql no Supabase SQL Editor

2. Faça login como administrador no sistema

3. Vá para a página de jovens e selecione um jovem

4. Clique em "Associar Usuário" 

5. Busque por um usuário de qualquer nível (não apenas colaborador)

6. Associe o jovem ao usuário selecionado

7. Faça logout e login com o usuário associado

8. Verifique se o jovem aparece na lista de jovens para esse usuário

9. Teste com diferentes níveis:
   - Líder estadual
   - Líder de bloco  
   - Líder regional
   - Líder de igreja
   - Colaborador
   - Jovem

10. Verifique se o jovem aparece independente da hierarquia geográfica
*/
