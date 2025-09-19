<script>
  import { onMount } from 'svelte';
  import { page } from '$app/stores';
  import ProgressoTimeline from '$lib/components/progresso/ProgressoTimeline.svelte';
  import { userProfile } from '$lib/stores/auth';

  let currentUser = null;
  let jovemId = null;
  let jovemNome = '';

  onMount(async () => {
    currentUser = $userProfile;
    // Captura o id do jovem via querystring ?jovem=ID
    jovemId = $page.url.searchParams.get('jovem');
    if (jovemId) {
      try {
        const { supabase } = await import('$lib/utils/supabase');
        const { data, error } = await supabase
          .from('jovens')
          .select('nome_completo')
          .eq('id', jovemId)
          .single();
        if (!error && data?.nome_completo) {
          jovemNome = data.nome_completo;
        }
      } catch (err) {
        console.error('Erro ao carregar nome do jovem:', err);
      }
    }
  });
</script>

<svelte:head>
  <title>Progresso dos Jovens - IntelliMen Campus</title>
</svelte:head>

<div class="min-h-screen py-8" style="background-color: #333333; border-radius: 20px;">
  <div class="max-w-7xl mx-auto px-4">
    <div class="mb-8 text-center">
      <h1 class="text-3xl sm:text-4xl font-bold text-white mb-2">
        {jovemNome ? `${jovemNome}` : 'Progresso dos Jovens'}
      </h1>
      <p class="text-gray-300 text-lg">
        {jovemNome ? 'Acompanhe a evolução espiritual deste jovem' : 'Acompanhe a evolução espiritual dos jovens através da timeline de progresso'}
      </p>
    </div>

    <!-- Timeline centralizada -->
    <div class="flex justify-center">
      <div class="w-full max-w-2xl">
        <ProgressoTimeline {jovemId} />
      </div>
    </div>
  </div>
</div>
