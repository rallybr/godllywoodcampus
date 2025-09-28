# Solução para Erro de Policies da Tabela Blocos

## 🚨 Problema Identificado

**Erro**: `403 (Forbidden)` ao tentar inserir um bloco
**Mensagem**: `new row violates row-level security policy for table "blocos"`
**URL**: `http://10.144.58.15:5173/administracao/gestao`

## 🔍 Análise do Problema

### **Causa Raiz**
A tabela `blocos` não possui **policies de INSERT** configuradas, apenas policies de SELECT. O Row Level Security (RLS) está bloqueando todas as tentativas de inserção.

### **Policies Existentes (Incompletas)**
```sql
-- Apenas esta policy existe:
CREATE POLICY "allow_read_all_blocos" ON blocos FOR r USING (true);
```

### **Policies Faltantes**
- ❌ **INSERT**: Não existe policy para inserção
- ❌ **UPDATE**: Não existe policy para atualização  
- ❌ **DELETE**: Não existe policy para exclusão

## ✅ Solução Implementada

### **1. Script de Correção das Policies**

Criei o arquivo `corrigir-policies-blocos.sql` com as policies corretas:

```sql
-- Policy para INSERT (inserção) - apenas administradores e líderes
CREATE POLICY "blocos_insert_admin" ON public.blocos
    FOR INSERT
    WITH CHECK (
        -- Administradores podem inserir
        EXISTS (
            SELECT 1 FROM public.usuarios u
            WHERE u.id_auth = auth.uid() 
            AND u.nivel = 'administrador'
        )
        OR
        -- Líderes nacionais podem inserir
        EXISTS (
            SELECT 1 FROM public.usuarios u
            WHERE u.id_auth = auth.uid() 
            AND u.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju')
        )
        OR
        -- Líderes estaduais podem inserir blocos do seu estado
        EXISTS (
            SELECT 1 FROM public.usuarios u
            WHERE u.id_auth = auth.uid() 
            AND u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju')
            AND u.estado_id = blocos.estado_id
        )
    );
```

### **2. Hierarquia de Permissões para Blocos**

| Nível | Permissão | Escopo |
|-------|-----------|--------|
| **Administrador** | ✅ Inserir/Atualizar/Excluir | Todos os blocos |
| **Líder Nacional** | ✅ Inserir/Atualizar/Excluir | Todos os blocos |
| **Líder Estadual** | ✅ Inserir/Atualizar | Blocos do seu estado |
| **Líder de Bloco** | ❌ Não pode gerenciar blocos | - |
| **Outros níveis** | ❌ Não pode gerenciar blocos | - |

### **3. Scripts Criados**

1. **`corrigir-policies-blocos.sql`** - Corrige apenas a tabela blocos
2. **`corrigir-policies-geograficas.sql`** - Corrige blocos, regiões e igrejas
3. **`testar-policies-blocos.sql`** - Testa se as policies estão funcionando
4. **`verificar-policies-blocos.sql`** - Verifica policies existentes

## 🚀 Como Aplicar a Solução

### **Passo 1: Executar o Script de Correção**
```sql
-- Execute no Supabase SQL Editor:
-- Arquivo: corrigir-policies-blocos.sql
```

### **Passo 2: Verificar se Funcionou**
```sql
-- Execute no Supabase SQL Editor:
-- Arquivo: testar-policies-blocos.sql
```

### **Passo 3: Testar no Frontend**
1. Acesse `http://10.144.58.15:5173/administracao/gestao`
2. Selecione um estado
3. Tente adicionar um bloco
4. Deve funcionar sem erro 403

## 🔧 Verificação de Permissões

### **Verificar Nível do Usuário**
```sql
SELECT 
    u.nome,
    u.nivel,
    u.estado_id,
    e.nome as estado_nome
FROM public.usuarios u
LEFT JOIN public.estados e ON e.id = u.estado_id
WHERE u.id_auth = auth.uid();
```

### **Testar Permissão de Inserção**
```sql
-- Este comando deve retornar 'true' se o usuário pode inserir blocos
SELECT EXISTS (
    SELECT 1 FROM public.usuarios u
    WHERE u.id_auth = auth.uid() 
    AND (
        u.nivel = 'administrador'
        OR u.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju')
        OR u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju')
    )
) as pode_inserir_blocos;
```

## 📋 Checklist de Verificação

- [ ] ✅ RLS habilitado na tabela blocos
- [ ] ✅ Policy de SELECT funcionando
- [ ] ✅ Policy de INSERT criada
- [ ] ✅ Policy de UPDATE criada
- [ ] ✅ Policy de DELETE criada
- [ ] ✅ Usuário tem nível adequado
- [ ] ✅ Teste de inserção funcionando
- [ ] ✅ Frontend funcionando sem erro 403

## 🎯 Resultado Esperado

Após aplicar a solução:

1. **✅ Inserção de Blocos**: Funcionará para administradores e líderes
2. **✅ Atualização de Blocos**: Funcionará para administradores e líderes
3. **✅ Exclusão de Blocos**: Funcionará apenas para administradores
4. **✅ Leitura de Blocos**: Continuará funcionando para todos
5. **✅ Erro 403**: Não aparecerá mais

## 🔄 Próximos Passos

1. **Aplicar a correção** executando o script SQL
2. **Testar no frontend** para confirmar que funciona
3. **Aplicar correção similar** para tabelas `regioes` e `igrejas` se necessário
4. **Documentar** as policies para futuras referências

## 📚 Arquivos Relacionados

- `corrigir-policies-blocos.sql` - Correção das policies
- `corrigir-policies-geograficas.sql` - Correção completa
- `testar-policies-blocos.sql` - Testes de verificação
- `verificar-policies-blocos.sql` - Verificação atual
- `SOLUCAO_ERRO_POLICIES_BLOCOS.md` - Este documento
