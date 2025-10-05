-- Script para verificar e corrigir o ID do jovem
-- Execute este script no SQL Editor do Supabase

-- 1. Verificar o usuário atual
SELECT 
  u.id as user_id,
  u.nivel,
  u.nome,
  auth.uid() as current_auth_uid
FROM usuarios u 
WHERE u.id_auth = auth.uid();

-- 2. Verificar se existe jovem com esse ID
SELECT 
  j.id as jovem_id,
  j.nome_completo,
  j.usuario_id
FROM jovens j 
WHERE j.id = 'e745720c-e9f7-4562-978b-72ba32387420'::uuid;

-- 3. Verificar se existe jovem associado ao usuário atual
SELECT 
  j.id as jovem_id,
  j.nome_completo,
  j.usuario_id
FROM jovens j 
WHERE j.usuario_id = (
  SELECT u.id FROM usuarios u WHERE u.id_auth = auth.uid()
);

-- 4. Se não existir jovem, vamos criar um para teste
INSERT INTO public.jovens (
  id,
  nome_completo,
  usuario_id,
  data_cadastro,
  data_nasc,
  edicao
) VALUES (
  'e745720c-e9f7-4562-978b-72ba32387420'::uuid,
  'Jovem de Teste',
  (SELECT u.id FROM usuarios u WHERE u.id_auth = auth.uid()),
  NOW(),
  '1990-01-01'::date,
  'Teste'
) ON CONFLICT (id) DO NOTHING;

-- 5. Verificar se o jovem foi criado
SELECT 
  j.id as jovem_id,
  j.nome_completo,
  j.usuario_id
FROM jovens j 
WHERE j.id = 'e745720c-e9f7-4562-978b-72ba32387420'::uuid;

-- 6. Agora tentar inserir os dados do núcleo
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
  'e745720c-e9f7-4562-978b-72ba32387420'::uuid,
  true,
  false,
  '["segunda", "quarta", "sexta"]'::jsonb,
  '2 anos',
  true,
  15,
  'https://exemplo.com/foto1.jpg',
  'https://exemplo.com/foto2.jpg',
  '',
  '',
  '',
  'https://www.youtube.com/watch?v=exemplo',
  'youtube',
  true,
  3,
  true,
  'João e Maria',
  12,
  'Minha maior experiência foi quando conseguimos orar por 3 horas seguidas e vimos várias pessoas sendo curadas e libertas. Foi um momento marcante na minha vida espiritual.',
  'Este é um registro de teste inserido manualmente para verificar se a tabela está funcionando corretamente.',
  NOW(),
  NOW()
);

-- 7. Verificar se os dados foram inseridos
SELECT 
  id,
  jovem_id,
  faz_nucleo,
  ha_quanto_tempo,
  media_pessoas,
  criado_em
FROM public.dados_nucleo 
WHERE jovem_id = 'e745720c-e9f7-4562-978b-72ba32387420'::uuid;
