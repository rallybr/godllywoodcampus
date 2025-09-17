# Políticas RLS (Row Level Security) - Sistema IntelliMen Campus

## Visão Geral
Este documento contém todas as políticas RLS implementadas no sistema, organizadas por tabela e com suas respectivas permissões. Essas políticas controlam o acesso aos dados baseado em roles e autenticação.
Sempre que houver acrescimo de policy no banco de dados ou modificações de permissões, deve ser atualizado neste documento.

---

## 1. Tabela `avaliacoes`

| Nome da Política | Comando | Aplicado a | Descrição |
|------------------|---------|------------|-----------|
| `avaliacoes_select_authenticated` | SELECT | authenticated | Usuários autenticados, conforme RLS por escopo |
| `avaliacoes_insert_lider_colab` | INSERT | authenticated | Admin/colab/líderes podem inserir avaliações |
| `avaliacoes_update_owner_admin` | UPDATE | authenticated | Admin pode tudo; autor pode editar dentro da janela definida |
| `avaliacoes_delete_admin` | DELETE | authenticated | Apenas administradores |

---

## 2. Tabela `blocos`

| Nome da Política | Comando | Aplicado a | Descrição |
|------------------|---------|------------|-----------|
| `blocos_admin_modify` | ALL | public | Administradores podem modificar blocos |
| `blocos_select_all` | SELECT | public | Todos podem consultar blocos |

---

## 3. Tabela `configuracoes_sistema`

| Nome da Política | Comando | Aplicado a | Descrição |
|------------------|---------|------------|-----------|
| `configuracoes_admin_modify` | ALL | public | Administradores podem modificar configurações |
| `configuracoes_select_all` | SELECT | public | Todos podem consultar configurações |

---

## 4. Tabela `edicoes`

| Nome da Política | Comando | Aplicado a | Descrição |
|------------------|---------|------------|-----------|
| `edicoes_admin_modify` | ALL | public | Administradores podem modificar edições |
| `edicoes_select_all` | SELECT | public | Todos podem consultar edições |

---

## 5. Tabela `estados`

| Nome da Política | Comando | Aplicado a | Descrição |
|------------------|---------|------------|-----------|
| `estados_admin_modify` | ALL | public | Administradores podem modificar estados |
| `estados_select_all` | SELECT | public | Todos podem consultar estados |

---

## 6. Tabela `igrejas`

| Nome da Política | Comando | Aplicado a | Descrição |
|------------------|---------|------------|-----------|
| `igrejas_admin_modify` | ALL | public | Administradores podem modificar igrejas |
| `igrejas_select_all` | SELECT | public | Todos podem consultar igrejas |

---

## 7. Tabela `jovens`

| Nome da Política | Comando | Aplicado a | Descrição |
|------------------|---------|------------|-----------|
| `jovem pode inserir proprio cadastro` | INSERT | authenticated | Jovens autenticados podem inserir próprio cadastro |
| `jovem pode ver proprio cadastro` | SELECT | authenticated | Jovens autenticados podem ver próprio cadastro |
| `jovens_select_scoped` | SELECT | authenticated | Acesso por `can_access_jovem(...)` |
| `jovens_insert_self_or_admin` | INSERT | authenticated | Jovem insere próprio cadastro; admin/colab/líderes podem inserir |
| `jovens_update_scoped_roles` | UPDATE | authenticated | Admin/colab/líderes com escopo via `can_access_jovem(...)` |
| `jovens_delete_admin` | DELETE | authenticated | Apenas administradores |

---

## 8. Tabela `logs_auditoria`

| Nome da Política | Comando | Aplicado a | Descrição |
|------------------|---------|------------|-----------|
| `logs_auditoria_admin` | SELECT | public | Administradores podem consultar logs de auditoria |
| `logs_auditoria_system_insert` | INSERT | public | Sistema pode inserir logs de auditoria |

---

## 9. Tabela `logs_historico`

| Nome da Política | Comando | Aplicado a | Descrição |
|------------------|---------|------------|-----------|
| `logs_historico_admin_colab` | ALL | public | Administradores e colaboradores têm acesso total aos logs |
| `logs_historico_by_jovem_access` | SELECT | public | Acesso aos logs baseado no jovem |
| `logs_historico_system_insert` | INSERT | public | Sistema pode inserir logs históricos |

