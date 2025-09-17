<script>
	import { onMount } from 'svelte';
	import { supabase } from '$lib/utils/supabase';
	import Card from '$lib/components/ui/Card.svelte';
	import Select from '$lib/components/ui/Select.svelte';
	import Button from '$lib/components/ui/Button.svelte';
	import { estados, blocos, regioes, igrejas, loadBlocos, loadRegioes, loadIgrejas } from '$lib/stores/geographic';

	let loading = true;
	let error = '';
	let users = [];
	let roles = [];
	let userRoles = [];

	let q = '';
	let selectedUser = null;
	let editing = null; // registro em edição

	let form = {
		user_id: '',
		role_id: '',
		estado_id: '',
		bloco_id: '',
		regiao_id: '',
		igreja_id: '',
		ativo: true
	};

	// --- Transferência de liderança ---
	const leaderRoleSlugs = [
		'lider_nacional_iurd','lider_nacional_fju',
		'lider_estadual_iurd','lider_estadual_fju',
		'lider_bloco_iurd','lider_bloco_fju',
		'lider_regional_iurd','lider_igreja_iurd'
	];
	let transfer = {
		from_user_id: '',
		to_user_id: '',
		role_id: '',
		estado_id: '',
		bloco_id: '',
		regiao_id: '',
		igreja_id: ''
	};

	async function loadLookups() {
		const [{ data: usersData }, { data: rolesData }] = await Promise.all([
			supabase.from('usuarios').select('id, nome, email').order('nome', { ascending: true }),
			supabase.from('roles').select('id, nome, slug').order('nome', { ascending: true })
		]);
		users = usersData || [];
		roles = rolesData || [];
	}

	async function loadUserRoles() {
		if (!selectedUser?.id) { userRoles = []; return; }
		const { data, error: e } = await supabase
			.from('user_roles')
			.select('id, ativo, created_at:criado_em, role_id, roles:role_id(id, nome, slug), estado_id, bloco_id, regiao_id, igreja_id')
			.eq('user_id', selectedUser.id)
			.order('criado_em', { ascending: false });
		if (e) throw e;
		userRoles = data || [];
	}

	function resetForm() {
		form = { user_id: selectedUser?.id || '', role_id: '', estado_id: '', bloco_id: '', regiao_id: '', igreja_id: '', ativo: true };
		editing = null;
	}

	async function saveForm() {
		try {
			loading = true; error = '';
			const payload = { ...form };
			['estado_id','bloco_id','regiao_id','igreja_id'].forEach(k => { if (!payload[k]) delete payload[k]; });
			let resp;
			if (editing?.id) {
				resp = await supabase.from('user_roles').update(payload).eq('id', editing.id).select().single();
			} else {
				resp = await supabase.from('user_roles').insert([payload]).select().single();
			}
			if (resp.error) throw resp.error;
			await loadUserRoles();
			resetForm();
		} catch (e) {
			error = e?.message || 'Falha ao salvar papel';
			console.error(e);
		} finally {
			loading = false;
		}
	}

	async function editRole(r) {
		editing = r;
		form = {
			user_id: selectedUser?.id || '',
			role_id: r?.roles?.id || r?.role_id || '',
			estado_id: r?.estado_id || '',
			bloco_id: r?.bloco_id || '',
			regiao_id: r?.regiao_id || '',
			igreja_id: r?.igreja_id || '',
			ativo: r?.ativo ?? true
		};
		if (form.estado_id) await loadBlocos(form.estado_id);
		if (form.bloco_id) await loadRegioes(form.bloco_id);
		if (form.regiao_id) await loadIgrejas(form.regiao_id);
	}

	async function deleteRole(id) {
		if (!confirm('Remover este papel?')) return;
		const { error: e } = await supabase.from('user_roles').delete().eq('id', id);
		if (e) { error = e.message; return; }
		await loadUserRoles();
	}

	function applyUserFilter(list) {
		const term = q.trim().toLowerCase();
		if (!term) return list;
		return list.filter(u => (u.nome||'').toLowerCase().includes(term) || (u.email||'').toLowerCase().includes(term));
	}

	function roleIsLeader(rid) {
		const r = roles.find(x => x.id === rid);
		return r && leaderRoleSlugs.includes(r.slug);
	}

	function scopeValid(t) {
		// Pelo menos um nível deve ser especificado para líder não-nacional
		const r = roles.find(x => x.id === t.role_id);
		if (!r) return false;
		if (['lider_nacional_iurd','lider_nacional_fju'].includes(r.slug)) return true; // nacional não exige escopo
		return !!(t.estado_id || t.bloco_id || t.regiao_id || t.igreja_id);
	}

	async function transferLeadership() {
		try {
			loading = true; error = '';
			// validações
			if (!transfer.from_user_id || !transfer.to_user_id) throw new Error('Selecione origem e destino');
			if (transfer.from_user_id === transfer.to_user_id) throw new Error('Origem e destino não podem ser o mesmo usuário');
			if (!transfer.role_id) throw new Error('Selecione o papel de liderança');
			if (!roleIsLeader(transfer.role_id)) throw new Error('Papel selecionado não é um papel de liderança');
			if (!scopeValid(transfer)) throw new Error('Defina um escopo (estado/bloco/região/igreja) adequado para a liderança');

			// localizar papel de origem correspondente (mesmo role+escopo)
			let query = supabase.from('user_roles').select('*').eq('user_id', transfer.from_user_id).eq('role_id', transfer.role_id).limit(1);
			if (transfer.estado_id) query = query.eq('estado_id', transfer.estado_id); else query = query.is('estado_id', null);
			if (transfer.bloco_id) query = query.eq('bloco_id', transfer.bloco_id); else query = query.is('bloco_id', null);
			if (transfer.regiao_id) query = query.eq('regiao_id', transfer.regiao_id); else query = query.is('regiao_id', null);
			if (transfer.igreja_id) query = query.eq('igreja_id', transfer.igreja_id); else query = query.is('igreja_id', null);
			const { data: fromRole, error: frErr } = await query.maybeSingle();
			if (frErr) throw frErr;
			if (!fromRole) throw new Error('Papel de origem não encontrado com o escopo informado');

			// criar papel no destino (se não existir)
			const payloadNew = {
				user_id: transfer.to_user_id,
				role_id: transfer.role_id,
				estado_id: transfer.estado_id || null,
				bloco_id: transfer.bloco_id || null,
				regiao_id: transfer.regiao_id || null,
				igreja_id: transfer.igreja_id || null,
				ativo: true
			};
			// verificar duplicidade no destino
			let q2 = supabase.from('user_roles').select('id').eq('user_id', payloadNew.user_id).eq('role_id', payloadNew.role_id).limit(1);
			q2 = payloadNew.estado_id ? q2.eq('estado_id', payloadNew.estado_id) : q2.is('estado_id', null);
			q2 = payloadNew.bloco_id ? q2.eq('bloco_id', payloadNew.bloco_id) : q2.is('bloco_id', null);
			q2 = payloadNew.regiao_id ? q2.eq('regiao_id', payloadNew.regiao_id) : q2.is('regiao_id', null);
			q2 = payloadNew.igreja_id ? q2.eq('igreja_id', payloadNew.igreja_id) : q2.is('igreja_id', null);
			const { data: dup } = await q2.maybeSingle();
			if (!dup) {
				const ins = await supabase.from('user_roles').insert([payloadNew]).select().single();
				if (ins.error) throw ins.error;
			}

			// desativar papel antigo
			const upd = await supabase.from('user_roles').update({ ativo: false }).eq('id', fromRole.id).select().single();
			if (upd.error) throw upd.error;

			// registrar no logs_historico
			await supabase.from('logs_historico').insert([
				{
					user_id: transfer.from_user_id,
					acao: 'transferencia_lideranca',
					detalhe: 'Transferência de liderança para outro usuário',
					dados_anteriores: fromRole,
					dados_novos: payloadNew
				}
			]);

			// feedback e limpeza
			await loadUserRoles();
			transfer = { from_user_id: '', to_user_id: '', role_id: '', estado_id: '', bloco_id: '', regiao_id: '', igreja_id: '' };
		} catch (e) {
			error = e?.message || 'Falha na transferência de liderança';
			console.error(e);
		} finally {
			loading = false;
		}
	}

	onMount(async () => {
		try { loading = true; await loadLookups(); } finally { loading = false; }
	});
