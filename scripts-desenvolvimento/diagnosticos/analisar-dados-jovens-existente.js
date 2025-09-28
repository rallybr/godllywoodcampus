import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://obrnnclzuzbwdtqbktto.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9icm5uY2x6dXpid2R0cWJrdHRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc2NDM4MzUsImV4cCI6MjA3MzIxOTgzNX0.ttgsuMaebOKA0hNPlgtD4EO0htPSLl-n20ICnDDbfHg';

const supabase = createClient(supabaseUrl, supabaseKey);

async function analisarDadosJovensExistente() {
  try {
    console.log('🔍 Analisando dados existentes na tabela jovens...');
    
    // 1. Verificar contagem total de jovens
    console.log('\n📊 Contagem de registros:');
    const { count: totalJovens, error: errorJovens } = await supabase
      .from('jovens')
      .select('*', { count: 'exact', head: true });
    
    if (errorJovens) {
      console.error('❌ Erro ao contar jovens:', errorJovens);
    } else {
      console.log(`✅ Total de jovens: ${totalJovens}`);
    }
    
    // 2. Verificar dados geográficos
    console.log('\n🌍 Verificando dados geográficos:');
    const { data: geograficos, error: errorGeo } = await supabase
      .from('jovens')
      .select(`
        id, nome_completo, estado_id, bloco_id, regiao_id, igreja_id,
        estados!estado_id(id, nome, sigla),
        blocos!bloco_id(id, nome),
        regioes!regiao_id(id, nome),
        igrejas!igreja_id(id, nome)
      `)
      .limit(5);
    
    if (errorGeo) {
      console.error('❌ Erro ao buscar dados geográficos:', errorGeo);
    } else {
      console.log('✅ Dados geográficos dos primeiros 5 jovens:');
      geograficos.forEach((jovem, index) => {
        console.log(`\n${index + 1}. ${jovem.nome_completo}:`);
        console.log(`   Estado: ${jovem.estados?.nome || '❌ Não informado'} (ID: ${jovem.estado_id})`);
        console.log(`   Bloco: ${jovem.blocos?.nome || '❌ Não informado'} (ID: ${jovem.bloco_id})`);
        console.log(`   Região: ${jovem.regioes?.nome || '❌ Não informado'} (ID: ${jovem.regiao_id})`);
        console.log(`   Igreja: ${jovem.igrejas?.nome || '❌ Não informado'} (ID: ${jovem.igreja_id})`);
      });
    }
    
    // 3. Verificar se as tabelas relacionadas existem
    console.log('\n📋 Verificando tabelas relacionadas:');
    const tabelas = ['estados', 'blocos', 'regioes', 'igrejas'];
    
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
    
    // 4. Verificar se há jovens sem dados geográficos
    console.log('\n🔍 Verificando jovens sem dados geográficos:');
    const { data: semGeo, error: errorSemGeo } = await supabase
      .from('jovens')
      .select('id, nome_completo, estado_id, bloco_id, regiao_id, igreja_id')
      .or('estado_id.is.null,bloco_id.is.null,regiao_id.is.null,igreja_id.is.null')
      .limit(10);
    
    if (errorSemGeo) {
      console.error('❌ Erro ao buscar jovens sem dados geográficos:', errorSemGeo);
    } else {
      console.log(`✅ Jovens sem dados geográficos completos: ${semGeo.length}`);
      if (semGeo.length > 0) {
        console.log('Primeiros 3 exemplos:');
        semGeo.slice(0, 3).forEach((jovem, index) => {
          console.log(`${index + 1}. ${jovem.nome_completo}:`);
          console.log(`   Estado: ${jovem.estado_id ? '✅' : '❌'}`);
          console.log(`   Bloco: ${jovem.bloco_id ? '✅' : '❌'}`);
          console.log(`   Região: ${jovem.regiao_id ? '✅' : '❌'}`);
          console.log(`   Igreja: ${jovem.igreja_id ? '✅' : '❌'}`);
        });
      }
    }
    
    // 5. Testar consulta específica do jovem problemático
    console.log('\n🎯 Testando jovem específico (0e1bc378-2cd2-476b-9551-d11d444bf499):');
    const jovemId = '0e1bc378-2cd2-476b-9551-d11d444bf499';
    
    const { data: jovemEspecifico, error: errorEspecifico } = await supabase
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
    
    if (errorEspecifico) {
      console.error('❌ Erro ao buscar jovem específico:', errorEspecifico);
    } else {
      console.log('✅ Dados do jovem específico:');
      console.log(`Nome: ${jovemEspecifico.nome_completo}`);
      console.log(`Estado: ${jovemEspecifico.estados?.nome || '❌ Não informado'}`);
      console.log(`Bloco: ${jovemEspecifico.blocos?.nome || '❌ Não informado'}`);
      console.log(`Região: ${jovemEspecifico.regioes?.nome || '❌ Não informado'}`);
      console.log(`Igreja: ${jovemEspecifico.igrejas?.nome || '❌ Não informado'}`);
      console.log(`Edição: ${jovemEspecifico.edicoes?.nome || '❌ Não informado'}`);
    }
    
    console.log('\n🎉 Análise concluída!');
    
  } catch (err) {
    console.error('❌ Erro geral:', err);
  }
}

analisarDadosJovensExistente();
