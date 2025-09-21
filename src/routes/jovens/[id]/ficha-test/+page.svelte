<script>
  import { onMount } from 'svelte';
  import { page } from '$app/stores';
  import { goto } from '$app/navigation';
  import { format, parseISO } from 'date-fns';
  import { ptBR } from 'date-fns/locale';

  // @ts-ignore
  let jovem = null;
  let loading = true;
  // @ts-ignore
  let error = null;

  onMount(async () => {
    const jovemId = $page.params.id;
    console.log('=== TESTE DE CARREGAMENTO DA FICHA ===');
    console.log('ID do jovem:', jovemId);
    
    if (!jovemId) {
      error = 'ID do jovem não fornecido';
      loading = false;
      return;
    }

    try {
      const { supabase } = await import('$lib/utils/supabase');
      
      const { data, error: fetchError } = await supabase
        .from('jovens')
        .select(`
          *,
          estado:estados(nome, sigla),
          bloco:blocos(nome),
          regiao:regioes(nome),
          igreja:igrejas(nome),
          edicao_obj:edicoes(nome, numero)
        `)
        .eq('id', jovemId)
        .single();
      
      if (fetchError) {
        throw fetchError;
      }
      
      jovem = data;
    } catch (err) {
      console.error('Erro ao carregar ficha:', err);
      error = 'Erro ao carregar dados do jovem';
    } finally {
      loading = false;
    }
  });

  function voltar() {
    goto('/jovens');
  }

  // Função para formatar data
  function formatarData(data) {
    if (!data) return 'Não informado';
    try {
      return format(parseISO(data), 'dd/MM/yyyy', { locale: ptBR });
    } catch {
      return data;
    }
  }

  // @ts-ignore
  function calcularIdade(dataNascimento) {
    if (!dataNascimento) return 0;
    const hoje = new Date();
    const nascimento = new Date(dataNascimento);
    let idade = hoje.getFullYear() - nascimento.getFullYear();
    const mesAtual = hoje.getMonth();
    const mesNascimento = nascimento.getMonth();
    
    if (mesAtual < mesNascimento || (mesAtual === mesNascimento && hoje.getDate() < nascimento.getDate())) {
      idade--;
    }
    
    return idade;
  }
</script>


<svelte:head>
  <title>Ficha do Jovem - IntelliMen Campus</title>
</svelte:head>

