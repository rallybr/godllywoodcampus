<script>
  import { userHierarchyLevel, getLevelName, getLevelColor } from '$lib/stores/niveis-acesso';
</script>

<div class="flex items-center space-x-2">
  <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium {getLevelColor($userHierarchyLevel)}">
    {getLevelName($userHierarchyLevel)}
  </span>
</div>
