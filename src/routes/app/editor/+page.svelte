<script>
  import { supabase } from '$lib/supabase';
  import { goto } from '$app/navigation';
  import { page } from '$app/stores';
  import { onMount } from 'svelte';
  import html2pdf from 'html2pdf.js'; // Asegúrate de haber hecho: npm install html2pdf.js
  import { get } from 'svelte/store';

  // --- ESTADOS (Svelte 5) ---
  let clientName = $state("");
  let taxRate = $state(21);
  let invoiceId = $state(null);
  let isEditing = $state(false);
  let profile = $state({
    business_name: "",
    tax_id: "",
    address: "",
    logo_url: ""
  });
  let showWatermark = $state(true);
  let items = $state([
    { desc: "", price: 0, qty: 1 }
  ]);
  
  let saving = $state(false);
  let user = $state(null);

  // --- CÁLCULOS REACTIVOS ---
  const subtotal = () => items.reduce((sum, item) => sum + (item.price * item.qty), 0);
  const total = () => subtotal() + (subtotal() * (taxRate / 100));

  onMount(async () => {
    const { data } = await supabase.auth.getUser();
    user = data.user;

    if (user) {
      const { data: profileData } = await supabase
        .from('profiles')
        .select('business_name, tax_id, address, logo_url')
        .eq('id', user.id)
        .maybeSingle();

      if (profileData) {
        profile = {
          business_name: profileData.business_name ?? "",
          tax_id: profileData.tax_id ?? "",
          address: profileData.address ?? "",
          logo_url: profileData.logo_url ?? ""
        };
      }
    }

    if (typeof localStorage !== 'undefined') {
      showWatermark = localStorage.getItem('facturasgen_pro') !== 'true';
    }

    const { url } = get(page);
    const id = url.searchParams.get('id');
    if (id) {
      invoiceId = id;
      isEditing = true;
      await loadInvoice(id);
    }
  });

  // --- FUNCIONES DE LA TABLA ---
  function addItem() {
    items.push({ desc: "", price: 0, qty: 1 });
  }

  function removeItem(index) {
    items = items.filter((_, i) => i !== index);
  }

  // --- GENERACIÓN DE PDF ---
  function downloadPDF() {
    const element = document.getElementById('invoice-canvas');
    const opt = {
      margin:       [0.5, 0.5],
      filename:     `Factura_${clientName.replace(/\s+/g, '_') || 'SaaS'}.pdf`,
      image:        { type: 'jpeg', quality: 0.98 },
      html2canvas:  { scale: 2, useCORS: true },
      jsPDF:        { unit: 'in', format: 'letter', orientation: 'portrait' }
    };

    html2pdf().set(opt).from(element).save();
  }

  // --- GUARDADO EN BD ---
  async function saveInvoice() {
    if (!clientName) return alert("Por favor, escribe el nombre del cliente");

    try {
      saving = true;
      const { data: { user: currentUser } } = await supabase.auth.getUser();
      
      if (!currentUser) throw new Error("Sesión expirada. Inicia sesión de nuevo.");

      const payload = {
        user_id: currentUser.id,
        client_name: clientName,
        line_items: items,
        tax_rate: taxRate,
        status: 'sent'
      };

      const { error } = isEditing
        ? await supabase
            .from('invoices')
            .update(payload)
            .eq('id', invoiceId)
            .eq('user_id', currentUser.id)
        : await supabase.from('invoices').insert(payload);

      if (error) throw error;
      alert(isEditing ? "¡Factura actualizada correctamente!" : "¡Factura guardada correctamente!");
      goto('/app/dashboard');
    } catch (err) {
      alert("Error: " + err.message);
    } finally {
      saving = false;
    }
  }

  async function loadInvoice(id) {
    const { data: { user: currentUser } } = await supabase.auth.getUser();
    if (!currentUser) return;

    const { data, error } = await supabase
      .from('invoices')
      .select('client_name, line_items, tax_rate')
      .eq('id', id)
      .eq('user_id', currentUser.id)
      .maybeSingle();

    if (error || !data) {
      alert("No se pudo cargar la factura");
      goto('/app/dashboard');
      return;
    }

    clientName = data.client_name ?? '';
    items = Array.isArray(data.line_items) && data.line_items.length > 0 ? data.line_items : [{ desc: "", price: 0, qty: 1 }];
    taxRate = data.tax_rate ?? 21;
  }
</script>

