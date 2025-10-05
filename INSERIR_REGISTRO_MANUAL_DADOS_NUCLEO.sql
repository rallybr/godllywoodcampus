-- Script para inserir um registro manual na tabela dados_nucleo
-- Execute este script no SQL Editor do Supabase

-- 1. Primeiro, vamos verificar o ID do usuário atual
SELECT 
  u.id as user_id,
  u.nivel,
  u.nome,
  auth.uid() as current_auth_uid
FROM usuarios u 
WHERE u.id_auth = auth.uid();

-- 2. Inserir um registro manual na tabela dados_nucleo
INSERT INTO public.dados_nucleo (
  jovem_id,
  faz_nucleo,
  ja_fez_nucleo,
  dias_semana,
  ha_quanto_tempo,
  foi_voce_que_iniciou,
  media_pessoas,
  foto_1,
  foto_2,
  foto_3,
  foto_4,
  foto_5,
  video_link,
  video_plataforma,
  tem_obreiros,
  quantos_obreiros,
  alguem_ajuda,
  quem_ajuda,
  quantas_pessoas_vao_igreja,
  maior_experiencia,
  observacao_geral,
  criado_em,
  atualizado_em
) VALUES (
  -- Substitua pelo ID do usuário atual (copie do resultado da query acima)
  'e745720c-e9f7-4562-978b-72ba32387420'::uuid,
  
  -- Dados do núcleo
  true,  -- faz_nucleo
  false, -- ja_fez_nucleo
  '["segunda", "quarta", "sexta"]'::jsonb, -- dias_semana
  '2 anos', -- ha_quanto_tempo
  true,  -- foi_voce_que_iniciou
  15,    -- media_pessoas
  
  -- Fotos (URLs de exemplo)
  'https://exemplo.com/foto1.jpg', -- foto_1
  'https://exemplo.com/foto2.jpg', -- foto_2
  '', -- foto_3
  '', -- foto_4
  '', -- foto_5
  
  -- Vídeo
  'https://www.youtube.com/watch?v=exemplo', -- video_link
  'youtube', -- video_plataforma
  
  -- Obreiros
  true,  -- tem_obreiros
  3,     -- quantos_obreiros
  
  -- Ajuda
  true,  -- alguem_ajuda
  'João e Maria', -- quem_ajuda
  
  -- Igreja
  12,    -- pessoas_na_igreja
  
  -- Experiência
  'Minha maior experiência foi quando conseguimos orar por 3 horas seguidas e vimos várias pessoas sendo curadas e libertas. Foi um momento marcante na minha vida espiritual.', -- maior_experiencia
  
  -- Observação geral
  'Este é um registro de teste inserido manualmente para verificar se a tabela está funcionando corretamente.', -- observacao_geral
  
  -- Timestamps
  NOW(), -- criado_em
  NOW()  -- atualizado_em
);

-- 3. Verificar se o registro foi inserido
SELECT 
  id,
  jovem_id,
  faz_nucleo,
  ha_quanto_tempo,
  media_pessoas,
  criado_em
FROM public.dados_nucleo 
WHERE jovem_id = 'e745720c-e9f7-4562-978b-72ba32387420'::uuid;

-- 4. Se quiser deletar o registro de teste depois
-- DELETE FROM public.dados_nucleo WHERE jovem_id = 'e745720c-e9f7-4562-978b-72ba32387420'::uuid;
