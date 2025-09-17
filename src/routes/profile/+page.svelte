<script>
	import { onMount } from 'svelte';
	import { userProfile } from '$lib/stores/auth';
	import { supabase } from '$lib/utils/supabase';
	import Card from '$lib/components/ui/Card.svelte';
	import Button from '$lib/components/ui/Button.svelte';

	let loading = true;
	let error = '';
	let jovem = null;

	// KPIs
	let totalAval = 0;
	let mediaNota = null;
	let ultimaData = null;

	// Timeline (paginada)
	let avaliacoes = [];
	let page = 1;
	const pageSize = 10;
	let hasMore = false;
	let loadingMore = false;

	async function loadKpis(jovemId) {
		// total
		const { count: totalCount, error: cErr } = await supabase
			.from('avaliacoes')
			.select('id', { count: 'exact', head: true })
			.eq('jovem_id', jovemId);
		if (cErr) throw cErr;
		totalAval = totalCount || 0;

		// média e última data (duas consultas simples)
		const { data: ult, error: uErr } = await supabase
			.from('avaliacoes')
			.select('criado_em, nota')
			.eq('jovem_id', jovemId)
			.order('criado_em', { ascending: false })
			.limit(1);
		if (uErr) throw uErr;
		ultimaData = ult?.[0]?.criado_em ? new Date(ult[0].criado_em) : null;

		const { data: notas, error: nErr } = await supabase
			.from('avaliacoes')
			.select('nota')
			.eq('jovem_id', jovemId);
		if (nErr) throw nErr;
		if (notas && notas.length) {
			const valid = notas.map(n => Number(n.nota)).filter(n => !Number.isNaN(n));
			mediaNota = valid.length ? (valid.reduce((a,b)=>a+b,0) / valid.length) : null;
		} else mediaNota = null;
	}

	async function loadTimeline(jovemId, reset = false) {
		const from = (page - 1) * pageSize;
		const to = from + pageSize - 1;
		const { data, error: e, count } = await supabase
			.from('avaliacoes')
			.select('id, espirito, caractere, disposicao, nota, criado_em, user_id', { count: 'exact' })
			.eq('jovem_id', jovemId)
			.order('criado_em', { ascending: false })
			.range(from, to);
		if (e) throw e;
		if (reset) avaliacoes = [];
		avaliacoes = [...avaliacoes, ...(data || [])];
		hasMore = count != null ? to + 1 < count : (data?.length === pageSize);
	}

	async function loadData() {
		try {
			loading = true;
			error = '';

			// Busca o jovem vinculado ao usuário logado (via usuario_id)
			if (!$userProfile?.id) return;
			const { data: jovemData, error: jErr } = await supabase
				.from('jovens')
				.select('*')
				.eq('usuario_id', $userProfile.id)
				.limit(1)
				.maybeSingle();
			if (jErr) throw jErr;
			jovem = jovemData;

			if (jovem?.id) {
				await loadKpis(jovem.id);
				page = 1;
				await loadTimeline(jovem.id, true);
			}
		} catch (e) {
			error = e?.message || 'Falha ao carregar dados do perfil';
			console.error('Perfil - erro:', e);
		} finally {
			loading = false;
		}
	}

	async function loadMore() {
		if (!jovem?.id || loadingMore || !hasMore) return;
		try {
			loadingMore = true;
			page += 1;
			await loadTimeline(jovem.id);
		} finally {
			loadingMore = false;
		}
	}

	onMount(loadData);
</script>

