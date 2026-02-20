<script>
	import { onMount } from 'svelte';
	import { userProfile } from '$lib/stores/auth';
	import { getUserLevelName } from '$lib/stores/niveis-acesso';
	import { supabase } from '$lib/utils/supabase';
	import Card from '$lib/components/ui/Card.svelte';
	import Button from '$lib/components/ui/Button.svelte';
	import ProgressoTimeline from '$lib/components/progresso/ProgressoTimeline.svelte';
	import EditarPerfilModal from '$lib/components/modals/EditarPerfilModal.svelte';
	import TrocarSenhaModal from '$lib/components/modals/TrocarSenhaModal.svelte';

	let loading = true;
	let error = '';
	let jovem = null;

	// Modais
	let showEditModal = false;
	let showTrocarSenhaModal = false;

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

            // Busca o jovem vinculado ao usuário logado (via usuario_id OU id_usuario_jovem)
            if (!$userProfile?.id) return;
            const { data: jovemData, error: jErr } = await supabase
                .from('jovens')
                .select(`
                    id,
                    nome_completo,
                    foto,
                    idade,
                    igreja_id,
                    edicao_id,
                    igreja:igrejas(nome),
                    edicao:edicoes(id, nome, numero)
                `)
                .or(`usuario_id.eq.${$userProfile.id},id_usuario_jovem.eq.${$userProfile.id}`)
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

	// Funções do modal de edição
	function openEditModal() {
		showEditModal = true;
	}

	function closeEditModal() {
		showEditModal = false;
	}

	function handleEditSuccess(event) {
		// Atualizar o userProfile com os novos dados
		if (event.detail) {
			userProfile.update(profile => ({
				...profile,
				nome: event.detail.nome,
				foto: event.detail.foto
			}));
		}
	}

	// Funções do modal de trocar senha
	function openTrocarSenhaModal() {
		showTrocarSenhaModal = true;
	}

	function closeTrocarSenhaModal() {
		showTrocarSenhaModal = false;
	}
</script>

