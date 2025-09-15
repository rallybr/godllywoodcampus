# 🔧 CONFIGURAÇÃO DO SUPABASE

## ⚠️ PROBLEMA IDENTIFICADO

O sistema não consegue carregar os blocos porque as variáveis de ambiente do Supabase não estão configuradas.

## 📋 DADOS CONFIRMADOS NO BANCO

✅ **Estado:** São Paulo (1 bloco)  
✅ **Bloco:** 1 bloco cadastrado  
✅ **Região:** 1 região cadastrada  
✅ **Igreja:** 1 igreja cadastrada  

## 🛠️ SOLUÇÃO

### 1. Acesse o Supabase Dashboard
- Vá para: https://supabase.com/dashboard
- Faça login na sua conta
- Selecione seu projeto

### 2. Obtenha as Credenciais
- Vá em **Settings** > **API**
- Copie:
  - **Project URL** (exemplo: `https://abcdefghijklmnop.supabase.co`)
  - **anon public** key (exemplo: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`)

### 3. Configure o Arquivo .env.local
Crie um arquivo chamado `.env.local` na raiz do projeto com:

```env
VITE_SUPABASE_URL=https://seu-projeto.supabase.co
VITE_SUPABASE_ANON_KEY=sua-chave-anonima-aqui
```

**Substitua pelos valores reais do seu projeto!**

### 4. Reinicie o Servidor
```bash
npm run dev
```

### 5. Teste o Sistema
- Acesse: http://localhost:5174/test-supabase
- Verifique se a conexão está funcionando
- Acesse: http://localhost:5174/jovens/cadastrar
- Teste a seleção de estado e carregamento de blocos

## 🔍 VERIFICAÇÃO

Após configurar, você deve ver no console do navegador:
- ✅ Supabase URL: https://seu-projeto.supabase.co
- ✅ Supabase Key: Presente

## 📞 SUPORTE

Se ainda houver problemas:
1. Verifique se as credenciais estão corretas
2. Verifique se o projeto Supabase está ativo
3. Verifique se as tabelas existem no banco de dados
4. Verifique o console do navegador para erros
