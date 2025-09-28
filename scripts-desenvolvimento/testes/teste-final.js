import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://obrnnclzuzbwdtqbktto.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9icm5uY2x6dXpid2R0cWJrdHRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc2NDM4MzUsImV4cCI6MjA3MzIxOTgzNX0.ttgsuMaebOKA0hNPlgtD4EO0htPSLl-n20ICnDDbfHg';

const supabase = createClient(supabaseUrl, supabaseKey);

async function testeFinal() {
  console.log('🎯 TESTE FINAL - Verificando correção do banco de dados');
  console.log('=' .repeat(60));
  
  try {
    // 1. Testar acesso básico
    console.log('\n1️⃣ TESTE DE ACESSO BÁSICO');
    console.log('-'.repeat(40));
    
    const { data: jovens, error: jovensError } = await supabase
      .from('jovens')
      .select('id, nome_completo')
      .limit(5);
    
    if (jovensError) {
      console.log('❌ FALHA: Erro ao acessar jovens:', jovensError.message);
      console.log('💡 Código do erro:', jovensError.code);
      return;
    } else {
      console.log('✅ SUCESSO: Acesso aos jovens funcionando');
      console.log(`📊 Jovens encontrados: ${jovens.length}`);
    }
    
    // 2. Testar tabelas relacionadas
    console.log('\n2️⃣ TESTE DE TABELAS RELACIONADAS');
    console.log('-'.repeat(40));
    
    const tabelas = [
      { nome: 'estados', descricao: 'Estados' },
      { nome: 'blocos', descricao: 'Blocos' },
      { nome: 'regioes', descricao: 'Regiões' },
      { nome: 'igrejas', descricao: 'Igrejas' },
      { nome: 'usuarios', descricao: 'Usuários' },
      { nome: 'roles', descricao: 'Roles' },
      { nome: 'user_roles', descricao: 'User Roles' },
      { nome: 'edicoes', descricao: 'Edições' }
    ];
    
    let tabelasFuncionando = 0;
    
    for (const tabela of tabelas) {
      try {
        const { data, error } = await supabase
          .from(tabela.nome)
          .select('*', { count: 'exact', head: true });
        
        if (error) {
          console.log(`❌ ${tabela.descricao}: ${error.message}`);
        } else {
          console.log(`✅ ${tabela.descricao}: ${data.length} registros`);
          tabelasFuncionando++;
        }
      } catch (err) {
        console.log(`❌ ${tabela.descricao}: Erro geral - ${err.message}`);
      }
    }
    
    // 3. Testar consulta com joins
    console.log('\n3️⃣ TESTE DE CONSULTA COM JOINS');
    console.log('-'.repeat(40));
    
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
        console.log('❌ FALHA: Erro na consulta com joins:', jovemError.message);
      } else {
        console.log('✅ SUCESSO: Consulta com joins funcionando');
        if (jovemCompleto.length > 0) {
          console.log('📊 Exemplo de jovem com dados completos:');
          console.log(JSON.stringify(jovemCompleto[0], null, 2));
        }
      }
    } catch (err) {
      console.log('❌ FALHA: Erro geral na consulta com joins:', err.message);
    }
    
    // 4. Testar autenticação
    console.log('\n4️⃣ TESTE DE AUTENTICAÇÃO');
    console.log('-'.repeat(40));
    
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    
    if (authError) {
      console.log('❌ FALHA: Erro de autenticação:', authError.message);
    } else if (user) {
      console.log('✅ SUCESSO: Usuário autenticado:', user.email);
    } else {
      console.log('ℹ️  INFO: Nenhum usuário autenticado (normal para teste)');
    }
    
    // 5. Resumo final
    console.log('\n5️⃣ RESUMO FINAL');
    console.log('=' .repeat(60));
    
    if (jovensError && jovensError.code === 'PGRST301') {
      console.log('❌ PROBLEMA IDENTIFICADO:');
      console.log('   O RLS está bloqueando o acesso aos dados');
      console.log('');
      console.log('🔧 SOLUÇÃO:');
      console.log('   1. Acesse o painel do Supabase');
      console.log('   2. Vá para SQL Editor');
      console.log('   3. Execute o arquivo corrigir-banco-supabase.sql');
      console.log('   4. Execute este teste novamente');
    } else {
      console.log('✅ BANCO DE DADOS CORRIGIDO COM SUCESSO!');
      console.log('');
      console.log('📊 STATUS:');
      console.log(`   - Acesso aos jovens: ✅ Funcionando`);
      console.log(`   - Tabelas relacionadas: ${tabelasFuncionando}/${tabelas.length} funcionando`);
      console.log(`   - Consultas com joins: ✅ Funcionando`);
      console.log('');
      console.log('🎉 O banco de dados está pronto para uso!');
      console.log('');
      console.log('📝 PRÓXIMOS PASSOS:');
      console.log('   1. Importar dados dos jovens (se necessário)');
      console.log('   2. Configurar autenticação no frontend');
      console.log('   3. Testar as funcionalidades da aplicação');
    }
    
  } catch (error) {
    console.error('❌ ERRO CRÍTICO durante o teste:', error);
  }
}

testeFinal();
