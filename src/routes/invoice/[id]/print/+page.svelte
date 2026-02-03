<script>
  import { goto } from '$app/navigation';
  import { supabase } from '$lib/supabase';
  import { onMount } from 'svelte';

  /** @typedef {{ desc: string, price: number, qty: number, imageUrl?: string }} LineItem */
  /** @typedef {{ business_name: string, tax_id: string, address: string, logo_url: string }} Profile */
  /** @typedef {{ id: string, number?: number, client_name?: string, line_items?: LineItem[], tax_rate?: number, template?: string, cover_image_url?: string, section_order?: string[] }} Invoice */

  /** @param {{ data: { id?: string, invoice?: Invoice, profile?: Profile, error?: string } }} props */
  let { data } = $props();

  let invoice = $state(/** @type {Invoice | null} */ (null));
  let profile = $state(/** @type {Profile | null} */ (null));
  let loading = $state(true);
  let error = $state('');

  const id = $derived(data?.id ?? '');

  $effect(() => {
    if (data?.invoice) {
      invoice = data.invoice;
      profile = data.profile ?? null;
      loading = false;
      error = '';
    } else if (data?.error) {
      error = data.error;
      loading = false;
    }
  });

  const sectionOrder = () => invoice?.section_order?.length ? invoice.section_order : ['header', 'client', 'items', 'totals', 'footer'];
  const subtotal = () => (invoice?.line_items ?? []).reduce((sum, item) => sum + (item.price * item.qty), 0);
  const taxRate = () => invoice?.tax_rate ?? 0;
  const total = () => subtotal() * (1 + taxRate() / 100);

  onMount(async () => {
    if (data?.invoice) {
      invoice = data.invoice;
      profile = data.profile ?? null;
      loading = false;
      return;
    }
    if (data?.error) {
      error = data.error;
      loading = false;
      return;
    }

    const { data: { user } } = await supabase.auth.getUser();
    if (!user) {
      goto('/?auth=required');
      return;
    }

    const { data: inv, error: errInv } = await supabase
      .from('invoices')
      .select('id, number, client_name, line_items, tax_rate, template, cover_image_url, section_order')
      .eq('id', id)
      .eq('user_id', user.id)
      .maybeSingle();

    if (errInv || !inv) {
      error = 'Factura no encontrada';
      loading = false;
      return;
    }

    invoice = inv;

    const { data: prof } = await supabase
      .from('profiles')
      .select('business_name, tax_id, address, logo_url')
      .eq('id', user.id)
      .maybeSingle();

    profile = prof ?? { business_name: '', tax_id: '', address: '', logo_url: '' };
    loading = false;
  });
</script>

{#if loading}
  <div class="flex min-h-screen items-center justify-center bg-white p-8 text-slate-500">
    Cargando factura...
  </div>
{:else if error}
  <div class="flex min-h-screen items-center justify-center bg-white p-8 text-red-600">
    {error}
  </div>
{:else if invoice}
  <article class="mx-auto min-h-screen max-w-[800px] bg-white p-12 text-slate-900" data-print-only>
    {#each sectionOrder() as section}
      {@const rate = taxRate()}
      {@const p = profile ?? { business_name: '', tax_id: '', address: '', logo_url: '' }}
      {#if section === 'header'}
        <div class="flex flex-wrap items-start justify-between gap-6 border-b border-slate-200 pb-8">
          <div>
            <p class="text-xs uppercase tracking-widest text-slate-400">Factura</p>
            <h1 class="mt-2 text-4xl font-semibold text-slate-900">INV-{invoice.number ?? '—'}</h1>
            <div class="mt-6 space-y-1 text-sm text-slate-500">
              {#if p.business_name}<div class="font-semibold text-slate-900">{p.business_name}</div>{/if}
              {#if p.tax_id}<div>NIF/CIF: {p.tax_id}</div>{/if}
              {#if p.address}<div class="whitespace-pre-line">{p.address}</div>{/if}
            </div>
          </div>
          <div class="text-right">
            {#if p.logo_url}
              <img src={p.logo_url} alt="Logo" class="ml-auto h-14 w-auto object-contain" />
            {:else}
              <div class="inline-flex h-14 items-center justify-center rounded-xl bg-slate-900 px-5 text-xs font-semibold text-white">LOGO</div>
            {/if}
          </div>
        </div>
        {#if invoice.cover_image_url}
          <div class="mt-6 overflow-hidden rounded-2xl border border-slate-100">
            <img src={invoice.cover_image_url} alt="Portada" class="h-40 w-full object-cover" />
          </div>
        {/if}
      {/if}

      {#if section === 'client'}
        <div class="mt-8">
          <p class="text-xs font-semibold uppercase tracking-widest text-slate-400">Cliente</p>
          <p class="mt-2 text-2xl font-semibold text-slate-900">{invoice.client_name || '—'}</p>
        </div>
      {/if}

      {#if section === 'items'}
        <div class="mt-8">
          <table class="w-full text-left text-sm">
            <thead>
              <tr class="border-b border-slate-200 text-xs font-semibold uppercase tracking-widest text-slate-400">
                <th class="pb-3">Concepto</th>
                <th class="pb-3 text-right">Cant.</th>
                <th class="pb-3 text-right">Precio</th>
                <th class="pb-3 text-right">Total</th>
              </tr>
            </thead>
            <tbody>
              {#each (invoice.line_items ?? []) as item}
                <tr class="border-b border-slate-50 py-3">
                  <td class="py-3 font-medium text-slate-700">{item.desc || '—'}</td>
                  <td class="py-3 text-right text-slate-600">{item.qty}</td>
                  <td class="py-3 text-right text-slate-600">{item.price.toFixed(2)} €</td>
                  <td class="py-3 text-right font-semibold text-slate-900">{(item.price * item.qty).toFixed(2)} €</td>
                </tr>
              {/each}
            </tbody>
          </table>
        </div>
      {/if}

      {#if section === 'totals'}
        <div class="mt-8 flex justify-end border-t border-slate-200 pt-8">
          <div class="w-72 space-y-2 text-sm">
            <div class="flex justify-between text-slate-500"><span>Subtotal</span><span class="font-medium text-slate-900">{subtotal().toFixed(2)} €</span></div>
            <div class="flex justify-between text-slate-500"><span>IVA ({rate}%)</span><span class="font-medium text-slate-900">{(subtotal() * rate / 100).toFixed(2)} €</span></div>
            <div class="flex justify-between pt-3 text-xl font-semibold text-slate-900"><span>Total</span><span class="text-blue-600">{total().toFixed(2)} €</span></div>
          </div>
        </div>
      {/if}

      {#if section === 'footer'}
        <div class="mt-12 border-t border-slate-100 pt-4 text-xs text-slate-400">
          Documento generado con FacturasGen. Gracias por su confianza.
        </div>
      {/if}
    {/each}
  </article>
{:else}
  <div class="flex min-h-screen items-center justify-center bg-white p-8 text-slate-500">
    No se pudo cargar la factura.
  </div>
{/if}

<svelte:head>
  <title>Factura {invoice?.number ?? id} - Impresión</title>
</svelte:head>
