-- =====================================================
-- TESTAR QUERY EXATA DO SUPABASE
-- =====================================================

-- Simular a query que o Supabase está fazendo
SELECT 
    a.*,
    json_build_object(
        'nome', u.nome,
        'foto', u.foto,
        'email', u.email
    ) as avaliador
FROM avaliacoes a
LEFT JOIN usuarios u ON a.user_id = u.id
ORDER BY a.criado_em DESC
LIMIT 3;
