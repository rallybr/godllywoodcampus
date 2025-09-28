# Correção da Função com DROP

## 🔍 **Problema Identificado**

A função `buscar_usuarios_com_ultimo_acesso()` já existe com um tipo de retorno diferente, causando o erro:
```
ERROR: 42P13: cannot change return type of existing function
```

## 🔧 **Solução Implementada**

### 1. **Remover Função Existente e Criar Nova**
```sql
-- Execute no Supabase SQL Editor:
\i corrigir-funcao-foto-com-drop.sql
```

### 2. **Testar Função Corrigida**
```sql
-- Execute no Supabase SQL Editor:
\i testar-funcao-corrigida.sql
```

## 📋 **Scripts Criados**

1. **`corrigir-funcao-foto-com-drop.sql`** - Remove função existente e cria nova
2. **`testar-funcao-corrigida.sql`** - Testa se a função foi corrigida

## 🚀 **Próximos Passos**

### 1. **Executar Correção**
Execute o script `corrigir-funcao-foto-com-drop.sql` no Supabase SQL Editor.

### 2. **Testar Função**
Execute o script `testar-funcao-corrigida.sql` para verificar se a função está funcionando.

### 3. **Verificar Resultado**
Recarregue a página `/usuarios` e verifique se as fotos aparecem nos cards.

## ❓ **Questões para Resolver**

1. **A função foi removida e recriada corretamente?**
2. **A função está retornando a coluna `foto`?**
3. **As fotos aparecem nos cards após a correção?**
4. **Há erros JavaScript no console?**

## 📝 **Conclusão**

O problema era que a função já existia com um tipo de retorno diferente. Precisamos removê-la primeiro e depois criar a nova versão que inclui a coluna `foto`.

**Execute o script `corrigir-funcao-foto-com-drop.sql` e me informe o resultado!**
