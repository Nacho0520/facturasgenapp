<script>
  let clientName = $state('Empresa Demo S.L.');
  let taxRate = $state(21);
  let template = $state('classic');
  let items = $state([
    { desc: 'Consultoría estratégica', price: 750, qty: 1 },
    { desc: 'Implementación', price: 500, qty: 1 }
  ]);

  const subtotal = () => items.reduce((sum, item) => sum + item.price * item.qty, 0);
  const total = () => subtotal() * (1 + taxRate / 100);

  const templateClass = () => {
    if (template === 'minimal') return 'border-slate-100';
    if (template === 'modern') return 'border-blue-100';
    return 'border-slate-200';
  };
</script>

<div class="min-h-screen bg-slate-50">
  <header class="border-b border-slate-200 bg-white/70 backdrop-blur">
    <div class="mx-auto flex h-16 max-w-6xl items-center justify-between px-6">
      <div class="flex items-center gap-2 text-slate-900">
        <div class="flex h-9 w-9 items-center justify-center rounded-xl bg-blue-600 text-white font-semibold">F</div>
        <span class="text-lg font-semibold">FacturasGen</span>
      </div>
      <a href="/login" class="rounded-full bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-700">
        Crear cuenta
      </a>
    </div>
  </header>

  <main class="mx-auto max-w-6xl px-6 py-16 space-y-8">
    <div>
      <p class="text-xs font-semibold uppercase tracking-[0.3em] text-blue-600">Demo</p>
      <h1 class="mt-4 text-3xl font-semibold text-slate-900">Prueba la experiencia sin registrarte</h1>
      <p class="mt-2 text-sm text-slate-500">
        Esta demo genera PDFs con marca de agua y no guarda datos en la nube.
      </p>
    </div>

    <div class="grid gap-6 lg:grid-cols-[1fr_2fr]">
      <aside class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm space-y-6">
        <div>
          <label class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">Plantilla</label>
          <select bind:value={template} class="mt-2 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm">
            <option value="classic">Clásica</option>
            <option value="modern">Moderna</option>
            <option value="minimal">Minimal</option>
          </select>
          <p class="mt-2 text-xs text-slate-400">Más plantillas profesionales disponibles en Pro.</p>
        </div>
        <div>
          <label class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">Cliente</label>
          <input
            type="text"
            bind:value={clientName}
            class="mt-2 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm"
          />
        </div>
        <div>
          <label class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">IVA</label>
          <input type="number" bind:value={taxRate} class="mt-2 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm" />
        </div>
      </aside>

      <div class={`relative rounded-3xl border ${templateClass()} bg-white p-10 shadow-xl`}>
        <div class="absolute inset-0 rounded-3xl border border-transparent">
          <div class="pointer-events-none absolute inset-0 flex flex-col items-center justify-center opacity-10">
            <div class="grid grid-cols-2 gap-10 text-[48px] font-semibold uppercase tracking-[0.3em] text-slate-400">
              <span>DEMO</span><span>DEMO</span>
              <span>DEMO</span><span>DEMO</span>
              <span>DEMO</span><span>DEMO</span>
              <span>DEMO</span><span>DEMO</span>
            </div>
          </div>
        </div>

        <div class="relative">
          <div class="flex items-start justify-between">
            <div>
              <p class="text-xs uppercase tracking-[0.3em] text-slate-400">Factura</p>
              <h2 class="mt-2 text-3xl font-semibold text-slate-900">INV-DEMO</h2>
            </div>
            <div class="text-right text-xs text-slate-400">
              Documento de ejemplo
            </div>
          </div>

          <div class="mt-8">
            <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">Cliente</p>
            <p class="mt-2 text-xl font-semibold text-slate-900">{clientName}</p>
          </div>

          <div class="mt-8 border-t border-slate-100 pt-4">
            {#each items as item}
              <div class="flex items-center justify-between text-sm text-slate-600">
                <span>{item.desc}</span>
                <span>{(item.price * item.qty).toFixed(2)} €</span>
              </div>
            {/each}
          </div>

          <div class="mt-8 flex justify-end">
            <div class="text-right">
              <p class="text-xs text-slate-400">Total</p>
              <p class="text-2xl font-semibold text-blue-600">{total().toFixed(2)} €</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </main>
</div>
