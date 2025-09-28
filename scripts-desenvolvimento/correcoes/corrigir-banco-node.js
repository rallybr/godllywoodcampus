import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://obrnnclzuzbwdtqbktto.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9icm5uY2x6dXpid2R0cWJrdHRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc2NDM4MzUsImV4cCI6MjA3MzIxOTgzNX0.ttgsuMaebOKA0hNPlgtD4EO0htPSLl-n20ICnDDbfHg';

const supabase = createClient(supabaseUrl, supabaseKey);

async function corrigirBanco() {
  console.log('🔧 Iniciando correção do banco de dados...');
  
  try {
    // 1. Desabilitar RLS temporariamente
    console.log('\n1️⃣ Desabilitando RLS temporariamente...');
    
    const tabelas = ['jovens', 'estados', 'blocos', 'regioes', 'igrejas', 'usuarios', 'roles', 'user_roles', 'edicoes'];
    
    for (const tabela of tabelas) {
      try {
        const { error } = await supabase.rpc('disable_rls', { table_name: tabela });
        if (error) {
          console.log(`⚠️  Aviso ao desabilitar RLS na tabela ${tabela}:`, error.message);
        } else {
          console.log(`✅ RLS desabilitado na tabela ${tabela}`);
        }
      } catch (err) {
        console.log(`⚠️  Erro ao desabilitar RLS na tabela ${tabela}:`, err.message);
      }
    }
    
    // 2. Criar roles essenciais
    console.log('\n2️⃣ Criando roles essenciais...');
    
    const roles = [
      { id: '11111111-1111-1111-1111-111111111111', nome: 'Administrador', slug: 'administrador', nivel_hierarquico: 1, descricao: 'Acesso total ao sistema' },
      { id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', nome: 'Colaborador', slug: 'colaborador', nivel_hierarquico: 7, descricao: 'Colaborador do sistema' },
      { id: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', nome: 'Jovem', slug: 'jovem', nivel_hierarquico: 8, descricao: 'Jovem cadastrado' }
    ];
    
    for (const role of roles) {
      const { error } = await supabase
        .from('roles')
        .upsert(role, { onConflict: 'slug' });
      
      if (error) {
        console.log(`❌ Erro ao criar role ${role.nome}:`, error.message);
      } else {
        console.log(`✅ Role ${role.nome} criada/atualizada`);
      }
    }
    
    // 3. Criar usuário administrador
    console.log('\n3️⃣ Criando usuário administrador...');
    
    const adminUser = {
      id: 'f2b0d1aa-92b9-4eb7-aa27-0ff9865ffbde',
      nome: 'Bp. Roberto Guerra - Admin',
      email: 'roberto@admin.com',
      nivel: 'administrador',
      id_auth: '346d397f-1a05-4e17-8bed-f94274b78fe0',
      ativo: true
    };
    
    const { error: userError } = await supabase
      .from('usuarios')
      .upsert(adminUser, { onConflict: 'email' });
    
    if (userError) {
      console.log('❌ Erro ao criar usuário admin:', userError.message);
    } else {
      console.log('✅ Usuário administrador criado/atualizado');
    }
    
    // 4. Atribuir papel de administrador
    console.log('\n4️⃣ Atribuindo papel de administrador...');
    
    const userRole = {
      id: 'cccccccc-cccc-cccc-cccc-cccccccccccc',
      user_id: 'f2b0d1aa-92b9-4eb7-aa27-0ff9865ffbde',
      role_id: '11111111-1111-1111-1111-111111111111',
      ativo: true
    };
    
    const { error: roleError } = await supabase
      .from('user_roles')
      .upsert(userRole, { onConflict: 'user_id,role_id' });
    
    if (roleError) {
      console.log('❌ Erro ao atribuir papel:', roleError.message);
    } else {
      console.log('✅ Papel de administrador atribuído');
    }
    
    // 5. Criar edições
    console.log('\n5️⃣ Criando edições...');
    
    const edicoes = [
      { id: 'dddddddd-dddd-dddd-dddd-dddddddddddd', nome: '1ª Edição IntelliMen Campus', numero: 1, data_inicio: '2024-01-01', data_fim: '2024-12-31', ativa: true },
      { id: 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', nome: '2ª Edição IntelliMen Campus', numero: 2, data_inicio: '2025-01-01', data_fim: '2025-12-31', ativa: true }
    ];
    
    for (const edicao of edicoes) {
      const { error } = await supabase
        .from('edicoes')
        .upsert(edicao, { onConflict: 'numero' });
      
      if (error) {
        console.log(`❌ Erro ao criar edição ${edicao.nome}:`, error.message);
      } else {
        console.log(`✅ Edição ${edicao.nome} criada/atualizada`);
      }
    }
    
    // 6. Extrair e inserir dados geográficos dos jovens existentes
    console.log('\n6️⃣ Extraindo dados geográficos dos jovens...');
    
    // Primeiro, vamos ver quantos jovens existem
    const { data: jovens, error: jovensError } = await supabase
      .from('jovens')
      .select('estado_id, bloco_id, regiao_id, igreja_id')
      .not('estado_id', 'is', null);
    
    if (jovensError) {
      console.log('❌ Erro ao buscar jovens:', jovensError.message);
    } else {
      console.log(`📊 Encontrados ${jovens.length} jovens com dados geográficos`);
      
      // Extrair estados únicos
      const estadosUnicos = [...new Set(jovens.map(j => j.estado_id).filter(Boolean))];
      console.log(`📊 Estados únicos encontrados: ${estadosUnicos.length}`);
      
      // Extrair blocos únicos
      const blocosUnicos = [...new Set(jovens.map(j => j.bloco_id).filter(Boolean))];
      console.log(`📊 Blocos únicos encontrados: ${blocosUnicos.length}`);
      
      // Extrair regiões únicas
      const regioesUnicas = [...new Set(jovens.map(j => j.regiao_id).filter(Boolean))];
      console.log(`📊 Regiões únicas encontradas: ${regioesUnicas.length}`);
      
      // Extrair igrejas únicas
      const igrejasUnicas = [...new Set(jovens.map(j => j.igreja_id).filter(Boolean))];
      console.log(`📊 Igrejas únicas encontradas: ${igrejasUnicas.length}`);
    }
    
    // 7. Reabilitar RLS
    console.log('\n7️⃣ Reabilitando RLS...');
    
    for (const tabela of tabelas) {
      try {
        const { error } = await supabase.rpc('enable_rls', { table_name: tabela });
        if (error) {
          console.log(`⚠️  Aviso ao reabilitar RLS na tabela ${tabela}:`, error.message);
        } else {
          console.log(`✅ RLS reabilitado na tabela ${tabela}`);
        }
      } catch (err) {
        console.log(`⚠️  Erro ao reabilitar RLS na tabela ${tabela}:`, err.message);
      }
    }
    
    // 8. Verificar resultado
    console.log('\n8️⃣ Verificando resultado...');
    
    const { data: contagem, error: contagemError } = await supabase
      .from('jovens')
      .select('*', { count: 'exact', head: true });
    
    if (contagemError) {
      console.log('❌ Erro ao verificar contagem:', contagemError.message);
    } else {
      console.log(`✅ Jovens no banco: ${contagem.length}`);
    }
    
    console.log('\n🎉 Correção do banco concluída!');
    
  } catch (error) {
    console.error('❌ Erro geral durante a correção:', error);
  }
}

corrigirBanco();
