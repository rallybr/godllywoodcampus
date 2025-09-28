# Hierarquia de Níveis e Permissões

## 🏆 **Hierarquia de Níveis (do maior para o menor privilégio)**

### 1. **Nível "administrador"**
- **Acesso**: Tudo
- **Descrição**: Acesso total ao sistema

### 2. **Níveis Nacionais (mesma permissão)**
- **Nível "lider_nacional_iurd"**
- **Nível "lider_nacional_fju"**
- **Acesso**: Visão nacional - todos os dados de todos os estados, blocos, regiões e igrejas do Brasil e todos os jovens

### 3. **Níveis Estaduais (mesma permissão)**
- **Nível "lider_estadual_iurd"**
- **Nível "lider_estadual_fju"**
- **Acesso**: Visão estadual - tudo de bloco, região e igreja e jovens relacionados

### 4. **Níveis de Bloco (mesma permissão)**
- **Nível "lider_bloco_iurd"**
- **Nível "lider_bloco_fju"**
- **Acesso**: Visão de bloco - região, igreja e jovens relacionados

### 5. **Nível Regional**
- **Nível "lider_regional_iurd"**
- **Acesso**: Visão regional - todas as igrejas ligadas à região e jovens relacionados

### 6. **Nível de Igreja**
- **Nível "lider_igreja_iurd"**
- **Acesso**: Visão de igreja - jovens relacionados à igreja

### 7. **Nível Colaborador**
- **Nível "colaborador"**
- **Acesso**: Tudo que ele mesmo criou, incluindo jovens que cadastrou e tudo relacionado a esses jovens

### 8. **Nível Jovem**
- **Nível "jovem"**
- **Acesso**: Seus próprios dados, perfil, card de viagem, cadastro

## 🔧 **Implementação Técnica**

### 1. **Mapeamento de Papéis para Níveis**
```javascript
const nivelMap = {
  'administrador': 'administrador',
  'lider_nacional_iurd': 'lider_nacional_iurd',
  'lider_nacional_fju': 'lider_nacional_fju',
  'lider_estadual_iurd': 'lider_estadual_iurd',
  'lider_estadual_fju': 'lider_estadual_fju',
  'lider_bloco_iurd': 'lider_bloco_iurd',
  'lider_bloco_fju': 'lider_bloco_fju',
  'lider_regional_iurd': 'lider_regional_iurd',
  'lider_igreja_iurd': 'lider_igreja_iurd',
  'colaborador': 'colaborador',
  'jovem': 'jovem'
};
```

### 2. **Sincronização Automática**
- O nível é sincronizado com o papel mais alto (menor nível hierárquico)
- Atualização automática quando papéis são carregados
- Atualização automática quando papéis são atribuídos/removidos

## 📋 **Regras de Negócio**

### 1. **Hierarquia de Permissões**
- **Administrador**: Acesso total
- **Líderes Nacionais**: Visão nacional
- **Líderes Estaduais**: Visão estadual
- **Líderes de Bloco**: Visão de bloco
- **Líder Regional**: Visão regional
- **Líder de Igreja**: Visão de igreja
- **Colaborador**: Visão do que criou
- **Jovem**: Visão própria

### 2. **Sincronização de Níveis**
- O nível é determinado pelo papel com maior privilégio
- Atualização automática quando papéis são alterados
- Correspondência direta entre papel e nível

## 🚀 **Funcionalidades**

### 1. **Sincronização Automática**
- Nível é atualizado quando papéis são carregados
- Nível é atualizado quando papéis são atribuídos
- Nível é atualizado quando papéis são removidos

### 2. **Mapeamento Correto**
- Cada papel corresponde ao seu nível correspondente
- Hierarquia respeitada na sincronização
- Fallback para 'colaborador' se papel não encontrado

## 📝 **Conclusão**

A hierarquia de níveis e permissões está corretamente implementada, com sincronização automática entre papéis e níveis, garantindo que o nível sempre corresponda ao papel com maior privilégio aplicado ao usuário.
