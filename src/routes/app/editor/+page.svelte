<script>
  import { supabase } from '$lib/supabase';
  import { goto } from '$app/navigation';
  import { page } from '$app/stores';
  import { onMount } from 'svelte';
  import { get } from 'svelte/store';

  const AUTOSAVE_DELAY_MS = 2500;

  /** @typedef {{ desc: string, price: number, qty: number, imageUrl?: string }} LineItem */

  let clientName = $state("");
  let taxRate = $state(21);
  let invoiceId = $state(/** @type {string | null} */ (null));
  let isEditing = $state(false);
  let invoiceStatus = $state(/** @type {'draft' | 'sent'} */ ('draft'));
  let template = $state('classic');
  let coverImageUrl = $state('');
  let isPro = $state(false);
  let profile = $state({
    business_name: "",
    tax_id: "",
    address: "",
    logo_url: ""
  });
  let showWatermark = $state(true);
  let items = $state(/** @type {LineItem[]} */ ([
    { desc: "", price: 0, qty: 1, imageUrl: "" }
  ]));
  let sectionOrder = $state(/** @type {string[]} */ (['header', 'client', 'items', 'totals', 'footer']));
  
  let saving = $state(false);
  let saveStatus = $state(/** @type {'' | 'saving' | 'saved' | 'error'} */ (''));
  let autosaveTimer = /** @type {ReturnType<typeof setTimeout> | null} */ (null);
  let user = $state(/** @type {import('@supabase/supabase-js').User | null} */ (null));

  // --- CÁLCULOS REACTIVOS ---
  const subtotal = () => items.reduce((sum, item) => sum + (item.price * item.qty), 0);
  const total = () => subtotal() + (subtotal() * (taxRate / 100));

  const templates = [
    { id: 'classic', name: 'Clásica', proOnly: false },
    { id: 'modern', name: 'Moderna', proOnly: false },
    { id: 'minimal', name: 'Minimal', proOnly: false },
    { id: 'signature', name: 'Signature', proOnly: true },
    { id: 'executive', name: 'Executive', proOnly: true }
  ];

  const templateClass = () => {
    if (template === 'modern') return 'border-blue-100';
    if (template === 'minimal') return 'border-slate-100';
    if (template === 'signature') return 'border-emerald-100';
    if (template === 'executive') return 'border-violet-100';
    return 'border-slate-200';
  };

  onMount(async () => {
    const { data } = await supabase.auth.getUser();
    user = data.user;
    if (!user) {
      goto('/?auth=required');
      return;
    }

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

    if (typeof localStorage !== 'undefined') {
      isPro = localStorage.getItem('facturasgen_pro') === 'true';
      showWatermark = !isPro;
    }

    const { url } = get(page);
    const id = url.searchParams.get('id');
    if (id) {
      invoiceId = id;
      isEditing = true;
      await loadInvoice(id);
    }
  });

  $effect(() => {
    if (!invoiceId || invoiceStatus === 'sent') return;
    const _ = [clientName, items, taxRate];
    scheduleAutosave();
  });

  // --- FUNCIONES DE LA TABLA ---
  function addItem() {
    items.push({ desc: "", price: 0, qty: 1, imageUrl: "" });
  }

  /** @param {number} index */
  function removeItem(index) {
    items = items.filter((_, i) => i !== index);
  }

  // --- GENERACIÓN DE PDF (lazy load para no cargar en dashboard) ---
  async function downloadPDF() {
    const element = document.getElementById('invoice-canvas');
    if (!element) return;
    const html2pdf = (await import('html2pdf.js')).default;
    /** @type {[number, number, number, number]} */
    const margin = [0.5, 0.5, 0.5, 0.5];
    /** @type {'jpeg'} */
    const imageType = 'jpeg';
    /** @type {'portrait'} */
    const orientation = 'portrait';
    /** @type {'letter'} */
    const format = 'letter';
    /** @type {'in'} */
    const unit = 'in';
    const opt = {
      margin,
      filename:     `Factura_${clientName.replace(/\s+/g, '_') || 'SaaS'}.pdf`,
      image:        { type: imageType, quality: 0.98 },
      html2canvas:  { scale: 2, useCORS: true },
      jsPDF:        { unit, format, orientation }
    };

    html2pdf().set(opt).from(element).save();
  }

  // --- GUARDADO EN BD ---
  async function saveDraft() {
    await persistInvoice('draft');
  }

  async function emitInvoice() {
    if (!clientName.trim()) {
      alert("Escribe el nombre del cliente antes de emitir.");
      return;
    }
    await persistInvoice('sent');
  }

  /** @param {'draft' | 'sent'} status */
  async function persistInvoice(status) {
    try {
      saving = true;
      saveStatus = 'saving';
      const { data: { user: currentUser } } = await supabase.auth.getUser();

      if (!currentUser) {
        goto('/?auth=required');
        return;
      }

      const payload = {
        user_id: currentUser.id,
        client_name: clientName.trim() || 'Sin nombre',
        line_items: items,
        tax_rate: taxRate,
        status,
        template,
        cover_image_url: coverImageUrl || null,
        section_order: sectionOrder
      };

      const result = isEditing
        ? await supabase
            .from('invoices')
            .update(payload)
            .eq('id', invoiceId)
            .eq('user_id', currentUser.id)
        : await supabase.from('invoices').insert(payload).select('id').single();

      if (result.error) throw result.error;
      invoiceStatus = status;
      saveStatus = 'saved';
      if (!isEditing && result.data?.id) {
        invoiceId = result.data.id;
        isEditing = true;
      }
      setTimeout(() => { saveStatus = ''; }, 2500);
      if (status === 'sent') {
        goto('/app/dashboard');
      }
    } catch (err) {
      const error = /** @type {Error} */ (err);
      saveStatus = 'error';
      alert("Error: " + error.message);
    } finally {
      saving = false;
    }
  }

  // --- AUTOSAVE (borrador) ---
  function scheduleAutosave() {
    if (autosaveTimer) clearTimeout(autosaveTimer);
    if (invoiceStatus === 'sent') return;
    autosaveTimer = setTimeout(async () => {
      autosaveTimer = null;
      if (!user || !invoiceId || saving) return;
      await persistInvoice('draft');
    }, AUTOSAVE_DELAY_MS);
  }

  /** @param {string} id */
  async function loadInvoice(id) {
    const { data: { user: currentUser } } = await supabase.auth.getUser();
    if (!currentUser) {
      goto('/?auth=required');
      return;
    }

    const { data, error } = await supabase
      .from('invoices')
      .select('client_name, line_items, tax_rate, template, cover_image_url, section_order, status')
      .eq('id', id)
      .eq('user_id', currentUser.id)
      .maybeSingle();

    if (error || !data) {
      alert("No se pudo cargar la factura");
      goto('/app/dashboard');
      return;
    }

    clientName = data.client_name ?? '';
    items = Array.isArray(data.line_items) && data.line_items.length > 0
      ? data.line_items.map((item) => ({ ...item, imageUrl: item.imageUrl ?? "" }))
      : [{ desc: "", price: 0, qty: 1, imageUrl: "" }];
    taxRate = data.tax_rate ?? 21;
    template = data.template ?? 'classic';
    coverImageUrl = data.cover_image_url ?? '';
    sectionOrder = Array.isArray(data.section_order) && data.section_order.length > 0
      ? data.section_order
      : ['header', 'client', 'items', 'totals', 'footer'];
    invoiceStatus = (data.status === 'sent' ? 'sent' : 'draft');
  }

  /** @param {string} value */
  function handleTemplateChange(value) {
    const selected = templates.find((item) => item.id === value);
    if (selected?.proOnly && !isPro) {
      template = 'classic';
      alert('Esta plantilla es Pro. Actualiza tu plan para acceder.');
      return;
    }
    template = value;
  }

  /** @param {number} index @param {number} direction */
  function moveSection(index, direction) {
    const nextIndex = index + direction;
    if (nextIndex < 0 || nextIndex >= sectionOrder.length) return;
    const updated = [...sectionOrder];
    const [current] = updated.splice(index, 1);
    updated.splice(nextIndex, 0, current);
    sectionOrder = updated;
  }
