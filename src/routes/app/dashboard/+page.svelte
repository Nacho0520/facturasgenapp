<script>
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { supabase } from '$lib/supabase';

  let invoices = $state([]);
  let loading = $state(true);
  let errorMessage = $state('');

  const totalRevenue = () =>
    invoices.reduce((sum, invoice) => sum + calculateTotal(invoice), 0);

  const draftCount = () =>
    invoices.filter((invoice) => (invoice.status ?? 'draft') === 'draft').length;

  const formatDate = (value) => {
    if (!value) return '-';
    const date = new Date(value);
    return Number.isNaN(date.getTime()) ? '-' : date.toLocaleDateString();
  };

  const calculateTotal = (invoice) => {
    const items = invoice.line_items ?? [];
    const subtotal = items.reduce((sum, item) => sum + (item.price * item.qty), 0);
    const taxRate = invoice.tax_rate ?? 0;
    return subtotal * (1 + taxRate / 100);
  };

  onMount(async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Sesión expirada. Inicia sesión de nuevo.');

      const { data, error } = await supabase
        .from('invoices')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', { ascending: false });

      if (error) throw error;
      invoices = data ?? [];
    } catch (error) {
      errorMessage = error.message ?? 'Error al cargar las facturas.';
    } finally {
      loading = false;
    }
  });
</script>

<div class="space-y-8">
  <div class="flex flex-wrap items-center justify-between gap-4">
    <div>
      <h2 class="text-3xl font-semibold text-slate-900">Dashboard</h2>
      <p class="text-sm text-slate-500">Resumen operativo de tu facturación.</p>
    </div>
    <a href="/app/editor" class="inline-flex items-center gap-2 rounded-full bg-blue-600 px-5 py-2.5 text-sm font-semibold text-white hover:bg-blue-700">
      + Nueva factura
    </a>
  </div>

  <div class="grid gap-4 md:grid-cols-3">
    <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
      <p class="text-xs text-slate-400">Facturas emitidas</p>
      <p class="mt-2 text-2xl font-semibold text-slate-900">{invoices.length}</p>
    </div>
    <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
      <p class="text-xs text-slate-400">Facturas en borrador</p>
      <p class="mt-2 text-2xl font-semibold text-slate-900">{draftCount()}</p>
    </div>
    <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
      <p class="text-xs text-slate-400">Ingresos estimados</p>
      <p class="mt-2 text-2xl font-semibold text-blue-600">{totalRevenue().toFixed(2)} €</p>
    </div>
  </div>

  {#if loading}
    <div class="rounded-2xl border border-slate-200 bg-white p-10 text-center text-slate-400">
      Cargando facturas...
    </div>
  {:else if errorMessage}
    <div class="rounded-2xl border border-red-100 bg-red-50 p-6 text-sm text-red-600">
      {errorMessage}
    </div>
  {:else if invoices.length === 0}
    <div class="rounded-2xl border border-slate-200 bg-white p-10 text-center">
      <div class="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-blue-50 text-xl">📄</div>
      <h3 class="text-lg font-semibold text-slate-900">Aún no tienes facturas</h3>
      <p class="mt-2 text-sm text-slate-500">Crea la primera factura para empezar a registrar ingresos.</p>
      <a href="/app/editor" class="mt-6 inline-flex items-center gap-2 text-sm font-semibold text-blue-600 hover:text-blue-700">
        Empezar ahora →
      </a>
    </div>
  {:else}
    <div class="rounded-2xl border border-slate-200 bg-white shadow-sm">
      <div class="flex items-center justify-between border-b border-slate-100 px-6 py-4">
        <h3 class="text-sm font-semibold text-slate-700">Últimas facturas</h3>
        <span class="text-xs text-slate-400">Actualizado hoy</span>
      </div>
      <div class="overflow-x-auto">
        <table class="w-full text-left text-sm">
          <thead class="bg-slate-50 text-xs uppercase text-slate-500">
            <tr>
              <th class="px-6 py-4">Nº</th>
              <th class="px-6 py-4">Cliente</th>
              <th class="px-6 py-4">Fecha</th>
              <th class="px-6 py-4 text-right">Total</th>
              <th class="px-6 py-4 text-center">Estado</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-100">
            {#each invoices as invoice}
              <tr class="cursor-pointer hover:bg-slate-50 transition" onclick={() => goto(`/app/editor?id=${invoice.id}`)}>
                <td class="px-6 py-4 font-semibold text-slate-800">{invoice.number ?? '-'}</td>
                <td class="px-6 py-4 text-slate-600">{invoice.client_name || 'Sin nombre'}</td>
                <td class="px-6 py-4 text-slate-500">{formatDate(invoice.created_at)}</td>
                <td class="px-6 py-4 text-right font-semibold text-slate-900">{calculateTotal(invoice).toFixed(2)} €</td>
                <td class="px-6 py-4 text-center">
                  <span class="rounded-full bg-emerald-50 px-3 py-1 text-xs font-semibold text-emerald-700">
                    {invoice.status ?? 'draft'}
                  </span>
                </td>
              </tr>
            {/each}
          </tbody>
        </table>
      </div>
    </div>
  {/if}
</div>