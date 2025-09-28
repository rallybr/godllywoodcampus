import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://obrnnclzuzbwdtqbktto.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9icm5uY2x6dXpid2R0cWJrdHRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc2NDM4MzUsImV4cCI6MjA3MzIxOTgzNX0.ttgsuMaebOKA0hNPlgtD4EO0htPSLl-n20ICnDDbfHg';

const supabase = createClient(supabaseUrl, supabaseKey);

async function corrigirProblemaColaborador() {
  console.log('🔧 CORRIGINDO PROBLEMA DO COLABORADOR');
  console.log('=' .repeat(50));
  
  try {
    // 1. Verificar níveis atuais
    console.log('\n1️⃣ VERIFICANDO NÍVEIS ATUAIS');
    console.log('-'.repeat(30));
    
    const { data: roles, error: rolesError } = await supabase
      .from('roles')
      .select('*')
      .order('nivel_hierarquico');
    
    if (rolesError) {
      console.log('❌ Erro ao buscar roles:', rolesError.message);
      return;
    }
    
    console.log('📊 Níveis atuais:');
    roles.forEach(role => {
      console.log(`   - ${role.nome} (${role.slug}): Nível ${role.nivel_hierarquico}`);
    });
    
    // 2. Corrigir níveis hierárquicos
    console.log('\n2️⃣ CORRIGINDO NÍVEIS HIERÁRQUICOS');
    console.log('-'.repeat(30));
    
    const correcoes = [
      { slug: 'administrador', nivel: 1 },
      { slug: 'lider_nacional_iurd', nivel: 2 },
      { slug: 'lider_nacional_fju', nivel: 2 },
      { slug: 'lider_estadual_iurd', nivel: 3 },
      { slug: 'lider_estadual_fju', nivel: 3 },
      { slug: 'lider_bloco_iurd', nivel: 4 },
      { slug: 'lider_bloco_fju', nivel: 4 },
      { slug: 'lider_regional_iurd', nivel: 5 },
      { slug: 'lider_igreja_iurd', nivel: 6 },
      { slug: 'colaborador', nivel: 7 },
      { slug: 'jovem', nivel: 8 }
    ];
    
    for (const correcao of correcoes) {
      try {
        const { error } = await supabase
          .from('roles')
          .update({ nivel_hierarquico: correcao.nivel })
          .eq('slug', correcao.slug);
        
        if (error) {
          console.log(`⚠️  Aviso ao corrigir ${correcao.slug}:`, error.message);
        } else {
          console.log(`✅ ${correcao.slug} corrigido para nível ${correcao.nivel}`);
        }
      } catch (err) {
        console.log(`❌ Erro ao corrigir ${correcao.slug}:`, err.message);
      }
    }
    
    // 3. Verificar resultado
    console.log('\n3️⃣ VERIFICANDO RESULTADO');
    console.log('-'.repeat(30));
    
    const { data: rolesCorrigidos, error: rolesCorrigidosError } = await supabase
      .from('roles')
      .select('*')
      .order('nivel_hierarquico');
    
    if (rolesCorrigidosError) {
      console.log('❌ Erro ao verificar roles corrigidos:', rolesCorrigidosError.message);
    } else {
      console.log('📊 Níveis corrigidos:');
      rolesCorrigidos.forEach(role => {
        console.log(`   - ${role.nome} (${role.slug}): Nível ${role.nivel_hierarquico}`);
      });
    }
    
    // 4. Verificar colaboradores específicos
    console.log('\n4️⃣ VERIFICANDO COLABORADORES');
    console.log('-'.repeat(30));
    
    const { data: colaboradores, error: colaboradoresError } = await supabase
      .from('usuarios')
      .select(`
        id, nome, email, nivel,
        user_roles!user_roles_user_id_fkey (
          *,
          roles (*)
        )
      `)
      .eq('nivel', 'colaborador');
    
    if (colaboradoresError) {
      console.log('❌ Erro ao buscar colaboradores:', colaboradoresError.message);
    } else {
      console.log(`📊 Colaboradores encontrados: ${colaboradores.length}`);
      colaboradores.forEach((colab, index) => {
        console.log(`\n${index + 1}. ${colab.nome} (${colab.email})`);
        console.log(`   Nível: ${colab.nivel}`);
        if (colab.user_roles?.length > 0) {
          colab.user_roles.forEach(role => {
            console.log(`   - Role: ${role.roles?.nome} (${role.roles?.slug})`);
            console.log(`   - Nível Hierárquico: ${role.roles?.nivel_hierarquico}`);
          });
        }
      });
    }
    
    console.log('\n🎉 CORREÇÃO CONCLUÍDA!');
    console.log('=' .repeat(50));
    
    console.log('\n💡 PRÓXIMOS PASSOS:');
    console.log('   1. Execute o script SQL no Supabase: corrigir-niveis-hierarquicos.sql');
    console.log('   2. Teste o sistema com um usuário colaborador');
    console.log('   3. Verifique se as restrições estão funcionando corretamente');
    
  } catch (error) {
    console.error('❌ Erro durante a correção:', error);
  }
}

corrigirProblemaColaborador();