</script>

<div class="space-y-6">
  <div class="flex flex-wrap items-center justify-between gap-4">
    <div>
      <h1 class="text-3xl font-semibold text-slate-900">Editor de factura</h1>
      <p class="text-sm text-slate-500">
        {isEditing ? 'Estás editando una factura guardada.' : 'Crea una factura clara y lista para enviar.'}
      </p>
    </div>
    <div class="flex flex-wrap items-center gap-3">
      {#if saveStatus === 'saving'}
        <span class="text-sm text-slate-500">Guardando...</span>
      {:else if saveStatus === 'saved'}
        <span class="text-sm text-emerald-600">Guardado</span>
      {:else if saveStatus === 'error'}
        <span class="text-sm text-red-600">Error al guardar</span>
      {/if}
      <button
        onclick={downloadPDF}
        class="rounded-full border border-slate-200 bg-white px-5 py-2 text-sm font-semibold text-slate-700 hover:border-slate-300 hover:text-slate-900 transition"
      >
        Descargar PDF
      </button>
      <button
        onclick={saveDraft}
        disabled={saving || !user}
        class="rounded-full border border-slate-200 bg-white px-5 py-2 text-sm font-semibold text-slate-700 hover:border-slate-300 disabled:opacity-50 transition"
      >
        {saving ? 'Guardando...' : 'Guardar borrador'}
      </button>
      <button
        onclick={emitInvoice}
        disabled={saving || !user}
        class="rounded-full bg-blue-600 px-5 py-2 text-sm font-semibold text-white hover:bg-blue-700 disabled:opacity-50 transition"
      >
        Emitir factura
      </button>
    </div>
  </div>

  {#if isEditing && invoiceStatus === 'sent'}
    <div class="mb-6 rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
      Estás editando una factura ya emitida. Los cambios pueden afectar a la trazabilidad; usa solo para correcciones puntuales.
    </div>
  {/if}

  <div class="grid gap-6 lg:grid-cols-[320px_1fr]">
    <aside class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm space-y-6">
      <div>
        <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">Plantilla</p>
        <select
          value={template}
          onchange={(event) => handleTemplateChange(event.currentTarget.value)}
          class="mt-2 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm"
        >
          {#each templates as option}
            <option value={option.id}>
              {option.name}{option.proOnly ? ' (Pro)' : ''}
            </option>
          {/each}
        </select>
        <p class="mt-2 text-xs text-slate-400">Las plantillas Pro desbloquean estilos premium.</p>
      </div>

      <div>
        <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">Imagen de portada</p>
        <input
          type="url"
          bind:value={coverImageUrl}
          placeholder="https://"
          class="mt-2 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm"
        />
        <p class="mt-2 text-xs text-slate-400">Se mostrará en la parte superior. Recomendamos subir a tu propio hosting; URLs externas pueden fallar al generar el PDF (CORS).</p>
      </div>

      <div>
        <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">Orden de secciones</p>
        <div class="mt-3 space-y-2">
          {#each sectionOrder as section, index}
            <div class="flex items-center justify-between rounded-xl border border-slate-200 bg-slate-50 px-3 py-2 text-xs text-slate-600">
              <span class="font-semibold text-slate-700">
                {section === 'header' ? 'Encabezado' : ''}
                {section === 'client' ? 'Cliente' : ''}
                {section === 'items' ? 'Conceptos' : ''}
                {section === 'totals' ? 'Totales' : ''}
                {section === 'footer' ? 'Pie' : ''}
              </span>
              <div class="flex gap-2">
                <button
                  type="button"
                  onclick={() => moveSection(index, -1)}
                  class="rounded-lg border border-slate-200 bg-white px-2 py-1 text-[10px] font-semibold text-slate-500 hover:text-slate-700"
                >
                  Subir
                </button>
                <button
                  type="button"
                  onclick={() => moveSection(index, 1)}
                  class="rounded-lg border border-slate-200 bg-white px-2 py-1 text-[10px] font-semibold text-slate-500 hover:text-slate-700"
                >
                  Bajar
                </button>
              </div>
            </div>
          {/each}
        </div>
      </div>

      <div class="rounded-2xl border border-slate-200 bg-slate-50 p-4 text-xs text-slate-500">
        <p class="font-semibold text-slate-700">Personalización avanzada</p>
        <p class="mt-2">Activa Pro para acceder a más plantillas y branding completo.</p>
        <a href="/pricing" class="mt-3 inline-flex text-xs font-semibold text-blue-600 hover:text-blue-700">Ver plan Pro</a>
      </div>
    </aside>

    <div
      id="invoice-canvas"
      class={`relative mx-auto w-[800px] max-w-full rounded-3xl border ${templateClass()} bg-white p-12 shadow-xl`}
    >
      {#if showWatermark}
        <div class="pointer-events-none absolute inset-0 overflow-hidden rounded-3xl">
          <div class="absolute inset-0 flex items-center justify-center opacity-10">
            <div class="grid grid-cols-2 gap-10 text-[36px] font-semibold uppercase tracking-[0.35em] text-slate-400">
              <span>FACTURASGEN</span><span>FACTURASGEN</span>
              <span>FACTURASGEN</span><span>FACTURASGEN</span>
              <span>FACTURASGEN</span><span>FACTURASGEN</span>
              <span>FACTURASGEN</span><span>FACTURASGEN</span>
            </div>
          </div>
        </div>
      {/if}

      <div class="relative space-y-10">
        {#each sectionOrder as section}
          {#if section === 'header'}
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

            {#if coverImageUrl}
              <div class="mt-6 overflow-hidden rounded-2xl border border-slate-100">
                <img src={coverImageUrl} alt="Portada" class="h-40 w-full object-cover" />
              </div>
            {/if}
          {/if}

          {#if section === 'client'}
            <div>
              <label class="block text-xs font-semibold uppercase tracking-[0.2em] text-slate-400 mb-3" for="client-name">Cliente</label>
              <input
                type="text"
                id="client-name"
                bind:value={clientName}
                placeholder="Nombre del cliente o empresa"
                class="w-full border-b border-slate-200 pb-3 text-2xl font-semibold text-slate-900 outline-none focus:border-blue-500 transition"
              />
            </div>
          {/if}

          {#if section === 'items'}
            <div>
              <div class="grid grid-cols-12 gap-4 border-b border-slate-100 pb-3 text-[11px] font-semibold uppercase tracking-[0.2em] text-slate-400">
                <div class="col-span-6">Concepto</div>
                <div class="col-span-2 text-right">Cant.</div>
                <div class="col-span-2 text-right">Precio</div>
                <div class="col-span-2 text-right">Total</div>
              </div>

              {#each items as item, i}
                <div class="grid grid-cols-12 items-start gap-4 border-b border-slate-50 py-3 hover:bg-slate-50/60 transition">
                  <div class="col-span-6 space-y-2">
                    <input
                      type="text"
                      bind:value={item.desc}
                      placeholder="Ej. Consultoría mensual"
                      class="w-full bg-transparent text-sm font-medium text-slate-700 outline-none"
                    />
                    <input
                      type="url"
                      bind:value={item.imageUrl}
                      placeholder="Imagen opcional (URL)"
                      class="w-full rounded-lg border border-slate-200 px-2 py-1 text-xs text-slate-500"
                    />
                    {#if item.imageUrl}
                      <img src={item.imageUrl} alt="Imagen del concepto" class="h-16 w-24 rounded-lg object-cover border border-slate-100" />
                    {/if}
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
                    <button onclick={() => removeItem(i)} class="text-slate-300 hover:text-red-500 transition">Eliminar</button>
                  </div>
                </div>
              {/each}

              <button onclick={addItem} class="mt-5 inline-flex items-center gap-2 text-sm font-semibold text-blue-600 hover:text-blue-700">
                Añadir concepto
              </button>
            </div>
          {/if}

          {#if section === 'totals'}
            <div class="flex justify-end border-t border-slate-200 pt-8">
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
          {/if}

          {#if section === 'footer'}
            <div class="border-t border-slate-100 pt-4 text-xs text-slate-400">
              Gracias por su confianza. Este documento es una factura válida generada mediante FacturasGen.
            </div>
          {/if}
        {/each}
      </div>
    </div>
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