<div class="max-w-4xl mx-auto px-4 py-6">
	<h1 class="text-2xl font-bold text-gray-900 mb-4">Meu Perfil</h1>

	{#if loading}
		<div class="space-y-4">
			<div class="fb-card p-6 animate-pulse">Carregando perfil...</div>
			<div class="fb-card p-6 animate-pulse">Carregando avaliações...</div>
		</div>
	{:else if error}
		<div class="fb-card p-6 text-red-600">{error}</div>
	{:else}
		<!-- Resumo do jovem -->
		<Card padding="p-6">
			<div class="flex items-center gap-4">
				{#if $userProfile?.foto}
					<img class="w-16 h-16 rounded-full object-cover" src={$userProfile.foto} alt={$userProfile.nome} />
				{:else}
					<div class="w-16 h-16 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 text-white flex items-center justify-center text-xl font-bold">
						{$userProfile?.nome?.charAt(0) || 'U'}
					</div>
				{/if}
				<div class="min-w-0">
					<h2 class="text-lg font-semibold text-gray-900 truncate">{$userProfile?.nome || 'Usuário'}</h2>
					<p class="text-sm text-gray-600 truncate">{$userProfile?.user_roles?.[0]?.roles?.nome || 'Jovem'}</p>
				</div>
			</div>

			<div class="grid grid-cols-1 sm:grid-cols-2 gap-4 mt-6">
				<div>
					<p class="text-sm text-gray-500">Edição</p>
					<p class="font-medium">{jovem?.edicao || '-'}</p>
				</div>
				<div>
					<p class="text-sm text-gray-500">Idade</p>
					<p class="font-medium">{jovem?.idade || '-'}</p>
				</div>
				<div>
					<p class="text-sm text-gray-500">Igreja</p>
					<p class="font-medium">{jovem?.igreja_id ? 'Vinculada' : '-'}</p>
				</div>
				<div>
					<p class="text-sm text-gray-500">Status</p>
					<p class="font-medium">{jovem?.aprovado ?? 'não avaliado'}</p>
				</div>
			</div>
		</Card>

		<!-- KPIs de avaliações -->
		<Card padding="p-6" class="mt-4">
			<h3 class="text-lg font-semibold text-gray-900 mb-4">Resumo de Avaliações</h3>
			<div class="grid grid-cols-1 xs:grid-cols-3 gap-4">
				<div class="p-4 rounded-lg border">
					<p class="text-sm text-gray-500">Total</p>
					<p class="text-2xl font-bold">{totalAval}</p>
				</div>
				<div class="p-4 rounded-lg border">
					<p class="text-sm text-gray-500">Média</p>
					<p class="text-2xl font-bold">{mediaNota ? mediaNota.toFixed(1) : '-'}</p>
				</div>
				<div class="p-4 rounded-lg border">
					<p class="text-sm text-gray-500">Última</p>
					<p class="text-2xl font-bold">{ultimaData ? ultimaData.toLocaleDateString() : '-'}</p>
				</div>
			</div>
		</Card>

		<!-- Timeline -->
		<Card padding="p-6" class="mt-4">
			<h3 class="text-lg font-semibold text-gray-900 mb-4">Timeline</h3>
			{#if !avaliacoes?.length}
				<p class="text-gray-500 text-sm">Nenhuma avaliação registrada ainda.</p>
			{:else}
				<div class="space-y-3">
					{#each avaliacoes as a}
						<div class="border rounded-lg p-3 flex items-center justify-between">
							<div class="text-sm">
								<p><span class="text-gray-500">Data:</span> {new Date(a.criado_em).toLocaleDateString()}</p>
								<p><span class="text-gray-500">Nota:</span> {a.nota ?? '-'}</p>
							</div>
							<div class="text-xs text-gray-500">espírito {a.espirito ?? '-'} • caráter {a.caractere ?? '-'} • disposição {a.disposicao ?? '-'}</div>
						</div>
					{/each}
				</div>
				{#if hasMore}
					<div class="mt-4">
						<Button on:click={loadMore} disabled={loadingMore}>{loadingMore ? 'Carregando...' : 'Carregar mais'}</Button>
					</div>
				{/if}
			{/if}
		</Card>
	{/if}
</div>

<style>
	.fb-card { background: white; border: 1px solid #e5e7eb; border-radius: 0.75rem; }
</style>