<!-- Background com gradiente sutil -->
<div class="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50 to-indigo-100 overflow-x-hidden">
	<div class="max-w-6xl mx-auto px-3 sm:px-4 lg:px-6 py-4 sm:py-6 lg:py-8">
		<!-- Header com título estilizado -->
		<div class="text-center mb-6 sm:mb-8">
			<h1 class="text-2xl sm:text-3xl lg:text-4xl font-bold bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent mb-2">
				Meu Perfil
			</h1>
			<p class="text-sm sm:text-base text-gray-600 px-4">Acompanhe sua jornada no Godllywood Campus</p>
		</div>

	{#if loading}
			<div class="space-y-4 sm:space-y-6">
				<!-- Loading skeleton para o card de perfil -->
				<div class="bg-white rounded-xl sm:rounded-2xl shadow-xl p-4 sm:p-6 lg:p-8 animate-pulse">
					<div class="flex flex-col sm:flex-row items-center space-y-4 sm:space-y-0 sm:space-x-6">
						<div class="w-16 h-16 sm:w-20 sm:h-20 bg-gray-200 rounded-full"></div>
						<div class="flex-1 text-center sm:text-left">
							<div class="h-5 sm:h-6 bg-gray-200 rounded w-1/2 sm:w-1/3 mb-2 mx-auto sm:mx-0"></div>
							<div class="h-4 bg-gray-200 rounded w-1/3 sm:w-1/4 mx-auto sm:mx-0"></div>
						</div>
					</div>
				</div>
				<!-- Loading skeleton para os cards de estatísticas -->
				<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6">
					{#each Array(3) as _}
						<div class="bg-white rounded-xl sm:rounded-2xl shadow-xl p-4 sm:p-6 animate-pulse">
							<div class="h-4 bg-gray-200 rounded w-1/2 mb-3"></div>
							<div class="h-6 sm:h-8 bg-gray-200 rounded w-1/3"></div>
						</div>
					{/each}
				</div>
		</div>
	{:else if error}
			<div class="bg-red-50 border border-red-200 rounded-xl sm:rounded-2xl p-4 sm:p-6 lg:p-8 text-center">
				<div class="w-12 h-12 sm:w-16 sm:h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-3 sm:mb-4">
					<svg class="w-6 h-6 sm:w-8 sm:h-8 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
						<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
					</svg>
				</div>
				<h3 class="text-base sm:text-lg font-semibold text-red-800 mb-2">Erro ao carregar perfil</h3>
				<p class="text-sm sm:text-base text-red-600 px-4">{error}</p>
			</div>
	{:else}
			<!-- Card principal do perfil -->
			<div class="bg-white rounded-xl sm:rounded-2xl shadow-xl overflow-hidden mb-6 sm:mb-8">
				<!-- Header com gradiente -->
				<div class="bg-gradient-to-r from-blue-600 to-purple-600 px-4 sm:px-6 lg:px-8 py-4 sm:py-6">
					<div class="flex flex-col sm:flex-row items-center sm:justify-between space-y-4 sm:space-y-0">
						<div class="flex flex-col sm:flex-row items-center space-y-4 sm:space-y-0 sm:space-x-6">
							<!-- Avatar com borda e sombra (clicável) -->
							<div class="relative cursor-pointer group" on:click={openEditModal} on:keydown={(e) => e.key === 'Enter' && openEditModal()} role="button" tabindex="0">
				{#if $userProfile?.foto}
									<img 
										class="w-20 h-20 sm:w-24 sm:h-24 rounded-full object-cover border-4 border-white shadow-lg group-hover:shadow-xl transition-all duration-300 group-hover:scale-105" 
										src={$userProfile.foto} 
										alt={$userProfile.nome} 
									/>
				{:else}
									<div class="w-20 h-20 sm:w-24 sm:h-24 rounded-full bg-gradient-to-br from-white to-gray-100 text-blue-600 flex items-center justify-center text-2xl sm:text-3xl font-bold border-4 border-white shadow-lg group-hover:shadow-xl transition-all duration-300 group-hover:scale-105">
						{$userProfile?.nome?.charAt(0) || 'U'}
					</div>
				{/if}
								<!-- Overlay de edição -->
								<div class="absolute inset-0 rounded-full bg-black bg-opacity-0 group-hover:bg-opacity-30 transition-all duration-300 flex items-center justify-center">
									<svg class="w-6 h-6 sm:w-8 sm:h-8 text-white opacity-0 group-hover:opacity-100 transition-all duration-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
										<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
									</svg>
								</div>
								<!-- Badge de status -->
								<div class="absolute -bottom-1 -right-1 sm:-bottom-2 sm:-right-2 w-6 h-6 sm:w-8 sm:h-8 bg-green-500 rounded-full border-2 sm:border-4 border-white flex items-center justify-center">
									<svg class="w-3 h-3 sm:w-4 sm:h-4 text-white" fill="currentColor" viewBox="0 0 20 20">
										<path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
									</svg>
								</div>
							</div>
							<div class="text-white text-center sm:text-left">
								<h2 class="text-xl sm:text-2xl font-bold mb-1">{$userProfile?.nome || 'Usuário'}</h2>
								<p class="text-blue-100 text-base sm:text-lg">{getUserLevelName($userProfile)}</p>
								<div class="flex items-center justify-center sm:justify-start mt-2">
									<svg class="w-4 h-4 sm:w-5 sm:h-5 text-blue-200 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
										<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
										<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
									</svg>
									<span class="text-blue-100 text-sm sm:text-base">Godllywood Campus</span>
								</div>
							</div>
						</div>
						
						<!-- Botões de Ação -->
						<div class="flex flex-col sm:flex-row gap-2 sm:gap-3 w-full sm:w-auto">
							<!-- Botão Trocar Senha -->
							<Button 
								on:click={openTrocarSenhaModal}
								variant="outline" 
								class="bg-white/10 backdrop-blur-sm border-white/20 text-white hover:bg-white/20 transition-all duration-300 flex items-center gap-2 px-4 sm:px-6 py-2 sm:py-3 rounded-lg sm:rounded-xl text-sm sm:text-base"
							>
								<svg class="w-4 h-4 sm:w-5 sm:h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z" />
								</svg>
								<span class="hidden xs:inline">Trocar Senha</span>
								<span class="xs:hidden">Senha</span>
							</Button>
							
							<!-- Botão Editar Perfil -->
							{#if jovem?.id}
								<Button 
									href="/jovens/{jovem.id}/editar" 
									variant="outline" 
									class="bg-white/10 backdrop-blur-sm border-white/20 text-white hover:bg-white/20 transition-all duration-300 flex items-center gap-2 px-4 sm:px-6 py-2 sm:py-3 rounded-lg sm:rounded-xl text-sm sm:text-base"
								>
									<svg class="w-4 h-4 sm:w-5 sm:h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
										<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
									</svg>
									<span class="hidden xs:inline">Editar Perfil</span>
									<span class="xs:hidden">Editar</span>
								</Button>
							{/if}
						</div>
					</div>
				</div>

				<!-- Informações do perfil -->
				<div class="p-4 sm:p-6 lg:p-8">
					<div class="grid grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4 lg:gap-6">
						<div class="text-center p-3 sm:p-4 bg-gradient-to-br from-blue-50 to-blue-100 rounded-lg sm:rounded-xl">
							<div class="w-8 h-8 sm:w-10 sm:h-10 lg:w-12 lg:h-12 bg-blue-500 rounded-full flex items-center justify-center mx-auto mb-2 sm:mb-3">
								<svg class="w-4 h-4 sm:w-5 sm:h-5 lg:w-6 lg:h-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
								</svg>
							</div>
							<p class="text-xs sm:text-sm font-medium text-blue-600 mb-1">Edição</p>
                            <p class="text-sm sm:text-base lg:text-lg font-bold text-gray-900 truncate">{jovem?.edicao ? (jovem.edicao.numero ? `Edição ${jovem.edicao.numero}` : (jovem.edicao.nome || '-')) : '-'}</p>
						</div>
						
						<div class="text-center p-3 sm:p-4 bg-gradient-to-br from-purple-50 to-purple-100 rounded-lg sm:rounded-xl">
							<div class="w-8 h-8 sm:w-10 sm:h-10 lg:w-12 lg:h-12 bg-purple-500 rounded-full flex items-center justify-center mx-auto mb-2 sm:mb-3">
								<svg class="w-4 h-4 sm:w-5 sm:h-5 lg:w-6 lg:h-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
								</svg>
							</div>
							<p class="text-xs sm:text-sm font-medium text-purple-600 mb-1">Idade</p>
                            <p class="text-sm sm:text-base lg:text-lg font-bold text-gray-900">{jovem?.idade ?? '-'} anos</p>
						</div>
						
						<div class="text-center p-3 sm:p-4 bg-gradient-to-br from-green-50 to-green-100 rounded-lg sm:rounded-xl">
							<div class="w-8 h-8 sm:w-10 sm:h-10 lg:w-12 lg:h-12 bg-green-500 rounded-full flex items-center justify-center mx-auto mb-2 sm:mb-3">
								<svg class="w-4 h-4 sm:w-5 sm:h-5 lg:w-6 lg:h-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
								</svg>
							</div>
							<p class="text-xs sm:text-sm font-medium text-green-600 mb-1">Igreja</p>
                            <p class="text-sm sm:text-base lg:text-lg font-bold text-gray-900">{jovem?.igreja?.nome || '-'}</p>
						</div>
						
						<div class="text-center p-3 sm:p-4 bg-gradient-to-br {totalAval > 0 ? 'from-green-50 to-green-100' : 'from-orange-50 to-orange-100'} rounded-lg sm:rounded-xl">
							<div class="w-8 h-8 sm:w-10 sm:h-10 lg:w-12 lg:h-12 {totalAval > 0 ? 'bg-green-500' : 'bg-orange-500'} rounded-full flex items-center justify-center mx-auto mb-2 sm:mb-3">
								<svg class="w-4 h-4 sm:w-5 sm:h-5 lg:w-6 lg:h-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
								</svg>
							</div>
							<p class="text-xs sm:text-sm font-medium {totalAval > 0 ? 'text-green-600' : 'text-orange-600'} mb-1">Status</p>
							<p class="text-sm sm:text-base lg:text-lg font-bold text-gray-900 truncate">{totalAval > 0 ? 'Avaliado' : 'Avaliação Pendente'}</p>
						</div>
					</div>
				</div>
			</div>

			<!-- Cards de estatísticas -->
			{#if $userProfile?.nivel !== 'jovem'}
				<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6 mb-6 sm:mb-8">
					<div class="bg-white rounded-xl sm:rounded-2xl shadow-xl p-4 sm:p-6 hover:shadow-2xl transition-all duration-300">
						<div class="flex items-center justify-between mb-3 sm:mb-4">
							<div class="w-10 h-10 sm:w-12 sm:h-12 bg-gradient-to-br from-blue-500 to-blue-600 rounded-lg sm:rounded-xl flex items-center justify-center">
								<svg class="w-5 h-5 sm:w-6 sm:h-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
								</svg>
							</div>
							<span class="text-xl sm:text-2xl font-bold text-blue-600">{totalAval}</span>
						</div>
						<h3 class="text-base sm:text-lg font-semibold text-gray-900 mb-1">Total de Avaliações</h3>
						<p class="text-gray-600 text-xs sm:text-sm">Avaliações recebidas</p>
					</div>

					<div class="bg-white rounded-xl sm:rounded-2xl shadow-xl p-4 sm:p-6 hover:shadow-2xl transition-all duration-300">
						<div class="flex items-center justify-between mb-3 sm:mb-4">
							<div class="w-10 h-10 sm:w-12 sm:h-12 bg-gradient-to-br from-green-500 to-green-600 rounded-lg sm:rounded-xl flex items-center justify-center">
								<svg class="w-5 h-5 sm:w-6 sm:h-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
								</svg>
							</div>
							<span class="text-xl sm:text-2xl font-bold text-green-600">{mediaNota ? mediaNota.toFixed(1) : '-'}</span>
						</div>
						<h3 class="text-base sm:text-lg font-semibold text-gray-900 mb-1">Média Geral</h3>
						<p class="text-gray-600 text-xs sm:text-sm">Nota média das avaliações</p>
					</div>

					<div class="bg-white rounded-xl sm:rounded-2xl shadow-xl p-4 sm:p-6 hover:shadow-2xl transition-all duration-300 sm:col-span-2 lg:col-span-1">
						<div class="flex items-center justify-between mb-3 sm:mb-4">
							<div class="w-10 h-10 sm:w-12 sm:h-12 bg-gradient-to-br from-purple-500 to-purple-600 rounded-lg sm:rounded-xl flex items-center justify-center">
								<svg class="w-5 h-5 sm:w-6 sm:h-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
								</svg>
							</div>
							<span class="text-lg sm:text-xl lg:text-2xl font-bold text-purple-600">{ultimaData ? ultimaData.toLocaleDateString() : '-'}</span>
						</div>
						<h3 class="text-base sm:text-lg font-semibold text-gray-900 mb-1">Última Avaliação</h3>
						<p class="text-gray-600 text-xs sm:text-sm">Data da última avaliação</p>
					</div>
				</div>
			{/if}

			<!-- Timeline de Progresso -->
			{#if jovem?.id}
				<div class="bg-white rounded-xl sm:rounded-2xl shadow-xl overflow-hidden mb-6 sm:mb-8">
					<div class="bg-gradient-to-r from-indigo-500 to-purple-600 px-4 sm:px-6 lg:px-8 py-4 sm:py-6">
						<div class="flex items-center space-x-3">
							<div class="w-8 h-8 sm:w-10 sm:h-10 bg-white/20 rounded-lg sm:rounded-xl flex items-center justify-center">
								<svg class="w-5 h-5 sm:w-6 sm:h-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
								</svg>
				</div>
				<div>
								<h3 class="text-lg sm:text-xl font-bold text-white">Timeline de Progresso</h3>
								<p class="text-indigo-100 text-sm sm:text-base">Acompanhe sua evolução espiritual</p>
							</div>
				</div>
				</div>
					<div class="p-4 sm:p-6 lg:p-8">
						<ProgressoTimeline jovemId={jovem.id} />
				</div>
			</div>
			{/if}

			<!-- Timeline de Avaliações -->
			{#if $userProfile?.nivel !== 'jovem'}
				<div class="bg-white rounded-xl sm:rounded-2xl shadow-xl overflow-hidden">
					<div class="bg-gradient-to-r from-gray-700 to-gray-800 px-4 sm:px-6 lg:px-8 py-4 sm:py-6">
						<div class="flex items-center space-x-3">
							<div class="w-8 h-8 sm:w-10 sm:h-10 bg-white/20 rounded-lg sm:rounded-xl flex items-center justify-center">
								<svg class="w-5 h-5 sm:w-6 sm:h-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
								</svg>
					</div>
							<div>
								<h3 class="text-lg sm:text-xl font-bold text-white">Histórico de Avaliações</h3>
								<p class="text-gray-300 text-sm sm:text-base">Todas as suas avaliações</p>
					</div>
					</div>
				</div>
					<div class="p-4 sm:p-6 lg:p-8">
				{#if !avaliacoes?.length}
							<div class="text-center py-8 sm:py-12">
								<div class="w-12 h-12 sm:w-16 sm:h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-3 sm:mb-4">
									<svg class="w-6 h-6 sm:w-8 sm:h-8 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
										<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
									</svg>
								</div>
								<h3 class="text-base sm:text-lg font-semibold text-gray-900 mb-2">Nenhuma avaliação registrada</h3>
								<p class="text-sm sm:text-base text-gray-600 px-4">Suas avaliações aparecerão aqui quando forem realizadas.</p>
							</div>
				{:else}
							<div class="space-y-3 sm:space-y-4">
						{#each avaliacoes as a}
									<div class="bg-gradient-to-r from-gray-50 to-gray-100 rounded-lg sm:rounded-xl p-4 sm:p-6 hover:shadow-md transition-all duration-300">
										<div class="flex flex-col sm:flex-row items-start sm:items-center justify-between space-y-3 sm:space-y-0">
											<div class="flex items-center space-x-3 sm:space-x-4">
												<div class="w-10 h-10 sm:w-12 sm:h-12 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center">
													<span class="text-white font-bold text-base sm:text-lg">{a.nota ?? '-'}</span>
												</div>
												<div>
													<p class="font-semibold text-gray-900 text-sm sm:text-base">
														{new Date(a.criado_em).toLocaleDateString('pt-BR', { 
															day: '2-digit', 
															month: 'long', 
															year: 'numeric' 
														})}
													</p>
													<p class="text-xs sm:text-sm text-gray-600">Avaliação realizada</p>
												</div>
											</div>
											<div class="w-full sm:w-auto">
												<div class="flex flex-wrap gap-1 sm:gap-2 text-xs">
													<span class="px-2 py-1 bg-blue-100 text-blue-800 rounded-full">Espírito: {a.espirito ?? '-'}</span>
													<span class="px-2 py-1 bg-green-100 text-green-800 rounded-full">Caráter: {a.caractere ?? '-'}</span>
													<span class="px-2 py-1 bg-purple-100 text-purple-800 rounded-full">Disposição: {a.disposicao ?? '-'}</span>
												</div>
											</div>
								</div>
							</div>
						{/each}
					</div>
					{#if hasMore}
								<div class="mt-4 sm:mt-6 text-center">
									<Button 
										on:click={loadMore} 
										disabled={loadingMore}
										class="bg-gradient-to-r from-blue-500 to-purple-600 text-white px-6 sm:px-8 py-2 sm:py-3 rounded-lg sm:rounded-xl hover:from-blue-600 hover:to-purple-700 transition-all duration-300 disabled:opacity-50 text-sm sm:text-base w-full sm:w-auto"
									>
										{loadingMore ? 'Carregando...' : 'Carregar mais'}
									</Button>
						</div>
					{/if}
				{/if}
					</div>
				</div>
			{/if}
	{/if}
</div>
</div>

<!-- Modal de Edição de Perfil -->
<EditarPerfilModal 
	bind:isOpen={showEditModal}
	userProfile={$userProfile}
	on:close={closeEditModal}
	on:success={handleEditSuccess}
/>

<!-- Modal de Trocar Senha -->
<TrocarSenhaModal 
	bind:isOpen={showTrocarSenhaModal}
	on:close={closeTrocarSenhaModal}
/>

