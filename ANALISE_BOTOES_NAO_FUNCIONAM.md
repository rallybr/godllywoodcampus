# Análise: Botões "Aprovar", "Pré-aprovar" e "Editar" Não Funcionam

## Problemas Identificados

### 1. **Página de Edição Não Existe**
- **Problema**: O botão "Editar" redireciona para `/jovens/[id]/editar`, mas esta rota não existe
- **Solução**: ✅ Criada a página `src/routes/jovens/[id]/editar/+page.svelte`

### 2. **Políticas RLS Podem Estar Incorretas**
- **Problema**: As políticas RLS para UPDATE na tabela `jovens` podem não estar funcionando corretamente
- **Política Atual**: `jovens_update_scoped_roles` - Admin/colab/líderes com escopo via `can_access_jovem(...)`
- **Solução**: ✅ Criado script `verificar-politicas-jovens.sql` para verificar e corrigir

### 3. **Função `can_access_jovem` Pode Não Existir**
- **Problema**: A função `can_access_jovem` pode não estar criada no banco de dados
- **Solução**: ✅ Incluída no script de verificação

## Estrutura da Tabela `jovens`

A tabela possui o campo `aprovado` que pode ter os valores:
- `null` ou vazio = "Pendente"
- `'pre_aprovado'` = "Pré-aprovado" 
- `'aprovado'` = "Aprovado"

## Políticas RLS Implementadas

### Para a Tabela `jovens`:

| Política | Comando | Aplicado a | Descrição |
|----------|---------|------------|-----------|
| `jovens_select_scoped` | SELECT | authenticated | O próprio jovem ou admin/colab/líderes com escopo |
| `jovens_insert_self_or_admin` | INSERT | authenticated | O jovem insere próprio cadastro ou admin/colab/líderes |
| `jovens_update_scoped_roles` | UPDATE | authenticated | O jovem atualiza próprio cadastro ou admin/colab/líderes |
| `jovens_delete_admin` | DELETE | authenticated | Apenas administradores |

## Função `can_access_jovem`

Esta função verifica se o usuário atual tem permissão para acessar um jovem específico:

```sql
can_access_jovem(jovem_estado_id, jovem_bloco_id, jovem_regiao_id, jovem_igreja_id)
```

**Permite acesso para:**
- **Administradores e Colaboradores**: Acesso total
- **Líderes**: Acesso baseado no escopo (estadual, bloco, regional, igreja)

## Soluções Implementadas

### 1. ✅ Página de Edição Criada
- **Arquivo**: `src/routes/jovens/[id]/editar/+page.svelte`
- **Funcionalidades**:
  - Carrega dados do jovem
  - Formulário completo com todos os campos
  - Validação e salvamento
  - Redirecionamento após sucesso

### 2. ✅ Script de Verificação de Políticas
- **Arquivo**: `verificar-politicas-jovens.sql`
- **Funcionalidades**:
  - Verifica se a tabela existe
  - Verifica se RLS está habilitado
  - Cria a função `can_access_jovem` se não existir
  - Corrige todas as políticas RLS
  - Inclui verificações e testes

### 3. ✅ Funções do Store Verificadas
- **Arquivo**: `src/lib/stores/jovens-simple.js`
- **Funções**:
  - `aprovarJovem(id, status)` - chama `updateJovem(id, { aprovado: status })`
  - `updateJovem(id, updates)` - atualiza o jovem no banco

## Como Resolver

### Passo 1: Executar Script SQL
1. Acesse o **Supabase Dashboard**
2. Vá para **SQL Editor**
3. Execute o arquivo `verificar-politicas-jovens.sql`

### Passo 2: Verificar Logs
1. Abra o **Console do Navegador** (F12)
2. Tente clicar nos botões "Aprovar", "Pré-aprovar" ou "Editar"
3. Verifique se há erros de JavaScript ou de rede

### Passo 3: Testar Funcionalidades
1. **Botão "Aprovar"**: Deve alterar `aprovado` para `'aprovado'`
2. **Botão "Pré-aprovar"**: Deve alterar `aprovado` para `'pre_aprovado'`
3. **Botão "Editar"**: Deve redirecionar para a página de edição

## Possíveis Causas Adicionais

### 1. **Usuário Sem Permissão**
- Verificar se o usuário tem role de `administrador`, `colaborador` ou líder
- Verificar se o escopo do líder corresponde ao jovem

### 2. **Erro de Rede**
- Verificar se o Supabase está acessível
- Verificar se as credenciais estão corretas

### 3. **Erro de JavaScript**
- Verificar console do navegador
- Verificar se as funções estão sendo chamadas corretamente

## Comandos de Verificação

Execute estes comandos no SQL Editor para verificar se tudo está funcionando:

```sql
-- Verificar políticas
SELECT policyname, cmd FROM pg_policies WHERE tablename = 'jovens';

-- Verificar função
SELECT proname FROM pg_proc WHERE proname = 'can_access_jovem';

-- Verificar usuário atual e suas roles
SELECT 
  u.id as usuario_id,
  u.nome,
  r.slug as role_slug,
  ur.ativo
FROM public.usuarios u
LEFT JOIN public.user_roles ur ON ur.user_id = u.id
LEFT JOIN public.roles r ON r.id = ur.role_id
WHERE u.id_auth = auth.uid();
```

## Próximos Passos

1. ✅ Executar o script de verificação
2. ✅ Testar os botões após a correção
3. ✅ Verificar logs para identificar problemas restantes
4. ✅ Documentar qualquer problema adicional encontrado

---

**Status**: ✅ Problemas identificados e soluções implementadas
**Data**: $(date)
**Sistema**: IntelliMen Campus