</script>

<div class="max-w-6xl mx-auto px-4 py-6 space-y-6">
	<h1 class="text-2xl font-bold text-gray-900">Gestão de Papéis e Escopos</h1>

	<Card padding="p-4">
		<h2 class="font-semibold mb-3">Selecionar usuário</h2>
		<div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
			<input class="w-full px-3 py-2 border rounded-lg" placeholder="Buscar por nome ou e-mail" bind:value={q} />
			<select class="w-full px-3 py-2 border rounded-lg" bind:value={selectedUser} on:change={loadUserRoles}>
				<option value={null}>— selecione —</option>
				{#each applyUserFilter(users) as u}
					<option value={u}>{u.nome} {u.email ? `— ${u.email}` : ''}</option>
				{/each}
			</select>
		</div>
	</Card>

	{#if selectedUser}
		<!-- Lista de papéis do usuário -->
		<Card padding="p-4">
			<div class="flex items-center justify-between mb-3">
				<h2 class="font-semibold">Papéis de {selectedUser.nome}</h2>
				<Button on:click={resetForm}>Novo papel</Button>
			</div>
			{#if !userRoles.length}
				<p class="text-sm text-gray-500">Nenhum papel definido.</p>
			{:else}
				<div class="space-y-2">
					{#each userRoles as r}
						<div class="p-3 border rounded-lg flex items-center justify-between">
							<div class="text-sm">
								<div><span class="text-gray-500">Papel:</span> {r?.roles?.nome || '-'}</div>
								<div class="text-gray-500">Escopo: {r.estado_id ? 'Estado' : r.bloco_id ? 'Bloco' : r.regiao_id ? 'Região' : r.igreja_id ? 'Igreja' : '—'}</div>
							</div>
							<div class="flex items-center gap-2">
								<Button on:click={() => editRole(r)} size="sm">Editar</Button>
								<Button variant="outline" on:click={() => deleteRole(r.id)} size="sm">Excluir</Button>
							</div>
						</div>
					{/each}
				</div>
			{/if}
		</Card>

		<!-- Formulário de criação/edição -->
		<Card padding="p-4">
			<h2 class="font-semibold mb-3">{editing ? 'Editar papel' : 'Novo papel'}</h2>
			<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
				<!-- Papel -->
				<div>
					<label class="block text-sm font-medium mb-1">Papel</label>
					<select class="w-full px-3 py-2 border rounded-lg" bind:value={form.role_id}>
						<option value="">— selecione —</option>
						{#each roles as r}
							<option value={r.id}>{r.nome}</option>
						{/each}
					</select>
				</div>
				<!-- Estado -->
				<div>
					<label class="block text-sm font-medium mb-1">Estado</label>
					<select class="w-full px-3 py-2 border rounded-lg" bind:value={form.estado_id} on:change={() => loadBlocos(form.estado_id)}>
						<option value="">— sem estado —</option>
						{#each $estados as e}
							<option value={e.id}>{e.nome}</option>
						{/each}
					</select>
				</div>
				<!-- Bloco -->
				<div>
					<label class="block text-sm font-medium mb-1">Bloco</label>
					<select class="w-full px-3 py-2 border rounded-lg" bind:value={form.bloco_id} on:change={() => loadRegioes(form.bloco_id)} disabled={!form.estado_id}>
						<option value="">— sem bloco —</option>
						{#each $blocos as b}
							<option value={b.id}>{b.nome}</option>
						{/each}
					</select>
				</div>
				<!-- Região -->
				<div>
					<label class="block text-sm font-medium mb-1">Região</label>
					<select class="w-full px-3 py-2 border rounded-lg" bind:value={form.regiao_id} on:change={() => loadIgrejas(form.regiao_id)} disabled={!form.bloco_id}>
						<option value="">— sem região —</option>
						{#each $regioes as r}
							<option value={r.id}>{r.nome}</option>
						{/each}
					</select>
				</div>
				<!-- Igreja -->
				<div>
					<label class="block text-sm font-medium mb-1">Igreja</label>
					<select class="w-full px-3 py-2 border rounded-lg" bind:value={form.igreja_id} disabled={!form.regiao_id}>
						<option value="">— sem igreja —</option>
						{#each $igrejas as i}
							<option value={i.id}>{i.nome}</option>
						{/each}
					</select>
				</div>
			</div>
			<div class="mt-4 flex items-center gap-2">
				<Button on:click={saveForm}>{editing ? 'Salvar alterações' : 'Adicionar papel'}</Button>
				<Button variant="outline" on:click={resetForm}>Cancelar</Button>
				{#if error}
					<span class="text-sm text-red-600">{error}</span>
				{/if}
			</div>
		</Card>

		<!-- Transferência de liderança -->
		<Card padding="p-4">
			<h2 class="font-semibold mb-3">Transferir liderança</h2>
			<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
				<div>
					<label class="block text-sm font-medium mb-1">Origem</label>
					<select class="w-full px-3 py-2 border rounded-lg" bind:value={transfer.from_user_id}>
						<option value="">— usuário origem —</option>
						{#each users as u}
							<option value={u.id}>{u.nome}</option>
						{/each}
					</select>
				</div>
				<div>
					<label class="block text-sm font-medium mb-1">Destino</label>
					<select class="w-full px-3 py-2 border rounded-lg" bind:value={transfer.to_user_id}>
						<option value="">— usuário destino —</option>
						{#each users as u}
							<option value={u.id}>{u.nome}</option>
						{/each}
					</select>
				</div>
				<div>
					<label class="block text-sm font-medium mb-1">Papel</label>
					<select class="w-full px-3 py-2 border rounded-lg" bind:value={transfer.role_id}>
						<option value="">— papel de liderança —</option>
						{#each roles.filter(r=>leaderRoleSlugs.includes(r.slug)) as r}
							<option value={r.id}>{r.nome}</option>
						{/each}
					</select>
				</div>
				<div>
					<label class="block text-sm font-medium mb-1">Estado</label>
					<select class="w-full px-3 py-2 border rounded-lg" bind:value={transfer.estado_id} on:change={() => loadBlocos(transfer.estado_id)}>
						<option value="">— sem estado —</option>
						{#each $estados as e}
							<option value={e.id}>{e.nome}</option>
						{/each}
					</select>
				</div>
				<div>
					<label class="block text-sm font-medium mb-1">Bloco</label>
					<select class="w-full px-3 py-2 border rounded-lg" bind:value={transfer.bloco_id} on:change={() => loadRegioes(transfer.bloco_id)} disabled={!transfer.estado_id}>
						<option value="">— sem bloco —</option>
						{#each $blocos as b}
							<option value={b.id}>{b.nome}</option>
						{/each}
					</select>
				</div>
				<div>
					<label class="block text-sm font-medium mb-1">Região</label>
					<select class="w-full px-3 py-2 border rounded-lg" bind:value={transfer.regiao_id} on:change={() => loadIgrejas(transfer.regiao_id)} disabled={!transfer.bloco_id}>
						<option value="">— sem região —</option>
						{#each $regioes as r}
							<option value={r.id}>{r.nome}</option>
						{/each}
					</select>
				</div>
				<div>
					<label class="block text-sm font-medium mb-1">Igreja</label>
					<select class="w-full px-3 py-2 border rounded-lg" bind:value={transfer.igreja_id} disabled={!transfer.regiao_id}>
						<option value="">— sem igreja —</option>
						{#each $igrejas as i}
							<option value={i.id}>{i.nome}</option>
						{/each}
					</select>
				</div>
			</div>
			<div class="mt-4 flex items-center gap-2">
				<Button on:click={transferLeadership}>Transferir</Button>
				{#if error}
					<span class="text-sm text-red-600">{error}</span>
				{/if}
			</div>
		</Card>
	{/if}
</div>

<style>
	.fb-card { background: white; border: 1px solid #e5e7eb; border-radius: 0.75rem; }
</style>
