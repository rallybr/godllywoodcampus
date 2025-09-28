# Análise do Problema com Inserção de Regiões

## 🔍 **Problema Identificado**
O usuário consegue inserir as duas primeiras regiões ("Catedral" e "Luizote"), mas falha ao tentar inserir a terceira região.

## 🧐 **Possíveis Causas**

### **1. Problema de Cache/Estado**
```javascript
// Linha 184-190: Função criarRegiao()
async function criarRegiao() {
  if (!blocoId || !novaRegiao.nome) return;
  const { error } = await supabase.from('regioes').insert([{ nome: novaRegiao.nome, bloco_id: blocoId }]);
  if (error) { alert(error.message); return; }
  novaRegiao = { nome: '' };
  await carregarListas();
}
```

**Possível problema**: O `carregarListas()` pode estar causando conflito de estado.

### **2. Problema de Policies RLS**
- As policies de `regioes` podem ter restrições específicas
- Pode haver limite de inserções por usuário/sessão
- Problema de permissão hierárquica

### **3. Problema de Validação de Dados**
- Nome duplicado (mesmo que não seja único no banco)
- Caracteres especiais no nome
- Tamanho do campo

### **4. Problema de Estado da Interface**
- Campo `novaRegiao.nome` não está sendo limpo corretamente
- `blocoId` pode estar sendo perdido
- Estado da interface corrompido

## 🔧 **Soluções Propostas**

### **Solução 1: Debug da Função**
```javascript
async function criarRegiao() {
  console.log('Debug - blocoId:', blocoId);
  console.log('Debug - novaRegiao:', novaRegiao);
  
  if (!blocoId || !novaRegiao.nome) {
    console.log('Debug - Validação falhou');
    return;
  }
  
  console.log('Debug - Tentando inserir:', { nome: novaRegiao.nome, bloco_id: blocoId });
  
  const { data, error } = await supabase.from('regioes').insert([{ nome: novaRegiao.nome, bloco_id: blocoId }]);
  
  if (error) { 
    console.error('Debug - Erro:', error);
    alert(`Erro: ${error.message}`);
    return; 
  }
  
  console.log('Debug - Sucesso:', data);
  novaRegiao = { nome: '' };
  await carregarListas();
}
```

### **Solução 2: Verificar Policies RLS**
```sql
-- Verificar se as policies estão funcionando
SELECT * FROM pg_policies WHERE tablename = 'regioes';
```

### **Solução 3: Limpar Estado Completamente**
```javascript
async function criarRegiao() {
  if (!blocoId || !novaRegiao.nome) return;
  
  const { error } = await supabase.from('regioes').insert([{ nome: novaRegiao.nome, bloco_id: blocoId }]);
  if (error) { 
    alert(`Erro: ${error.message}`);
    return; 
  }
  
  // Limpar estado
  novaRegiao = { nome: '' };
  
  // Recarregar apenas regiões do bloco atual
  const { data, error: loadError } = await supabase
    .from('regioes')
    .select('*')
    .eq('bloco_id', blocoId)
    .order('nome');
    
  if (!loadError) {
    const normalizadas = (data || []).map(r => ({ ...r, id: String(r.id), bloco_id: String(r.bloco_id) }));
    regioes = [...regioes.filter(r => String(r.bloco_id) !== String(blocoId)), ...normalizadas];
  }
}
```

## 🎯 **Próximos Passos**

1. **Adicionar logs de debug** na função `criarRegiao()`
2. **Verificar policies RLS** da tabela `regioes`
3. **Testar inserção manual** via SQL
4. **Verificar estado da interface** durante a inserção
5. **Implementar solução de fallback** se necessário

## 📊 **Dados para Análise**

- **Regiões existentes**: "Catedral", "Luizote"
- **Bloco selecionado**: Uberlândia
- **Estado**: Minas Gerais
- **Erro**: Não especificado (precisa de debug)
