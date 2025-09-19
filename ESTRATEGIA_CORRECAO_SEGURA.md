# Estratégia de Correção Segura - Políticas RLS da Tabela Jovens

## 🎯 **Objetivo**
Corrigir as políticas RLS da tabela `jovens` sem comprometer o funcionamento do sistema.

## 🔍 **Análise do Problema Atual**

### **Situação Identificada:**
- **13 políticas** na tabela `jovens` (deveria ter apenas 4)
- **Políticas duplicadas** com roles diferentes (`public` vs `authenticated`)
- **Políticas com comando "ALL"** que podem estar causando conflitos
- **Possível ausência** da função `can_access_jovem`

### **Funcionalidades que Dependem da Tabela Jovens:**
1. **Listagem de jovens** (`/jovens`)
2. **Perfil do jovem** (`/jovens/[id]`)
3. **Edição de jovens** (`/jovens/[id]/editar`) ✅ Criada
4. **Cadastro de jovens** (`/jovens/cadastrar`, `/jovens/cadastrar-simples`)
5. **Fichas de jovens** (`/jovens/[id]/ficha*`)
6. **Aprovação de jovens** (botões Aprovar/Pré-aprovar)
7. **Avaliações** (relacionadas aos jovens)

## 📋 **Plano de Ação Seguro**

### **Fase 1: Análise Completa** ✅
- [x] Criar script de análise completa (`analise-completa-sistema.sql`)
- [ ] Executar análise para entender o estado atual
- [ ] Identificar políticas problemáticas
- [ ] Verificar função `can_access_jovem`

### **Fase 2: Backup e Preparação**
- [ ] Fazer backup das políticas atuais
- [ ] Documentar todas as políticas existentes
- [ ] Testar funcionalidades críticas

### **Fase 3: Correção Gradual**
- [ ] Criar função `can_access_jovem` se não existir
- [ ] Remover políticas duplicadas
- [ ] Criar políticas limpas e organizadas
- [ ] Testar cada funcionalidade após cada alteração

### **Fase 4: Validação**
- [ ] Testar todas as funcionalidades
- [ ] Verificar permissões de diferentes tipos de usuário
- [ ] Validar que os botões funcionam corretamente

## 🛠️ **Scripts Criados**

### 1. **`analise-completa-sistema.sql`** ✅
- Análise completa do estado atual
- Verificação de políticas, roles, usuários
- Identificação de problemas

### 2. **`verificar-politicas-jovens.sql`** ✅
- Verificação básica das políticas
- Listagem das 13 políticas existentes

### 3. **`executar-correcao-jovens.sql`** ✅
- Script de correção (aguardando aprovação)
- Limpeza e recriação das políticas

## ⚠️ **Riscos Identificados**

### **Alto Risco:**
- **Políticas com role `public`**: Podem permitir acesso não autenticado
- **Políticas duplicadas**: Podem causar comportamentos inesperados
- **Função `can_access_jovem` ausente**: Pode quebrar verificações de permissão

### **Médio Risco:**
- **Políticas com comando "ALL"**: Podem sobrescrever políticas específicas
- **Mistura de roles**: `public` e `authenticated` podem conflitar

### **Baixo Risco:**
- **Página de edição**: Já foi criada e testada
- **Funções do store**: Já estão implementadas

## 🔒 **Medidas de Segurança**

### **Antes de Qualquer Alteração:**
1. **Executar análise completa** para entender o estado atual
2. **Fazer backup** das políticas existentes
3. **Testar funcionalidades críticas** no estado atual
4. **Documentar** todas as políticas existentes

### **Durante a Correção:**
1. **Alterações graduais** - uma política por vez
2. **Teste após cada alteração**
3. **Rollback imediato** se algo quebrar
4. **Logs detalhados** de todas as alterações

### **Após a Correção:**
1. **Teste completo** de todas as funcionalidades
2. **Validação** com diferentes tipos de usuário
3. **Monitoramento** por alguns dias
4. **Documentação** das alterações realizadas

## 📊 **Próximos Passos**

### **Imediato:**
1. **Execute o script `analise-completa-sistema.sql`**
2. **Analise os resultados** para entender o estado atual
3. **Identifique** quais políticas são problemáticas

### **Após Análise:**
1. **Decida** se quer prosseguir com a correção
2. **Aprove** o plano de correção
3. **Execute** as correções de forma gradual

## 🎯 **Resultado Esperado**

### **Estado Final:**
- **4 políticas limpas** na tabela `jovens`
- **Função `can_access_jovem`** funcionando
- **Botões Aprovar/Pré-aprovar/Editar** funcionando
- **Todas as funcionalidades** mantidas
- **Segurança** aprimorada

### **Políticas Finais:**
1. `jovens_select_scoped` - SELECT para authenticated
2. `jovens_insert_self_or_admin` - INSERT para authenticated  
3. `jovens_update_scoped_roles` - UPDATE para authenticated
4. `jovens_delete_admin` - DELETE apenas para administradores

---

**Status**: ✅ Análise preparada, aguardando execução
**Próximo**: Executar `analise-completa-sistema.sql` para entender o estado atual
