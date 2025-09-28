import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://obrnnclzuzbwdtqbktto.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9icm5uY2x6dXpid2R0cWJrdHRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc2NDM4MzUsImV4cCI6MjA3MzIxOTgzNX0.ttgsuMaebOKA0hNPlgtD4EO0htPSLl-n20ICnDDbfHg';

const supabase = createClient(supabaseUrl, supabaseKey);

async function popularDadosGeograficos() {
  console.log('🌍 Populando dados geográficos...');
  
  try {
    // 1. Verificar se há jovens no banco
    console.log('\n1️⃣ Verificando jovens existentes...');
    
    const { data: jovens, error: jovensError } = await supabase
      .from('jovens')
      .select('id, nome_completo, estado_id, bloco_id, regiao_id, igreja_id')
      .limit(10);
    
    if (jovensError) {
      console.log('❌ Erro ao buscar jovens:', jovensError.message);
      return;
    }
    
    console.log(`📊 Encontrados ${jovens.length} jovens`);
    
    if (jovens.length === 0) {
      console.log('⚠️  Nenhum jovem encontrado no banco');
      console.log('💡 Você precisa primeiro importar os dados dos jovens');
      return;
    }
    
    // 2. Extrair IDs únicos
    console.log('\n2️⃣ Extraindo IDs únicos...');
    
    const estadosUnicos = [...new Set(jovens.map(j => j.estado_id).filter(Boolean))];
    const blocosUnicos = [...new Set(jovens.map(j => j.bloco_id).filter(Boolean))];
    const regioesUnicas = [...new Set(jovens.map(j => j.regiao_id).filter(Boolean))];
    const igrejasUnicas = [...new Set(jovens.map(j => j.igreja_id).filter(Boolean))];
    
    console.log(`📊 Estados únicos: ${estadosUnicos.length}`);
    console.log(`📊 Blocos únicos: ${blocosUnicos.length}`);
    console.log(`📊 Regiões únicas: ${regioesUnicas.length}`);
    console.log(`📊 Igrejas únicas: ${igrejasUnicas.length}`);
    
    // 3. Criar dados geográficos básicos
    console.log('\n3️⃣ Criando dados geográficos básicos...');
    
    // Estados
    for (const estadoId of estadosUnicos) {
      try {
        const { error } = await supabase
          .from('estados')
          .upsert({
            id: estadoId,
            nome: `Estado ${estadoId}`,
            sigla: 'ST',
            bandeira: 'bandeira_default.png'
          }, { onConflict: 'id' });
        
        if (error) {
          console.log(`⚠️  Aviso ao criar estado ${estadoId}:`, error.message);
        } else {
          console.log(`✅ Estado ${estadoId} criado/atualizado`);
        }
      } catch (err) {
        console.log(`❌ Erro ao criar estado ${estadoId}:`, err.message);
      }
    }
    
    // Blocos
    for (const blocoId of blocosUnicos) {
      try {
        const { error } = await supabase
          .from('blocos')
          .upsert({
            id: blocoId,
            nome: `Bloco ${blocoId}`,
            estado_id: jovens.find(j => j.bloco_id === blocoId)?.estado_id
          }, { onConflict: 'id' });
        
        if (error) {
          console.log(`⚠️  Aviso ao criar bloco ${blocoId}:`, error.message);
        } else {
          console.log(`✅ Bloco ${blocoId} criado/atualizado`);
        }
      } catch (err) {
        console.log(`❌ Erro ao criar bloco ${blocoId}:`, err.message);
      }
    }
    
    // Regiões
    for (const regiaoId of regioesUnicas) {
      try {
        const { error } = await supabase
          .from('regioes')
          .upsert({
            id: regiaoId,
            nome: `Região ${regiaoId}`,
            bloco_id: jovens.find(j => j.regiao_id === regiaoId)?.bloco_id
          }, { onConflict: 'id' });
        
        if (error) {
          console.log(`⚠️  Aviso ao criar região ${regiaoId}:`, error.message);
        } else {
          console.log(`✅ Região ${regiaoId} criada/atualizada`);
        }
      } catch (err) {
        console.log(`❌ Erro ao criar região ${regiaoId}:`, err.message);
      }
    }
    
    // Igrejas
    for (const igrejaId of igrejasUnicas) {
      try {
        const { error } = await supabase
          .from('igrejas')
          .upsert({
            id: igrejaId,
            nome: `Igreja ${igrejaId}`,
            endereco: 'Endereço não informado',
            regiao_id: jovens.find(j => j.igreja_id === igrejaId)?.regiao_id
          }, { onConflict: 'id' });
        
        if (error) {
          console.log(`⚠️  Aviso ao criar igreja ${igrejaId}:`, error.message);
        } else {
          console.log(`✅ Igreja ${igrejaId} criada/atualizada`);
        }
      } catch (err) {
        console.log(`❌ Erro ao criar igreja ${igrejaId}:`, err.message);
      }
    }
    
    // 4. Verificar resultado
    console.log('\n4️⃣ Verificando resultado...');
    
    const { data: contagemEstados, error: estadosError } = await supabase
      .from('estados')
      .select('*', { count: 'exact', head: true });
    
    const { data: contagemBlocos, error: blocosError } = await supabase
      .from('blocos')
      .select('*', { count: 'exact', head: true });
    
    const { data: contagemRegioes, error: regioesError } = await supabase
      .from('regioes')
      .select('*', { count: 'exact', head: true });
    
    const { data: contagemIgrejas, error: igrejasError } = await supabase
      .from('igrejas')
      .select('*', { count: 'exact', head: true });
    
    if (estadosError) console.log('❌ Erro ao contar estados:', estadosError.message);
    else console.log(`✅ Estados: ${contagemEstados.length} registros`);
    
    if (blocosError) console.log('❌ Erro ao contar blocos:', blocosError.message);
    else console.log(`✅ Blocos: ${contagemBlocos.length} registros`);
    
    if (regioesError) console.log('❌ Erro ao contar regiões:', regioesError.message);
    else console.log(`✅ Regiões: ${contagemRegioes.length} registros`);
    
    if (igrejasError) console.log('❌ Erro ao contar igrejas:', igrejasError.message);
    else console.log(`✅ Igrejas: ${contagemIgrejas.length} registros`);
    
    // 5. Testar consulta com joins
    console.log('\n5️⃣ Testando consulta com joins...');
    
    try {
      const { data: jovemCompleto, error: jovemError } = await supabase
        .from('jovens')
        .select(`
          id, nome_completo,
          estados!estado_id(id, nome, sigla),
          blocos!bloco_id(id, nome),
          regioes!regiao_id(id, nome),
          igrejas!igreja_id(id, nome, endereco)
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
    
    console.log('\n🎉 População de dados geográficos concluída!');
    
  } catch (error) {
    console.error('❌ Erro geral durante a população:', error);
  }
}

popularDadosGeograficos();
