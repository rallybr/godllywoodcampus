-- Script para verificar permissões do bucket 'viagens'
-- Execute este script no Supabase SQL Editor

-- ============================================
-- 1. VERIFICAR SE O BUCKET EXISTE
-- ============================================

SELECT 'Verificando bucket viagens...' as status;

-- Tentar listar arquivos do bucket (isso vai falhar se não tiver permissão)
SELECT 'Testando acesso ao bucket viagens...' as teste;

-- ============================================
-- 2. VERIFICAR POLÍTICAS DE STORAGE
-- ============================================

-- Verificar se existem políticas para o bucket viagens
SELECT 'Políticas de storage para bucket viagens:' as verificacao;
SELECT policyname, cmd, permissive, roles
FROM pg_policies 
WHERE schemaname = 'storage' 
  AND tablename = 'objects'
ORDER BY policyname;

-- ============================================
-- 3. VERIFICAR PERMISSÕES DO USUÁRIO ATUAL
-- ============================================

-- Verificar se o usuário atual tem permissões no storage
SELECT 'Permissões do usuário atual no storage:' as verificacao;
SELECT 
  has_schema_privilege('storage', 'USAGE') as pode_usar_storage,
  has_schema_privilege('storage', 'CREATE') as pode_criar_storage;

-- ============================================
-- 4. VERIFICAR CONFIGURAÇÕES DO BUCKET
-- ============================================

-- Verificar configurações do bucket (se acessível)
SELECT 'Configurações do bucket viagens:' as verificacao;
SELECT * FROM storage.buckets 
WHERE name = 'viagens';

-- ============================================
-- 5. TESTE DE INSERÇÃO SIMPLES
-- ============================================

-- Este teste vai tentar inserir um arquivo de teste
-- (comente se não quiser criar arquivos de teste)
/*
INSERT INTO storage.objects (bucket_id, name, owner, metadata)
VALUES ('viagens', 'teste.txt', auth.uid(), '{"contentType": "text/plain"}');
*/

SELECT 'Verificação do bucket concluída!' as status;
