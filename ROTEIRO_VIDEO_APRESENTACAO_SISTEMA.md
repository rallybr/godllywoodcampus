# 🎬 Roteiro para Vídeo de Apresentação - IntelliMen Campus

## 📋 Informações Gerais

**Duração estimada:** 15-20 minutos  
**Público-alvo:** Líderes, pastores, colaboradores e jovens  
**Objetivo:** Demonstrar todas as funcionalidades do sistema de forma clara e prática  

---

## 🎯 Estrutura do Roteiro

### **1. Abertura e Introdução (2 minutos)**

#### **Cenário:** Tela inicial do sistema
- **Narração:** "Bem-vindos ao IntelliMen Campus, a plataforma completa para gestão e avaliação de jovens participantes dos acampamentos IntelliMen."
- **Demonstração:** 
  - Mostrar a tela de login
  - Fazer login com diferentes perfis (administrador, líder, jovem)
  - Destacar o design moderno e responsivo

#### **Pontos-chave:**
- Sistema web moderno e intuitivo
- Acesso via qualquer dispositivo (mobile-first)
- Segurança e controle de acesso por níveis hierárquicos

---

### **2. Sistema de Permissões e Níveis (3 minutos)**

#### **Cenário:** Dashboard principal
- **Narração:** "O sistema possui 8 níveis hierárquicos de acesso, cada um com permissões específicas."
- **Demonstração:**
  - Mostrar diferentes dashboards para cada nível
  - Explicar a hierarquia: Administrador → Líder Nacional → Líder Estadual → Líder de Bloco → Líder Regional → Líder de Igreja → Colaborador → Jovem

#### **Níveis detalhados:**
1. **Administrador:** Acesso total ao sistema
2. **Líder Nacional (IURD/FJU):** Visão nacional completa
3. **Líder Estadual:** Visão por estado
4. **Líder de Bloco:** Visão por bloco geográfico
5. **Líder Regional:** Visão por região
6. **Líder de Igreja:** Visão por igreja específica
7. **Colaborador:** Acesso aos dados que criou
8. **Jovem:** Acesso apenas aos próprios dados

---

### **3. Dashboard e Visão Geral (2 minutos)**

#### **Cenário:** Dashboard principal
- **Narração:** "O dashboard centraliza todas as informações importantes em tempo real."
- **Demonstração:**
  - Estatísticas gerais (total de jovens, avaliações pendentes, aprovados)
  - Gráficos de distribuição por estado e condição
  - Atividades recentes
  - Ações rápidas
  - Feed de jovens com filtros

#### **Elementos destacados:**
- Cards informativos com métricas
- Gráficos interativos
- Filtros por edição, estado, condição
- Interface responsiva

---

### **4. Cadastro de Jovens (3 minutos)**

#### **Cenário:** Formulário de cadastro
- **Narração:** "O cadastro de jovens é completo e intuitivo, com validações em tempo real."
- **Demonstração:**
  - Acessar `/jovens/cadastrar`
  - Preencher dados pessoais (nome, WhatsApp, data nascimento)
  - Upload e corte de foto de perfil
  - Dados profissionais e espirituais
  - Informações sobre experiência na igreja
  - Testemunho pessoal
  - Validação e salvamento

#### **Funcionalidades destacadas:**
- Upload de foto com corte automático
- Validação de dados em tempo real
- Interface multi-etapas
- Salvamento automático
- Integração com dados geográficos

---

### **5. Gestão de Jovens (3 minutos)**

#### **Cenário:** Listas e perfis de jovens
- **Narração:** "A gestão de jovens oferece múltiplas visualizações e filtros avançados."
- **Demonstração:**
  - Lista completa de jovens (`/jovens/todos`)
  - Filtros por estado, condição, idade, edição
  - Visualização em cards (`/jovens/cards`)
  - Perfil detalhado do jovem
  - Ficha completa com todas as informações
  - Edição de dados do jovem

#### **Funcionalidades destacadas:**
- Múltiplas visualizações (lista, cards, ficha)
- Filtros avançados e busca
- Perfil completo com foto
- Edição inline de informações
- Histórico de alterações

---

### **6. Sistema de Associações (2 minutos)**

#### **Cenário:** Perfil do jovem
- **Narração:** "O sistema permite duas formas de associação: relacionamento direto e acompanhamento múltiplo."
- **Demonstração:**
  - Mostrar campo `id_usuario_jovem` (relacionamento direto)
  - Demonstrar associação múltipla via botão "Associar"
  - Mostrar lista de usuários associados
  - Explicar diferença entre os dois tipos

#### **Funcionalidades destacadas:**
- Relacionamento direto jovem-usuário
- Associações múltiplas para avaliação
- Interface intuitiva para gerenciar associações
- Notificações automáticas

---

### **7. Sistema de Avaliações (3 minutos)**

#### **Cenário:** Módulo de avaliações
- **Narração:** "As avaliações são o coração do sistema, permitindo feedback estruturado dos líderes."
- **Demonstração:**
  - Acessar `/avaliacoes`
  - Selecionar jovem para avaliar
  - Preencher avaliação com notas e comentários
  - Avaliar disposição, caráter e espírito
  - Salvar e visualizar histórico de avaliações

#### **Funcionalidades destacadas:**
- Avaliação estruturada por critérios
- Notas numéricas e comentários
- Histórico completo de avaliações
- Média automática de notas
- Filtros por avaliador e período

---

### **8. Relatórios e Estatísticas (2 minutos)**

#### **Cenário:** Módulo de relatórios
- **Narração:** "Relatórios detalhados fornecem insights valiosos para tomada de decisão."
- **Demonstração:**
  - Acessar `/relatorios`
  - Mostrar relatórios de jovens por estado
  - Relatórios de avaliações
  - Estatísticas de aprovação
  - Exportação de dados

