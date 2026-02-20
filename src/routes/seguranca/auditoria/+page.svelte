<script>
  export const ssr = false;
  export const prerender = false;
  import AuditLogs from '$lib/components/security/AuditLogs.svelte';
</script>

<svelte:head>
  <title>Logs de Auditoria - Godllywood Campus</title>
</svelte:head>

<div class="max-w-7xl mx-auto py-8 px-4 sm:px-6 overflow-x-hidden">
  <AuditLogs />
</div>
