<script>
  import { page } from '$app/stores';
  import JovemProfile from '$lib/components/jovens/JovemProfile.svelte';
</script>

<svelte:head>
  <title>Detalhes do Jovem - IntelliMen Campus</title>
</svelte:head>

<JovemProfile jovemId={$page.params.id} />