<div class="space-y-6">
  <div class="flex flex-wrap items-center justify-between gap-4">
    <div>
      <h1 class="text-3xl font-semibold text-slate-900">Editor de factura</h1>
      <p class="text-sm text-slate-500">Crea una factura clara y lista para enviar.</p>
    </div>
    <div class="flex flex-wrap gap-3">
      <button
        onclick={downloadPDF}
        class="rounded-full border border-slate-200 bg-white px-5 py-2 text-sm font-semibold text-slate-700 hover:border-slate-300 hover:text-slate-900 transition"
      >
        📄 Descargar PDF
      </button>

      <button
        onclick={saveInvoice}
        disabled={saving || !user}
        class="rounded-full bg-blue-600 px-5 py-2 text-sm font-semibold text-white hover:bg-blue-700 disabled:opacity-50 transition"
      >
        {saving ? 'Guardando...' : (isEditing ? 'Actualizar factura' : 'Guardar en nube')}
      </button>
    </div>
  </div>

  <div id="invoice-canvas" class="mx-auto w-[800px] max-w-full rounded-3xl border border-slate-200 bg-white p-12 shadow-xl">
    <div class="flex flex-wrap items-start justify-between gap-6">
      <div>
        <p class="text-xs uppercase tracking-[0.3em] text-slate-400">Factura</p>
        <h2 class="mt-2 text-4xl font-semibold text-slate-900">INV-{Math.floor(Math.random() * 1000)}</h2>
        <div class="mt-6 space-y-1 text-sm text-slate-500">
          {#if profile.business_name}
            <div class="text-slate-900 font-semibold">{profile.business_name}</div>
          {/if}
          {#if profile.tax_id}
            <div>NIF/CIF: {profile.tax_id}</div>
          {/if}
          {#if profile.address}
            <div class="whitespace-pre-line">{profile.address}</div>
          {/if}
        </div>
      </div>
      <div class="text-right">
        {#if profile.logo_url}
          <img src={profile.logo_url} alt="Logo" class="h-14 w-auto object-contain ml-auto mb-2" />
        {:else}
          <div class="inline-flex items-center justify-center rounded-xl bg-slate-900 px-5 py-3 text-xs font-semibold text-white">
            LOGO
          </div>
        {/if}
        <p class="mt-2 text-xs uppercase tracking-[0.3em] text-slate-400">Documento oficial</p>
      </div>
    </div>

    <div class="mt-10">
      <label class="block text-xs font-semibold uppercase tracking-[0.2em] text-slate-400 mb-3">Cliente</label>
      <input
        type="text"
        bind:value={clientName}
        placeholder="Nombre del cliente o empresa"
        class="w-full border-b border-slate-200 pb-3 text-2xl font-semibold text-slate-900 outline-none focus:border-blue-500 transition"
      />
    </div>

    <div class="mt-10">
      <div class="grid grid-cols-12 gap-4 border-b border-slate-100 pb-3 text-[11px] font-semibold uppercase tracking-[0.2em] text-slate-400">
        <div class="col-span-6">Concepto</div>
        <div class="col-span-2 text-right">Cant.</div>
        <div class="col-span-2 text-right">Precio</div>
        <div class="col-span-2 text-right">Total</div>
      </div>

      {#each items as item, i}
        <div class="grid grid-cols-12 items-center gap-4 border-b border-slate-50 py-3 hover:bg-slate-50/60 transition">
          <div class="col-span-6">
            <input
              type="text"
              bind:value={item.desc}
              placeholder="Ej. Consultoría mensual"
              class="w-full bg-transparent text-sm font-medium text-slate-700 outline-none"
            />
          </div>
          <div class="col-span-2 text-right">
            <input type="number" bind:value={item.qty} class="w-full bg-transparent text-right text-sm text-slate-700 outline-none" />
          </div>
          <div class="col-span-2 text-right">
            <input type="number" bind:value={item.price} class="w-full bg-transparent text-right text-sm text-slate-700 outline-none" />
          </div>
          <div class="col-span-1 text-right text-sm font-semibold text-slate-900">
            {(item.price * item.qty).toFixed(2)}€
          </div>
          <div class="col-span-1 text-right">
            <button onclick={() => removeItem(i)} class="text-slate-300 hover:text-red-500 transition">✕</button>
          </div>
        </div>
      {/each}

      <button onclick={addItem} class="mt-5 inline-flex items-center gap-2 text-sm font-semibold text-blue-600 hover:text-blue-700">
        + Añadir concepto
      </button>
    </div>

    <div class="mt-12 flex justify-end border-t border-slate-200 pt-8">
      <div class="w-72 space-y-4 text-sm">
        <div class="flex justify-between text-slate-500">
          <span>Subtotal</span>
          <span class="font-medium text-slate-900">{subtotal().toFixed(2)} €</span>
        </div>
        <div class="flex justify-between items-center text-slate-500">
          <span>IVA ({taxRate}%)</span>
          <div class="flex items-center gap-2">
            <input type="number" bind:value={taxRate} class="w-12 border-b border-slate-200 text-right text-sm outline-none" />
            <span>%</span>
          </div>
        </div>
        <div class="flex justify-between text-xl font-semibold text-slate-900 pt-3">
          <span>Total</span>
          <span class="text-blue-600">{total().toFixed(2)} €</span>
        </div>
      </div>
    </div>

    <div class="mt-14 border-t border-slate-100 pt-4 text-xs text-slate-400">
      Gracias por su confianza. Este documento es una factura válida generada mediante FacturasGen.
    </div>
    {#if showWatermark}
      <div class="mt-4 text-[10px] text-slate-300 text-center uppercase tracking-[0.3em]">
        Generado con FacturasGen
      </div>
    {/if}
  </div>
</div>

<style>
  /* Evitar que los inputs se vean como bordes al imprimir */
  input::-webkit-outer-spin-button,
  input::-webkit-inner-spin-button {
    -webkit-appearance: none;
    margin: 0;
  }
</style>