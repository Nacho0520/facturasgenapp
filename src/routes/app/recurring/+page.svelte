<script>
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { supabase } from '$lib/supabase';

  /** @typedef {{ id: string, client_name?: string, frequency?: string, next_run_at?: string, last_run_at?: string, created_at?: string }} Recurring */

  let list = $state(/** @type {Recurring[]} */ ([]));
  let loading = $state(true);
  let error = $state('');
  let showForm = $state(false);
  let saving = $state(false);
  let form = $state({
    client_name: '',
    frequency: 'monthly',
    next_run_at: ''
  });

  const frequencyLabels = { monthly: 'Mensual', quarterly: 'Trimestral', yearly: 'Anual' };

  /** @param {string} d */
  const formatDate = (d) => (d ? new Date(d).toLocaleDateString() : '—');

  async function load() {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        goto('/?auth=required');
        return;
      }
      const { data, error: err } = await supabase
        .from('recurring_invoices')
        .select('id, client_name, frequency, next_run_at, last_run_at, created_at')
        .eq('user_id', user.id)
        .order('next_run_at', { ascending: true });
      if (err) throw err;
      list = data ?? [];
    } catch (e) {
      const err = /** @type {Error} */ (e);
      error = err.message ?? 'Error al cargar';
    } finally {
      loading = false;
    }
  }

  async function createRecurring() {
    try {
      saving = true;
      error = '';
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;
      const nextRun = form.next_run_at || new Date().toISOString().slice(0, 10);
      const { error: err } = await supabase.from('recurring_invoices').insert({
        user_id: user.id,
        client_name: form.client_name || null,
        frequency: form.frequency,
        next_run_at: nextRun,
        line_items: [],
        tax_rate: 21
      });
      if (err) throw err;
      showForm = false;
      form = { client_name: '', frequency: 'monthly', next_run_at: nextRun };
      await load();
    } catch (e) {
      const err = /** @type {Error} */ (e);
      error = err.message ?? 'Error al crear';
    } finally {
      saving = false;
    }
  }

  onMount(load);
</script>

<div class="space-y-8">
  <div class="flex flex-wrap items-center justify-between gap-4">
    <div>
      <h2 class="text-3xl font-semibold text-slate-900">Facturas recurrentes</h2>
      <p class="text-sm text-slate-500">Series mensuales, trimestrales o anuales (Pro).</p>
    </div>
    <button
      type="button"
      onclick={() => { showForm = !showForm; error = ''; }}
      class="inline-flex items-center gap-2 rounded-full bg-blue-600 px-5 py-2.5 text-sm font-semibold text-white hover:bg-blue-700"
    >
      {showForm ? 'Cerrar' : '+ Crear serie'}
    </button>
  </div>

  {#if showForm}
    <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
      <h3 class="text-sm font-semibold text-slate-700 mb-4">Nueva serie recurrente</h3>
      <form class="space-y-4" onsubmit={(e) => { e.preventDefault(); createRecurring(); }}>
        <div>
          <label for="recurring-client" class="block text-xs font-medium text-slate-500 mb-1">Cliente</label>
          <input id="recurring-client" type="text" bind:value={form.client_name} placeholder="Nombre del cliente" class="w-full rounded-xl border border-slate-200 px-3 py-2 text-sm" />
        </div>
        <div>
          <label for="recurring-freq" class="block text-xs font-medium text-slate-500 mb-1">Frecuencia</label>
          <select id="recurring-freq" bind:value={form.frequency} class="w-full rounded-xl border border-slate-200 px-3 py-2 text-sm">
            <option value="monthly">Mensual</option>
            <option value="quarterly">Trimestral</option>
            <option value="yearly">Anual</option>
          </select>
        </div>
        <div>
          <label for="recurring-next" class="block text-xs font-medium text-slate-500 mb-1">Próxima ejecución</label>
          <input id="recurring-next" type="date" bind:value={form.next_run_at} class="w-full rounded-xl border border-slate-200 px-3 py-2 text-sm" />
        </div>
        <button type="submit" disabled={saving} class="rounded-full bg-blue-600 px-5 py-2 text-sm font-semibold text-white hover:bg-blue-700 disabled:opacity-50">
          {saving ? 'Guardando...' : 'Crear serie'}
        </button>
      </form>
    </div>
  {/if}

  {#if error}
    <div class="rounded-2xl border border-red-100 bg-red-50 p-4 text-sm text-red-600">{error}</div>
  {/if}

  {#if loading}
    <div class="rounded-2xl border border-slate-200 bg-white p-10 text-center text-slate-400">Cargando...</div>
  {:else if list.length === 0}
    <div class="rounded-2xl border border-slate-200 bg-white p-10 text-center">
      <p class="text-slate-500">Aún no tienes facturas recurrentes.</p>
      <p class="mt-2 text-xs text-slate-400">Crea una serie para autogenerar borradores (Pro).</p>
    </div>
  {:else}
    <div class="rounded-2xl border border-slate-200 bg-white shadow-sm overflow-hidden">
      <table class="w-full text-left text-sm">
        <thead class="bg-slate-50 text-xs uppercase text-slate-500">
          <tr>
            <th class="px-6 py-4">Cliente</th>
            <th class="px-6 py-4">Frecuencia</th>
            <th class="px-6 py-4">Próxima</th>
            <th class="px-6 py-4">Última</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-slate-100">
          {#each list as row}
            <tr class="hover:bg-slate-50">
              <td class="px-6 py-4 font-medium text-slate-800">{row.client_name || '—'}</td>
              <td class="px-6 py-4 text-slate-600">{frequencyLabels[row.frequency ?? 'monthly'] ?? row.frequency}</td>
              <td class="px-6 py-4 text-slate-600">{formatDate(row.next_run_at)}</td>
              <td class="px-6 py-4 text-slate-500">{formatDate(row.last_run_at)}</td>
            </tr>
          {/each}
        </tbody>
      </table>
    </div>
  {/if}
</div>