---

## 10. Tabela `notificacoes`

| Nome da Política | Comando | Aplicado a | Descrição |
|------------------|---------|------------|-----------|
| `notificacoes_self` | ALL | public | Usuários podem gerenciar próprias notificações |
| `notificacoes_system_insert` | INSERT | public | Sistema pode inserir notificações |

---

## 11. Tabela `regioes`

| Nome da Política | Comando | Aplicado a | Descrição |
|------------------|---------|------------|-----------|
| `regioes_admin_modify` | ALL | public | Administradores podem modificar regiões |
| `regioes_select_all` | SELECT | public | Todos podem consultar regiões |

---

## 12. Tabela `roles`

| Nome da Política | Comando | Aplicado a | Descrição |
|------------------|---------|------------|-----------|
| `roles_admin_modify` | ALL | public | Administradores podem modificar roles |
| `roles_select_all` | SELECT | public | Todos podem consultar roles |

---

## 13. Tabela `sessoes_usuario`

| Nome da Política | Comando | Aplicado a | Descrição |
|------------------|---------|------------|-----------|
| `sessoes_self` | ALL | public | Usuários podem gerenciar próprias sessões |
| `sessoes_system_insert` | INSERT | public | Sistema pode inserir sessões |

---

## 14. Tabela `user_roles`

| Nome da Política | Comando | Aplicado a | Descrição |
|------------------|---------|------------|-----------|
| `user_roles_select_authenticated` | SELECT | authenticated | Usuário vê seus roles; admin/colab veem todos |
| `user_roles_insert_admin` | INSERT | authenticated | Apenas administradores e colaboradores |
| `user_roles_update_admin` | UPDATE | authenticated | Apenas administradores e colaboradores |
| `user_roles_delete_admin` | DELETE | authenticated | Apenas administradores |

---

## 15. Tabela `usuarios`

| Nome da Política | Comando | Aplicado a | Descrição |
|------------------|---------|------------|-----------|
| `usuarios_select_authenticated` | SELECT | authenticated | Usuário vê próprio registro; admin/colab veem todos |
| `usuarios_insert_admin` | INSERT | authenticated | Apenas administradores |
| `usuarios_update_self_admin` | UPDATE | authenticated | Usuário atualiza campos próprios; admin pode tudo |
| `usuarios_delete_admin` | DELETE | authenticated | Apenas administradores |

---

## Resumo por Tipo de Acesso

### Acesso Total (ALL)
- **Administradores**: Todas as tabelas de configuração e dados
- **Colaboradores**: Tabelas de dados e logs
- **Líderes**: Tabela de jovens (com diferentes níveis)
- **Sistema**: Logs e notificações

### Acesso de Consulta (SELECT)
- **Público**: Tabelas de referência (estados, blocos, regiões, igrejas, edições, roles)
- **Autenticados**: Próprios dados (jovens, user_roles)

### Acesso de Inserção (INSERT)
- **Sistema**: Logs e notificações
- **Autenticados**: Próprios cadastros

### Acesso de Atualização (UPDATE)
- **Autenticados**: Conforme papel e escopo; nunca público

### Acesso de Exclusão (DELETE)
- **Apenas administradores**: usuários, user_roles, avaliações, jovens

---

## Notas Importantes

1. **RLS Habilitado**: Todas as tabelas mostradas têm RLS habilitado
2. **Role 'public'**: A maioria das políticas se aplica ao role 'public'
3. **Role 'authenticated'**: Usado para políticas específicas de usuários autenticados
4. **Políticas Duplicadas**: Algumas tabelas têm políticas tanto para 'public' quanto para 'authenticated'
5. **Sistema vs Usuário**: Políticas específicas para operações do sistema vs operações do usuário

---

## Recomendações para Manutenção

1. **Auditoria Regular**: Revisar políticas periodicamente
2. **Princípio do Menor Privilégio**: Aplicar apenas permissões necessárias
3. **Testes de Segurança**: Validar políticas antes de implementar em produção
4. **Documentação**: Manter este documento atualizado com mudanças
5. **Backup**: Fazer backup das políticas antes de modificações

---

*Documento gerado em: $(date)*
*Sistema: IntelliMen Campus*
*Versão: 1.0*
