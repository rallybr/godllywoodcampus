import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://obrnnclzuzbwdtqbktto.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9icm5uY2x6dXpid2R0cWJrdHRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc2NDM4MzUsImV4cCI6MjA3MzIxOTgzNX0.ttgsuMaebOKA0hNPlgtD4EO0htPSLl-n20ICnDDbfHg';

const supabase = createClient(supabaseUrl, supabaseKey);

async function testarCorrecao() {
  console.log('🧪 Testando correção do banco de dados...');
  
  try {
    // 1. Testar acesso aos jovens
    console.log('\n1️⃣ Testando acesso aos jovens...');
    const { data: jovens, error: jovensError } = await supabase
      .from('jovens')
      .select('id, nome_completo, estado_id, bloco_id, regiao_id, igreja_id')
      .limit(5);
    
    if (jovensError) {
      console.log('❌ Erro ao acessar jovens:', jovensError.message);
    } else {
      console.log(`✅ Acesso aos jovens funcionando! Encontrados: ${jovens.length}`);
      if (jovens.length > 0) {
        console.log('📊 Primeiro jovem:', jovens[0]);
      }
    }
    
    // 2. Testar acesso às tabelas relacionadas
    console.log('\n2️⃣ Testando acesso às tabelas relacionadas...');
    
    const tabelas = ['estados', 'blocos', 'regioes', 'igrejas', 'usuarios', 'roles', 'user_roles', 'edicoes'];
    
    for (const tabela of tabelas) {
      try {
        const { data, error } = await supabase
          .from(tabela)
          .select('*', { count: 'exact', head: true });
        
        if (error) {
          console.log(`❌ Erro na tabela ${tabela}:`, error.message);
        } else {
          console.log(`✅ ${tabela}: ${data.length} registros`);
        }
      } catch (err) {
        console.log(`❌ Erro geral na tabela ${tabela}:`, err.message);
      }
    }
    
    // 3. Testar consulta com joins
    console.log('\n3️⃣ Testando consulta com joins...');
    
    try {
      const { data: jovemCompleto, error: jovemError } = await supabase
        .from('jovens')
        .select(`
          id, nome_completo,
          estados!estado_id(id, nome, sigla),
          blocos!bloco_id(id, nome),
          regioes!regiao_id(id, nome),
          igrejas!igreja_id(id, nome, endereco),
          edicoes!edicao_id(id, nome, numero)
        `)
        .limit(1);
      
      if (jovemError) {
        console.log('❌ Erro na consulta com joins:', jovemError.message);
      } else {
        console.log('✅ Consulta com joins funcionando!');
        if (jovemCompleto.length > 0) {
          console.log('📊 Jovem com dados completos:', jovemCompleto[0]);
        }
      }
    } catch (err) {
      console.log('❌ Erro geral na consulta com joins:', err.message);
    }
    
    // 4. Testar autenticação
    console.log('\n4️⃣ Testando autenticação...');
    
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    
    if (authError) {
      console.log('❌ Erro de autenticação:', authError.message);
    } else if (user) {
      console.log('✅ Usuário autenticado:', user.email);
    } else {
      console.log('ℹ️  Nenhum usuário autenticado (normal para teste)');
    }
    
    console.log('\n🎉 Teste concluído!');
    
    if (jovensError && jovensError.code === 'PGRST301') {
      console.log('\n💡 DIAGNÓSTICO:');
      console.log('O RLS ainda está bloqueando o acesso. Execute o script SQL no painel do Supabase:');
      console.log('1. Acesse o painel do Supabase');
      console.log('2. Vá para SQL Editor');
      console.log('3. Execute o arquivo corrigir-banco-supabase.sql');
      console.log('4. Execute este teste novamente');
    } else {
      console.log('\n✅ SUCESSO!');
      console.log('O banco de dados foi corrigido e está funcionando!');
    }
    
  } catch (error) {
    console.error('❌ Erro geral durante o teste:', error);
  }
}

testarCorrecao();
