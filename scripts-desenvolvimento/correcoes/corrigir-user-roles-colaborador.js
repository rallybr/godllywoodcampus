import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://obrnnclzuzbwdtqbktto.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9icm5uY2x6dXpid2R0cWJrdHRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc2NDM4MzUsImV4cCI6MjA3MzIxOTgzNX0.ttgsuMaebOKA0hNPlgtD4EO0htPSLl-n20ICnDDbfHg';

const supabase = createClient(supabaseUrl, supabaseKey);

async function corrigirUserRolesColaborador() {
  console.log('🔧 CORRIGINDO USER ROLES DO COLABORADOR');
  console.log('=' .repeat(50));
  
  try {
    // 1. Verificar colaborador específico
    console.log('\n1️⃣ VERIFICANDO COLABORADOR');
    console.log('-'.repeat(30));
    
    const { data: colaborador, error: colaboradorError } = await supabase
      .from('usuarios')
      .select(`
        id, nome, email, nivel,
        user_roles!user_roles_user_id_fkey (
          *,
          roles (*)
        )
      `)
      .eq('email', 'pedropaulobacana@hotmail.com')
      .single();
    
    if (colaboradorError) {
      console.log('❌ Erro ao buscar colaborador:', colaboradorError.message);
      return;
    }
    
    console.log('📊 Colaborador encontrado:');
    console.log(`   Nome: ${colaborador.nome}`);
    console.log(`   Email: ${colaborador.email}`);
    console.log(`   Nível: ${colaborador.nivel}`);
    console.log(`   ID: ${colaborador.id}`);
    console.log(`   User Roles atuais: ${colaborador.user_roles?.length || 0}`);
    
    // 2. Verificar se existe role de colaborador
    console.log('\n2️⃣ VERIFICANDO ROLE DE COLABORADOR');
    console.log('-'.repeat(30));
    
    const { data: roleColaborador, error: roleError } = await supabase
      .from('roles')
      .select('*')
      .eq('slug', 'colaborador')
      .single();
    
    if (roleError) {
      console.log('❌ Erro ao buscar role colaborador:', roleError.message);
      return;
    }
    
    console.log('📊 Role colaborador encontrado:');
    console.log(`   Nome: ${roleColaborador.nome}`);
    console.log(`   Slug: ${roleColaborador.slug}`);
    console.log(`   Nível Hierárquico: ${roleColaborador.nivel_hierarquico}`);
    console.log(`   ID: ${roleColaborador.id}`);
    
    // 3. Criar user_role para o colaborador
    console.log('\n3️⃣ CRIANDO USER ROLE PARA COLABORADOR');
    console.log('-'.repeat(30));
    
    const { data: userRole, error: userRoleError } = await supabase
      .from('user_roles')
      .insert({
        user_id: colaborador.id,
        role_id: roleColaborador.id,
        ativo: true,
        criado_em: new Date().toISOString()
      })
      .select()
      .single();
    
    if (userRoleError) {
      console.log('❌ Erro ao criar user_role:', userRoleError.message);
      
      // Se já existe, tentar atualizar
      if (userRoleError.code === '23505') {
        console.log('⚠️  User role já existe, tentando atualizar...');
        
        const { data: userRoleExistente, error: updateError } = await supabase
          .from('user_roles')
          .update({
            ativo: true,
            atualizado_em: new Date().toISOString()
          })
          .eq('user_id', colaborador.id)
          .eq('role_id', roleColaborador.id)
          .select()
          .single();
        
        if (updateError) {
          console.log('❌ Erro ao atualizar user_role:', updateError.message);
        } else {
          console.log('✅ User role atualizado com sucesso');
        }
      }
    } else {
      console.log('✅ User role criado com sucesso');
      console.log(`   ID: ${userRole.id}`);
      console.log(`   User ID: ${userRole.user_id}`);
      console.log(`   Role ID: ${userRole.role_id}`);
    }
    
    // 4. Verificar outros colaboradores sem user_roles
    console.log('\n4️⃣ VERIFICANDO OUTROS COLABORADORES');
    console.log('-'.repeat(30));
    
    const { data: todosColaboradores, error: todosColaboradoresError } = await supabase
      .from('usuarios')
      .select(`
        id, nome, email, nivel,
        user_roles!user_roles_user_id_fkey (
          *,
          roles (*)
        )
      `)
      .eq('nivel', 'colaborador');
    
    if (todosColaboradoresError) {
      console.log('❌ Erro ao buscar todos os colaboradores:', todosColaboradoresError.message);
    } else {
      console.log(`📊 Total de colaboradores: ${todosColaboradores.length}`);
      
      const colaboradoresSemRole = todosColaboradores.filter(colab => 
        !colab.user_roles || colab.user_roles.length === 0
      );
      
      console.log(`📊 Colaboradores sem user_roles: ${colaboradoresSemRole.length}`);
      
      if (colaboradoresSemRole.length > 0) {
        console.log('📊 Lista de colaboradores sem user_roles:');
        colaboradoresSemRole.forEach((colab, index) => {
          console.log(`   ${index + 1}. ${colab.nome} (${colab.email})`);
        });
        
        // Criar user_roles para todos os colaboradores sem role
        console.log('\n🔧 CRIANDO USER ROLES PARA TODOS OS COLABORADORES');
        console.log('-'.repeat(40));
        
        for (const colab of colaboradoresSemRole) {
          try {
            const { error: insertError } = await supabase
              .from('user_roles')
              .insert({
                user_id: colab.id,
                role_id: roleColaborador.id,
                ativo: true,
                criado_em: new Date().toISOString()
              });
            
            if (insertError) {
              console.log(`⚠️  Erro ao criar user_role para ${colab.nome}:`, insertError.message);
            } else {
              console.log(`✅ User role criado para ${colab.nome}`);
            }
          } catch (err) {
            console.log(`❌ Erro geral ao criar user_role para ${colab.nome}:`, err.message);
          }
        }
      }
    }
    
    // 5. Verificar resultado final
    console.log('\n5️⃣ VERIFICANDO RESULTADO FINAL');
    console.log('-'.repeat(30));
    
    const { data: colaboradorFinal, error: colaboradorFinalError } = await supabase
      .from('usuarios')
      .select(`
        id, nome, email, nivel,
        user_roles!user_roles_user_id_fkey (
          *,
          roles (*)
        )
      `)
      .eq('email', 'pedropaulobacana@hotmail.com')
      .single();
    
    if (colaboradorFinalError) {
      console.log('❌ Erro ao verificar colaborador final:', colaboradorFinalError.message);
    } else {
      console.log('📊 Colaborador após correção:');
      console.log(`   Nome: ${colaboradorFinal.nome}`);
      console.log(`   Email: ${colaboradorFinal.email}`);
      console.log(`   Nível: ${colaboradorFinal.nivel}`);
      console.log(`   User Roles: ${colaboradorFinal.user_roles?.length || 0}`);
      
      if (colaboradorFinal.user_roles?.length > 0) {
        colaboradorFinal.user_roles.forEach(role => {
          console.log(`   ✅ Role: ${role.roles?.nome} (${role.roles?.slug})`);
          console.log(`   ✅ Nível Hierárquico: ${role.roles?.nivel_hierarquico}`);
        });
      }
    }
    
    console.log('\n🎉 CORREÇÃO CONCLUÍDA!');
    console.log('=' .repeat(50));
    
    console.log('\n💡 PRÓXIMOS PASSOS:');
    console.log('   1. Teste o sistema com o usuário colaborador');
    console.log('   2. Verifique se as restrições estão funcionando');
    console.log('   3. Confirme que o problema foi resolvido');
    console.log('   4. Se necessário, limpe o cache do navegador');
    
  } catch (error) {
    console.error('❌ Erro durante a correção:', error);
  }
}

corrigirUserRolesColaborador();