#### **Funcionalidades destacadas:**
- Relatórios por período e critério
- Gráficos e visualizações
- Exportação em múltiplos formatos
- Filtros personalizáveis
- Dashboards por nível hierárquico

---

### **9. Módulo de Viagens (1 minuto)**

#### **Cenário:** Gestão de viagens
- **Narração:** "O módulo de viagens controla despesas e comprovantes de cada edição."
- **Demonstração:**
  - Acessar `/viagem`
  - Mostrar cards de jovens com status de pagamento
  - Upload de comprovantes (passagem ida, volta, despesas)
  - Controle por edição

#### **Funcionalidades destacadas:**
- Controle de despesas por jovem
- Upload de comprovantes
- Organização por edição
- Interface visual intuitiva

---

### **10. Configurações e Perfil (1 minuto)**

#### **Cenário:** Configurações do usuário
- **Narração:** "Cada usuário pode personalizar seu perfil e configurações."
- **Demonstração:**
  - Acessar `/config`
  - Editar perfil pessoal
  - Configurar notificações
  - Alterar foto de perfil

#### **Funcionalidades destacadas:**
- Perfil personalizável
- Configurações de notificação
- Upload de foto
- Preferências do usuário

---

### **11. Segurança e Auditoria (1 minuto)**

#### **Cenário:** Módulo de segurança
- **Narração:** "O sistema possui auditoria completa e controles de segurança."
- **Demonstração:**
  - Acessar `/seguranca`
  - Mostrar logs de auditoria
  - Histórico de sessões
  - Controles de acesso

#### **Funcionalidades destacadas:**
- Logs completos de ações
- Controle de sessões
- Auditoria de alterações
- Segurança por níveis

---

### **12. Funcionalidades Mobile (1 minuto)**

#### **Cenário:** Acesso mobile
- **Narração:** "O sistema é totalmente responsivo e otimizado para dispositivos móveis."
- **Demonstração:**
  - Mostrar interface em smartphone
  - Navegação touch-friendly
  - Funcionalidades adaptadas para mobile
  - PWA (Progressive Web App)

#### **Funcionalidades destacadas:**
- Design responsivo
- Interface touch-optimized
- PWA para instalação
- Funcionalidades completas no mobile

---

### **13. Encerramento (1 minuto)**

#### **Cenário:** Dashboard principal
- **Narração:** "O IntelliMen Campus é uma solução completa para gestão de jovens, oferecendo controle total, segurança e facilidade de uso."
- **Demonstração:**
  - Mostrar resumo das funcionalidades
  - Destacar benefícios principais
  - Call-to-action para uso

#### **Pontos finais:**
- Sistema completo e integrado
- Segurança e controle de acesso
- Interface moderna e intuitiva
- Suporte completo para gestão de jovens

---

## 🎥 Dicas para Gravação

### **Preparação:**
1. **Dados de teste:** Prepare contas de usuário para cada nível hierárquico
2. **Dados de exemplo:** Cadastre jovens de exemplo com informações completas
3. **Cenários:** Prepare fluxos específicos para demonstrar cada funcionalidade
4. **Dispositivos:** Teste em desktop, tablet e mobile

### **Durante a gravação:**
1. **Ritmo:** Mantenha um ritmo constante, não muito rápido
2. **Clareza:** Explique cada ação antes de executá-la
3. **Destaque:** Use zoom ou destaque para elementos importantes
4. **Transições:** Faça transições suaves entre seções

### **Pós-produção:**
1. **Edição:** Adicione títulos e transições entre seções
2. **Legendas:** Considere adicionar legendas para acessibilidade
3. **Música:** Adicione música de fundo suave
4. **Thumbnail:** Crie thumbnail atrativo para o vídeo

---

## 📝 Checklist de Funcionalidades

### **✅ Funcionalidades Principais:**
- [ ] Sistema de login e autenticação
- [ ] Dashboard com estatísticas
- [ ] Cadastro completo de jovens
- [ ] Upload e corte de fotos
- [ ] Gestão de jovens (listas, filtros, perfis)
- [ ] Sistema de associações (simples e múltiplas)
- [ ] Avaliações estruturadas
- [ ] Relatórios e estatísticas
- [ ] Módulo de viagens
- [ ] Configurações de perfil
- [ ] Segurança e auditoria
- [ ] Interface responsiva/mobile

### **✅ Níveis de Acesso:**
- [ ] Administrador
- [ ] Líder Nacional (IURD/FJU)
- [ ] Líder Estadual
- [ ] Líder de Bloco
- [ ] Líder Regional
- [ ] Líder de Igreja
- [ ] Colaborador
- [ ] Jovem

### **✅ Recursos Técnicos:**
- [ ] Design moderno e responsivo
- [ ] PWA (Progressive Web App)
- [ ] Upload de arquivos
- [ ] Sistema de notificações
- [ ] Filtros avançados
- [ ] Busca em tempo real
- [ ] Exportação de dados
- [ ] Auditoria completa

---

## 🎯 Objetivos do Vídeo

1. **Demonstrar** todas as funcionalidades principais
2. **Explicar** o sistema de permissões hierárquicas
3. **Mostrar** a facilidade de uso e interface intuitiva
4. **Destacar** os benefícios para cada tipo de usuário
5. **Convencer** sobre a necessidade e utilidade do sistema

---

**Duração total estimada:** 15-20 minutos  
**Público:** Líderes, pastores, colaboradores e jovens  
**Formato:** Demonstração prática com narração explicativa
