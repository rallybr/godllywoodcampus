import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://obrnnclzuzbwdtqbktto.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9icm5uY2x6dXpid2R0cWJrdHRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc2NDM4MzUsImV4cCI6MjA3MzIxOTgzNX0.ttgsuMaebOKA0hNPlgtD4EO0htPSLl-n20ICnDDbfHg';

const supabase = createClient(supabaseUrl, supabaseKey);

async function corrigirBancoSimples() {
  console.log('🔧 Iniciando correção simples do banco de dados...');
  
  try {
    // 1. Verificar se conseguimos acessar os dados
    console.log('\n1️⃣ Verificando acesso aos dados...');
    
    const { data: jovens, error: jovensError } = await supabase
      .from('jovens')
      .select('id, nome_completo, estado_id, bloco_id, regiao_id, igreja_id')
      .limit(5);
    
    if (jovensError) {
      console.log('❌ Erro ao acessar jovens:', jovensError.message);
      console.log('🔍 Código do erro:', jovensError.code);
      
      if (jovensError.code === 'PGRST301') {
        console.log('💡 O erro indica que o RLS está bloqueando o acesso');
        console.log('💡 Vamos tentar uma abordagem diferente...');
      }
    } else {
      console.log(`✅ Acesso aos jovens funcionando! Encontrados: ${jovens.length}`);
      if (jovens.length > 0) {
        console.log('📊 Primeiro jovem:', jovens[0]);
      }
    }
    
    // 2. Verificar autenticação
    console.log('\n2️⃣ Verificando autenticação...');
    
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    
    if (authError) {
      console.log('❌ Erro de autenticação:', authError.message);
    } else if (user) {
      console.log('✅ Usuário autenticado:', user.email);
      console.log('🔍 ID do usuário:', user.id);
    } else {
      console.log('❌ Nenhum usuário autenticado');
      console.log('💡 Isso explica por que o RLS está bloqueando o acesso!');
    }
    
    // 3. Tentar acessar tabelas relacionadas
    console.log('\n3️⃣ Verificando tabelas relacionadas...');
    
    const tabelas = ['estados', 'blocos', 'regioes', 'igrejas', 'usuarios', 'roles', 'user_roles', 'edicoes'];
    
    for (const tabela of tabelas) {
      try {
        const { data, error } = await supabase
          .from(tabela)
          .select('*', { count: 'exact', head: true });
        
        if (error) {
          console.log(`❌ Erro na tabela ${tabela}:`, error.message);
          if (error.code === 'PGRST301') {
            console.log(`💡 RLS bloqueando acesso à tabela ${tabela}`);
          }
        } else {
          console.log(`✅ ${tabela}: ${data.length} registros`);
        }
      } catch (err) {
        console.log(`❌ Erro geral na tabela ${tabela}:`, err.message);
      }
    }
    
    // 4. Tentar criar dados básicos (se possível)
    console.log('\n4️⃣ Tentando criar dados básicos...');
    
    // Tentar criar um role
    try {
      const { error: roleError } = await supabase
        .from('roles')
        .insert({
          id: '11111111-1111-1111-1111-111111111111',
          nome: 'Administrador',
          slug: 'administrador',
          nivel_hierarquico: 1,
          descricao: 'Acesso total ao sistema'
        });
      
      if (roleError) {
        console.log('❌ Erro ao criar role:', roleError.message);
        if (roleError.code === 'PGRST301') {
          console.log('💡 RLS bloqueando criação de role');
        }
      } else {
        console.log('✅ Role criada com sucesso');
      }
    } catch (err) {
      console.log('❌ Erro geral ao criar role:', err.message);
    }
    
    // 5. Verificar se há dados existentes
    console.log('\n5️⃣ Verificando dados existentes...');
    
    try {
      const { data: contagem, error: contagemError } = await supabase
        .from('jovens')
        .select('*', { count: 'exact', head: true });
      
      if (contagemError) {
        console.log('❌ Erro ao verificar contagem:', contagemError.message);
      } else {
        console.log(`✅ Total de jovens no banco: ${contagem.length}`);
      }
    } catch (err) {
      console.log('❌ Erro geral ao verificar contagem:', err.message);
    }
    
    console.log('\n🎉 Verificação concluída!');
    console.log('\n💡 DIAGNÓSTICO:');
    console.log('Se você viu erros de RLS (PGRST301), o problema é que:');
    console.log('1. O RLS está ativo e bloqueando o acesso');
    console.log('2. Não há usuário autenticado');
    console.log('3. As políticas RLS não permitem acesso anônimo');
    console.log('\n🔧 SOLUÇÕES POSSÍVEIS:');
    console.log('1. Desabilitar RLS temporariamente no painel do Supabase');
    console.log('2. Configurar políticas RLS que permitam acesso anônimo');
    console.log('3. Autenticar um usuário antes de acessar os dados');
    
  } catch (error) {
    console.error('❌ Erro geral durante a verificação:', error);
  }
}

corrigirBancoSimples();
