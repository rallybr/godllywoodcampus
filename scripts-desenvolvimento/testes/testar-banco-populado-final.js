import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://obrnnclzuzbwdtqbktto.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9icm5uY2x6dXpid2R0cWJrdHRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc2NDM4MzUsImV4cCI6MjA3MzIxOTgzNX0.ttgsuMaebOKA0hNPlgtD4EO0htPSLl-n20ICnDDbfHg';

const supabase = createClient(supabaseUrl, supabaseKey);

async function testarBancoPopuladoFinal() {
  try {
    console.log('🔍 Testando banco após popular dados...');
    
    // 1. Verificar contagem de registros
    console.log('\n📊 Contagem de registros:');
    const tabelas = ['jovens', 'estados', 'blocos', 'regioes', 'igrejas', 'usuarios', 'roles', 'edicoes'];
    
    for (const tabela of tabelas) {
      const { count, error } = await supabase
        .from(tabela)
        .select('*', { count: 'exact', head: true });
      
      if (error) {
        console.error(`❌ Erro na tabela ${tabela}:`, error.message);
      } else {
        console.log(`✅ ${tabela}: ${count} registros`);
      }
    }
    
    // 2. Testar consulta específica do jovem (como no frontend)
    console.log('\n🔍 Testando consulta do jovem específico:');
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
        console.error('❌ Erro na consulta do jovem:', errorJovem);
      } else {
        console.log('✅ Consulta do jovem funcionando!');
        console.log('📊 Dados do jovem:');
        console.log('Nome:', jovem.nome_completo);
        console.log('Estado:', jovem.estados?.nome || 'Não informado');
        console.log('Bloco:', jovem.blocos?.nome || 'Não informado');
        console.log('Região:', jovem.regioes?.nome || 'Não informado');
        console.log('Igreja:', jovem.igrejas?.nome || 'Não informado');
        console.log('Edição:', jovem.edicoes?.nome || 'Não informado');
        
        // Verificar se os dados geográficos estão corretos
        if (jovem.estados?.nome && jovem.blocos?.nome && jovem.regioes?.nome && jovem.igrejas?.nome) {
          console.log('\n🎉 SUCESSO! Todos os dados geográficos estão aparecendo!');
          console.log('✅ Estado:', jovem.estados.nome);
          console.log('✅ Bloco:', jovem.blocos.nome);
          console.log('✅ Região:', jovem.regioes.nome);
          console.log('✅ Igreja:', jovem.igrejas.nome);
        } else {
          console.log('\n⚠️ ATENÇÃO: Alguns dados geográficos ainda não estão aparecendo');
          console.log('Estado:', jovem.estados?.nome || '❌ Não informado');
          console.log('Bloco:', jovem.blocos?.nome || '❌ Não informado');
          console.log('Região:', jovem.regioes?.nome || '❌ Não informado');
          console.log('Igreja:', jovem.igrejas?.nome || '❌ Não informado');
        }
      }
    } catch (err) {
      console.error('❌ Erro geral na consulta do jovem:', err);
    }
    
    // 3. Testar função RPC (se disponível)
    console.log('\n🔍 Testando função RPC:');
    try {
      const { data: rpcData, error: rpcError } = await supabase.rpc('get_jovem_completo', {
        p_jovem_id: jovemId
      });
      
      if (rpcError) {
        console.log('⚠️ Função RPC:', rpcError.message);
      } else {
        console.log('✅ Função RPC funcionando!');
        console.log('📊 Dados RPC:', JSON.stringify(rpcData, null, 2));
      }
    } catch (err) {
      console.log('⚠️ Função RPC não disponível:', err.message);
    }
    
    console.log('\n🎉 Teste concluído!');
    console.log('🔗 Acesse: http://10.144.58.15:5173/jovens/0e1bc378-2cd2-476b-9551-d11d444bf499');
    
  } catch (err) {
    console.error('❌ Erro geral:', err);
  }
}

testarBancoPopuladoFinal();
