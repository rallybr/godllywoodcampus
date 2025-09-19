<script>
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { user } from '$lib/stores/auth';
  import CadastroJovem from '$lib/components/forms/CadastroJovem.svelte';
  
  onMount(() => {
    if (!$user) {
      goto('/login');
    }
  });
</script>

<svelte:head>
  <title>Cadastrar Jovem - IntelliMen Campus</title>
</svelte:head>

<div class="min-h-screen bg-gray-100 py-6 sm:py-8">
  <div class="max-w-6xl mx-auto px-4 sm:px-6">
    <CadastroJovem />
  </div>
</div>