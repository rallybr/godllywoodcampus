-- Script para verificar policies RLS de DELETE para regiões

-- 1. Verificar se existem policies de DELETE para regioes
SELECT 
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'regioes' AND cmd = 'DELETE';

-- 2. Se não existir policy de DELETE, criar uma
-- (Execute apenas se não houver policies de DELETE)

-- Policy para administradores
CREATE POLICY "regioes_delete_admin" ON regioes
FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM usuarios u 
        WHERE u.id = auth.uid() 
        AND u.nivel = 'administrador'
    )
);

-- Policy para líderes nacionais
CREATE POLICY "regioes_delete_lider_nacional" ON regioes
FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM usuarios u 
        WHERE u.id = auth.uid() 
        AND u.nivel = 'lider_nacional'
    )
);

-- Policy para líderes estaduais (do seu estado)
CREATE POLICY "regioes_delete_lider_estadual" ON regioes
FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM usuarios u 
        JOIN blocos b ON b.estado_id = u.estado_id
        WHERE u.id = auth.uid() 
        AND u.nivel = 'lider_estadual_fju'
        AND b.id = regioes.bloco_id
    )
);

-- Policy para líderes de bloco (do seu bloco)
CREATE POLICY "regioes_delete_lider_bloco" ON regioes
FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM usuarios u 
        WHERE u.id = auth.uid() 
        AND u.nivel = 'lider_bloco'
        AND u.bloco_id = regioes.bloco_id
    )
);

-- Policy para líderes regionais (da sua região)
CREATE POLICY "regioes_delete_lider_regional" ON regioes
FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM usuarios u 
        WHERE u.id = auth.uid() 
        AND u.nivel = 'lider_regional'
        AND u.regiao_id = regioes.id
    )
);