<div class="min-h-screen bg-gray-50 py-8">
  <div class="max-w-7xl mx-auto px-4">
    {#if loading}
      <div class="flex items-center justify-center py-12">
        <div class="text-center">
          <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p class="text-gray-600">Carregando dados do jovem...</p>
        </div>
      </div>
    {/if}

    {#if error}
      <div class="bg-red-50 border border-red-200 rounded-lg p-6 text-center">
        <h3 class="text-lg font-semibold text-red-800 mb-2">Erro</h3>
        <!-- @ts-ignore -->
        <p class="text-red-600 mb-4">{error}</p>
        <button
          on:click={voltar}
          class="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
        >
          Voltar para Lista
        </button>
      </div>
    {/if}

    {#if jovem}
      <div class="bg-white rounded-xl shadow-lg overflow-hidden border border-gray-200 max-w-6xl mx-auto">
        <div class="bg-gradient-to-r from-blue-600 to-blue-500 text-white text-center p-6 relative">
          <h1 class="text-2xl font-semibold">{jovem.nome_completo}</h1>
          <p class="text-sm opacity-90">
            {jovem.estado?.nome || 'Estado não informado'} • 
            Cadastrado em {formatarData(jovem.data_cadastro)}
          </p>
        </div>

        <div class="p-8">
          <!-- Informações Pessoais com foto sobrepondo o header -->
          <div class="mb-8 relative">
            <!-- Foto posicionada sobre o header -->
            <div class="absolute -top-8 left-0 z-10">
              {#if jovem.foto}
                <img 
                  src={jovem.foto} 
                  alt={jovem.nome_completo}
                  class="w-30 h-40 object-cover object-top rounded-lg border border-gray-200 shadow-md bg-gray-100"
                />
              {:else}
                <div class="w-30 h-40 bg-gradient-to-br from-blue-500 to-blue-600 rounded-lg border border-gray-200 shadow-md flex items-center justify-center">
                  <span class="text-white font-bold text-2xl">
                    {jovem.nome_completo?.charAt(0) || 'J'}
                  </span>
                </div>
              {/if}
            </div>
            
            <!-- Dados pessoais em 2 colunas conforme o print -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mt-6 ml-52">
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">WHATSAPP</div>
                <div class="text-gray-800 text-base mt-1">{jovem.whatsapp || 'Não informado'}</div>
              </div>
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">ESTADO CIVIL</div>
                <div class="text-gray-800 text-base mt-1">{jovem.estado_civil || 'Não informado'}</div>
              </div>
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">DATA DE NASCIMENTO</div>
                <div class="text-gray-800 text-base mt-1">
                  {formatarData(jovem.data_nasc)}
                </div>
              </div>
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">IDADE</div>
                <div class="text-gray-800 text-base mt-1">{jovem.idade || calcularIdade(jovem.data_nasc) || 'Não informado'}</div>
              </div>
            </div>
            
            <!-- SEXO, NAMORA, TEM FILHO em 3 colunas -->
            <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mt-6 ml-52">
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">SEXO</div>
                <div class="text-gray-800 text-base mt-1">{jovem.sexo || 'Não informado'}</div>
              </div>
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">NAMORA</div>
                <div class="text-gray-800 text-base mt-1">{jovem.namora ? 'Sim' : 'Não'}</div>
              </div>
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">TEM FILHO</div>
                <div class="text-gray-800 text-base mt-1">{jovem.tem_filho ? 'Sim' : 'Não'}</div>
              </div>
            </div>
          </div>

          <div class="mt-10">
            <div class="flex items-center mb-4">
              <div class="w-1 h-6 bg-green-500 mr-3 rounded"></div>
              <h2 class="text-lg font-bold text-gray-800">Informações Profissionais</h2>
            </div>
            
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">TRABALHA</div>
                <div class="text-gray-800 text-base mt-1">{jovem.trabalha ? 'Sim' : 'Não'}</div>
              </div>
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">LOCAL DE TRABALHO</div>
                <div class="text-gray-800 text-base mt-1">{jovem.local_trabalho || 'Não informado'}</div>
              </div>
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">ESCOLARIDADE</div>
                <div class="text-gray-800 text-base mt-1">{jovem.escolaridade || 'Não informado'}</div>
              </div>
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">FORMAÇÃO</div>
                <div class="text-gray-800 text-base mt-1">{jovem.formacao || 'Não informado'}</div>
              </div>
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">TEM DÍVIDAS</div>
                <div class="text-gray-800 text-base mt-1">{jovem.tem_dividas ? 'Sim' : 'Não'}</div>
              </div>
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">VALOR DA DÍVIDA</div>
                <div class="text-gray-800 text-base mt-1">{jovem.valor_divida || 'Não informado'}</div>
              </div>
            </div>
          </div>

          <div class="mt-10">
            <div class="flex items-center mb-4">
              <div class="w-1 h-6 bg-red-500 mr-3 rounded"></div>
              <h2 class="text-lg font-bold text-gray-800">Informações Espirituais</h2>
            </div>
            
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">TEMPO DE IGREJA</div>
                <div class="text-gray-800 text-base mt-1">{jovem.tempo_igreja || 'Não informado'}</div>
              </div>
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">BATIZADO NAS ÁGUAS</div>
                <div class="text-gray-800 text-base mt-1">{jovem.batizado_aguas ? 'Sim' : 'Não'}</div>
              </div>
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">DATA DO BATISMO NAS ÁGUAS</div>
                <div class="text-gray-800 text-base mt-1">
                  {formatarData(jovem.data_batismo_aguas)}
                </div>
              </div>
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">BATIZADO COM O ES</div>
                <div class="text-gray-800 text-base mt-1">{jovem.batizado_es ? 'Sim' : 'Não'}</div>
              </div>
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">DATA DO BATISMO COM O ES</div>
                <div class="text-gray-800 text-base mt-1">
                  {formatarData(jovem.data_batismo_es)}
                </div>
              </div>
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">CONDIÇÃO</div>
                <div class="text-gray-800 text-base mt-1">{jovem.condicao || 'Não informado'}</div>
              </div>
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">TEMPO NESTA CONDIÇÃO</div>
                <div class="text-gray-800 text-base mt-1">{jovem.tempo_condicao || 'Não informado'}</div>
              </div>
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">RESPONSABILIDADE NA IGREJA</div>
                <div class="text-gray-800 text-base mt-1">{jovem.responsabilidade_igreja || 'Não informado'}</div>
              </div>
            </div>
          </div>

          <div class="mt-10">
            <div class="flex items-center mb-4">
              <div class="w-1 h-6 bg-red-500 mr-3 rounded"></div>
              <h2 class="text-lg font-bold text-gray-800">Experiência na Igreja</h2>
            </div>
            
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">JÁ FEZ A OBRA NO ALTAR</div>
                <div class="text-gray-800 text-base mt-1">{jovem.ja_obra_altar ? 'Sim' : 'Não'}</div>
              </div>
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">JÁ FOI OBREIRO</div>
                <div class="text-gray-800 text-base mt-1">{jovem.ja_obreiro ? 'Sim' : 'Não'}</div>
              </div>
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">JÁ FOI COLABORADOR</div>
                <div class="text-gray-800 text-base mt-1">{jovem.ja_colaborador ? 'Sim' : 'Não'}</div>
              </div>
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">JÁ SE AFASTOU ALGUMA VEZ</div>
                <div class="text-gray-800 text-base mt-1">{jovem.afastado ? 'Sim' : 'Não'}</div>
              </div>
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">DATA DO AFASTAMENTO</div>
                <div class="text-gray-800 text-base mt-1">
                  {formatarData(jovem.data_afastamento)}
                </div>
              </div>
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">MOTIVO DO AFASTAMENTO</div>
                <div class="text-gray-800 text-base mt-1">{jovem.motivo_afastamento || 'Não informado'}</div>
              </div>
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">DATA DO RETORNO</div>
                <div class="text-gray-800 text-base mt-1">
                  {formatarData(jovem.data_retorno)}
                </div>
              </div>
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">OS PAIS SÃO DA IGREJA</div>
                <div class="text-gray-800 text-base mt-1">{jovem.pais_na_igreja ? 'Sim' : 'Não'}</div>
              </div>
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">OBSERVAÇÃO SOBRE OS PAIS</div>
                <div class="text-gray-800 text-base mt-1">{jovem.observacao_pais || 'Não informado'}</div>
              </div>
            </div>
            
            <!-- Últimos 4 campos em 4 colunas -->
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mt-6">
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">TEM FAMILIARES NA IGREJA</div>
                <div class="text-gray-800 text-base mt-1">{jovem.familiares_igreja ? 'Sim' : 'Não'}</div>
              </div>
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">DESEJA O ALTAR</div>
                <div class="text-gray-800 text-base mt-1">{jovem.deseja_altar ? 'Sim' : 'Não'}</div>
              </div>
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">DISPONÍVEL PARA SERVIR</div>
                <div class="text-gray-800 text-base mt-1">{jovem.disposto_servir ? 'Sim' : 'Não'}</div>
              </div>
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">CRESCEU NA IGREJA</div>
                <div class="text-gray-800 text-base mt-1">{jovem.cresceu_na_igreja ? 'Sim' : 'Não'}</div>
              </div>
            </div>
          </div>

          <div class="mt-10">
            <div class="flex items-center mb-4">
              <div class="w-1 h-6 bg-purple-500 mr-3 rounded"></div>
              <h2 class="text-lg font-bold text-gray-800">IntelliMen</h2>
            </div>
            
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">FORMADO INTELLIMEN</div>
                <div class="text-gray-800 text-base mt-1">{jovem.formado_intellimen ? 'Sim' : 'Não'}</div>
              </div>
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">FAZENDO DESAFIOS</div>
                <div class="text-gray-800 text-base mt-1">{jovem.fazendo_desafios ? 'Sim' : 'Não'}</div>
              </div>
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">QUAL DESAFIO</div>
                <div class="text-gray-800 text-base mt-1">{jovem.qual_desafio || 'Não informado'}</div>
              </div>
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">EDIÇÃO</div>
                <div class="text-gray-800 text-base mt-1">{jovem.edicao_obj?.nome || jovem.edicao || 'Não informado'}</div>
              </div>
            </div>
          </div>

          <div class="mt-10">
            <div class="flex items-center mb-4">
              <div class="w-1 h-6 bg-blue-500 mr-3 rounded"></div>
              <h2 class="text-lg font-bold text-gray-800">Redes Sociais</h2>
            </div>
            
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">INSTAGRAM</div>
                <div class="text-gray-800 text-base mt-1">{jovem.instagram || 'Não informado'}</div>
              </div>
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">FACEBOOK</div>
                <div class="text-gray-800 text-base mt-1">{jovem.facebook || 'Não informado'}</div>
              </div>
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">TIKTOK</div>
                <div class="text-gray-800 text-base mt-1">{jovem.tiktok || 'Não informado'}</div>
              </div>
            </div>
            
            <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 mt-6">
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">OBSERVAÇÃO REDES</div>
                <div class="text-gray-800 text-base mt-1">{jovem.obs_redes || jovem.observacao_redes || 'Não informado'}</div>
              </div>
            </div>
          </div>

          <div class="mt-10">
            <div class="flex items-center mb-4">
              <div class="w-1 h-6 bg-yellow-500 mr-3 rounded"></div>
              <h2 class="text-lg font-bold text-gray-800">Observações e Testemunho</h2>
            </div>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">OBSERVAÇÕES</div>
                <div class="text-gray-800 text-base mt-1">{jovem.observacao || jovem.observacao_text || 'Não informado'}</div>
              </div>
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">TESTEMUNHO</div>
                <div class="text-gray-800 text-base mt-1">{jovem.testemunho || jovem.testemunho_text || 'Não informado'}</div>
              </div>
            </div>
          </div>

          <div class="mt-10">
            <div class="flex items-center mb-4">
              <div class="w-1 h-6 bg-indigo-500 mr-3 rounded"></div>
              <h2 class="text-lg font-bold text-gray-800">Informações do Sistema</h2>
            </div>
            
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">APROVADO</div>
                <div class="text-gray-800 text-base mt-1">{jovem.aprovado ? 'Sim' : 'Não'}</div>
              </div>
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">PASTOR QUE INDICOU</div>
                <div class="text-gray-800 text-base mt-1">{jovem.pastor_que_indicou || 'Não informado'}</div>
              </div>
              <div class="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
                <div class="text-xs font-semibold text-gray-500 uppercase">DATA DE CADASTRO</div>
                <div class="text-gray-800 text-base mt-1">
                  {formatarData(jovem.data_cadastro)}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    {/if}
  </div>
</div>
