# Instruções para Corrigir Problemas na Inserção de Dados de Viagem

## Problema Identificado

O problema na inserção de dados do formulário de comprovantes na tabela `dados_viagem` está relacionado a:

1. **Políticas RLS incorretas ou ausentes**
2. **Função `can_access_jovem` não existe ou não funciona**
3. **Campo `usuario_id` não sendo preenchido automaticamente**
4. **Falta de trigger para definir `usuario_id`**

## Solução

### Passo 1: Executar Script SQL de Correção

1. Acesse o **Supabase Dashboard**
2. Vá para **SQL Editor**
3. Execute o arquivo `diagnostico-viagem.sql` que foi criado

Este script irá:
- ✅ Verificar se a tabela `dados_viagem` existe
- ✅ Criar a função `can_access_jovem` se não existir
- ✅ Criar trigger para preencher `usuario_id` automaticamente
- ✅ Corrigir todas as políticas RLS
- ✅ Verificar se tudo foi configurado corretamente

### Passo 2: Verificar Configurações

Após executar o script, verifique se:

1. **Tabela existe**: A tabela `dados_viagem` deve existir com a estrutura correta
2. **RLS habilitado**: Row Level Security deve estar habilitado
3. **Políticas criadas**: 4 políticas devem estar ativas (SELECT, INSERT, UPDATE, DELETE)
4. **Função criada**: A função `can_access_jovem` deve existir
5. **Trigger criado**: O trigger `trigger_set_usuario_id_dados_viagem` deve existir

### Passo 3: Testar a Funcionalidade

1. Acesse a página de viagem: `http://10.101.172.167:5173/viagem`
2. Tente fazer upload de um comprovante
3. Verifique se os dados são inseridos corretamente

## Código JavaScript Corrigido

O arquivo `src/lib/stores/viagem.js` foi atualizado para:

- ✅ Buscar o usuário atual corretamente
- ✅ Preencher o campo `usuario_id` em todas as operações
- ✅ Adicionar logs de erro mais detalhados
- ✅ Verificar autenticação antes de inserir dados

## Estrutura da Tabela `dados_viagem`

A tabela deve ter a seguinte estrutura:

```sql
CREATE TABLE public.dados_viagem (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  jovem_id uuid NOT NULL REFERENCES public.jovens(id),
  edicao_id uuid NOT NULL REFERENCES public.edicoes(id),
  pagou_despesas boolean DEFAULT false,
  comprovante_pagamento text,
  data_passagem_ida timestamptz,
  comprovante_passagem_ida text,
  data_passagem_volta timestamptz,
  comprovante_passagem_volta text,
  data_cadastro timestamptz DEFAULT now(),
  atualizado_em timestamptz DEFAULT now(),
  usuario_id uuid REFERENCES public.usuarios(id),
  UNIQUE(jovem_id, edicao_id)
);
```

## Políticas RLS Aplicadas

As políticas permitem:

- **SELECT**: Usuários podem ver dados de jovens que têm acesso via `can_access_jovem()` ou são o próprio jovem
- **INSERT**: Usuários podem inserir dados para jovens que têm acesso via `can_access_jovem()` ou são o próprio jovem
- **UPDATE**: Usuários podem atualizar dados de jovens que têm acesso via `can_access_jovem()` ou são o próprio jovem
- **DELETE**: Apenas administradores podem deletar registros

## Função `can_access_jovem`

Esta função verifica se o usuário atual tem permissão para acessar um jovem específico baseado em:

- **Administradores e Colaboradores**: Acesso total
- **Líderes**: Acesso baseado no escopo (estadual, bloco, regional, igreja)

## Troubleshooting

Se ainda houver problemas:

1. **Verifique os logs do console** do navegador para erros específicos
2. **Verifique os logs do Supabase** para erros de RLS
3. **Teste a função `can_access_jovem`** diretamente no SQL Editor
4. **Verifique se o usuário tem as roles corretas** na tabela `user_roles`

## Comandos de Verificação

Execute estes comandos no SQL Editor para verificar se tudo está funcionando:

```sql
-- Verificar políticas
SELECT policyname, cmd FROM pg_policies WHERE tablename = 'dados_viagem';

-- Verificar função
SELECT proname FROM pg_proc WHERE proname = 'can_access_jovem';

-- Verificar trigger
SELECT tgname FROM pg_trigger WHERE tgrelid = 'dados_viagem'::regclass;

-- Testar função (substitua os UUIDs pelos valores reais)
SELECT can_access_jovem('uuid_estado', 'uuid_bloco', 'uuid_regiao', 'uuid_igreja');
```

## Próximos Passos

Após executar o script de correção:

1. Teste o upload de comprovantes
2. Verifique se os dados aparecem corretamente na interface
3. Teste com diferentes tipos de usuários (admin, colaborador, líder, jovem)
4. Monitore os logs para identificar possíveis problemas

Se ainda houver problemas, verifique:
- Se o bucket 'viagens' existe no Supabase Storage
- Se as permissões do storage estão configuradas corretamente
- Se o usuário está autenticado corretamente
