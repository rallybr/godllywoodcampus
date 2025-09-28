-- =====================================================
-- CORRIGIR NÍVEIS HIERÁRQUICOS INCONSISTENTES
-- =====================================================

-- Atualizar níveis hierárquicos para serem consistentes com o código
UPDATE public.roles SET nivel_hierarquico = 1 WHERE slug = 'administrador';
UPDATE public.roles SET nivel_hierarquico = 2 WHERE slug = 'lider_nacional_iurd';
UPDATE public.roles SET nivel_hierarquico = 2 WHERE slug = 'lider_nacional_fju';
UPDATE public.roles SET nivel_hierarquico = 3 WHERE slug = 'lider_estadual_iurd';
UPDATE public.roles SET nivel_hierarquico = 3 WHERE slug = 'lider_estadual_fju';
UPDATE public.roles SET nivel_hierarquico = 4 WHERE slug = 'lider_bloco_iurd';
UPDATE public.roles SET nivel_hierarquico = 4 WHERE slug = 'lider_bloco_fju';
UPDATE public.roles SET nivel_hierarquico = 5 WHERE slug = 'lider_regional_iurd';
UPDATE public.roles SET nivel_hierarquico = 6 WHERE slug = 'lider_igreja_iurd';
UPDATE public.roles SET nivel_hierarquico = 7 WHERE slug = 'colaborador';
UPDATE public.roles SET nivel_hierarquico = 8 WHERE slug = 'jovem';

-- Verificar resultado
SELECT 
    nome,
    slug,
    nivel_hierarquico,
    descricao
FROM public.roles 
ORDER BY nivel_hierarquico;
