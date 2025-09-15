<script>
  import { onMount } from 'svelte';
  import { user } from '$lib/stores/auth';
  import { goto } from '$app/navigation';
  import ListaAvaliacoes from '$lib/components/avaliacoes/ListaAvaliacoes.svelte';
  
  onMount(() => {
    if (!$user) {
      goto('/login');
    }
  });
</script>

<svelte:head>
  <title>Avaliações - IntelliMen Campus</title>
</svelte:head>

<div class="max-w-7xl mx-auto py-8">
  <div class="mb-8">
    <h1 class="text-3xl font-bold text-gray-900 mb-2">Avaliações</h1>
    <p class="text-gray-600">Visualize e gerencie todas as avaliações dos jovens cadastrados no sistema.</p>
  </div>
  
  <ListaAvaliacoes />
</div>
