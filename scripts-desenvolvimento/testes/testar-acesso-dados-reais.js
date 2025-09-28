import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://obrnnclzuzbwdtqbktto.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9icm5uY2x6dXpid2R0cWJrdHRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc2NDM4MzUsImV4cCI6MjA3MzIxOTgzNX0.ttgsuMaebOKA0hNPlgtD4EO0htPSLl-n20ICnDDbfHg';

const supabase = createClient(supabaseUrl, supabaseKey);

async function testarAcessoDadosReais() {
  try {
    console.log('🔍 Testando acesso aos dados reais existentes...');
    
    // 1. Verificar se conseguimos acessar os dados com RLS ativo
    console.log('\n📊 Testando acesso com RLS ativo:');
    const { data: jovensComRLS, error: errorComRLS } = await supabase
      .from('jovens')
      .select('id, nome_completo, estado_id, bloco_id, regiao_id, igreja_id')
      .limit(5);
    
    if (errorComRLS) {
      console.log('❌ Erro com RLS ativo:', errorComRLS.message);
      console.log('🔍 Isso confirma que o RLS está bloqueando o acesso aos dados');
    } else {
      console.log('✅ Acesso com RLS funcionando!');
      console.log('📊 Jovens encontrados:', jovensComRLS.length);
    }
    
    // 2. Testar autenticação
    console.log('\n🔐 Testando autenticação:');
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    
    if (authError) {
      console.log('❌ Erro de autenticação:', authError.message);
      console.log('🔍 Usuário não está autenticado - isso explica o problema!');
    } else if (user) {
      console.log('✅ Usuário autenticado:', user.email);
      console.log('🔍 ID do usuário:', user.id);
    } else {
      console.log('❌ Nenhum usuário autenticado');
      console.log('🔍 Isso explica por que o RLS está bloqueando o acesso!');
    }
    
    // 3. Testar função específica do jovem
    console.log('\n🎯 Testando jovem específico:');
    const jovemId = '0e1bc378-2cd2-476b-9551-d11d444bf499';
    
    try {
      const { data: jovem, error: errorJovem } = await supabase
        .from('jovens')
        .select(`
          *,
          estados!estado_id(id, nome, sigla, bandeira),
          blocos!bloco_id(id, nome),
          regioes!regiao_id(id, nome),
          igrejas!igreja_id(id, nome, endereco),
          edicoes!edicao_id(id, nome, numero)
        `)
        .eq('id', jovemId)
        .single();
      
      if (errorJovem) {
        console.log('❌ Erro ao buscar jovem específico:', errorJovem.message);
        console.log('🔍 Código do erro:', errorJovem.code);
      } else {
        console.log('✅ Jovem encontrado!');
        console.log('📊 Nome:', jovem.nome_completo);
        console.log('📊 Estado:', jovem.estados?.nome || 'Não informado');
        console.log('📊 Bloco:', jovem.blocos?.nome || 'Não informado');
        console.log('📊 Região:', jovem.regioes?.nome || 'Não informado');
        console.log('📊 Igreja:', jovem.igrejas?.nome || 'Não informado');
      }
    } catch (err) {
      console.log('❌ Erro geral na consulta do jovem:', err.message);
    }
    
    // 4. Verificar se as tabelas relacionadas existem
    console.log('\n📋 Verificando tabelas relacionadas:');
    const tabelas = ['estados', 'blocos', 'regioes', 'igrejas'];
    
    for (const tabela of tabelas) {
      try {
        const { count, error } = await supabase
          .from(tabela)
          .select('*', { count: 'exact', head: true });
        
        if (error) {
          console.log(`❌ Erro na tabela ${tabela}:`, error.message);
        } else {
          console.log(`✅ ${tabela}: ${count} registros`);
        }
      } catch (err) {
        console.log(`❌ Erro geral na tabela ${tabela}:`, err.message);
      }
    }
    
    console.log('\n🎉 Teste concluído!');
    console.log('\n💡 DIAGNÓSTICO:');
    console.log('Se você viu erros de RLS, o problema é que:');
    console.log('1. O usuário não está autenticado no frontend');
    console.log('2. As políticas RLS estão bloqueando o acesso');
    console.log('3. Precisa configurar as políticas corretamente');
    
  } catch (err) {
    console.error('❌ Erro geral:', err);
  }
}

testarAcessoDadosReais();
