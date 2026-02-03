<script>
  import logo from '$lib/assets/logo.svg';
</script>

<div class="min-h-screen bg-slate-50">
  <header class="border-b border-slate-200 bg-white/70 backdrop-blur">
    <div class="mx-auto flex h-16 max-w-6xl items-center justify-between px-6">
      <a href="/" class="flex items-center gap-3 text-slate-900 hover:opacity-90 transition">
        <img src={logo} alt="FacturasGen" class="h-9 w-9" />
        <span class="text-lg font-semibold">FacturasGen</span>
      </a>
      <a href="/login" class="rounded-full bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-700">
        Acceder
      </a>
    </div>
  </header>

  <main class="mx-auto max-w-6xl px-6 py-16">
    <div class="text-center">
      <p class="text-xs font-semibold uppercase tracking-[0.3em] text-blue-600">Planes</p>
      <h1 class="mt-4 text-4xl font-semibold text-slate-900">Elige el plan que encaja con tu negocio</h1>
      <p class="mt-3 text-lg text-slate-600">Empieza gratis y actualiza cuando necesites plantillas pro y mayor personalización.</p>
    </div>

    <div class="mt-12 grid gap-6 lg:grid-cols-2">
      <div class="rounded-3xl border border-slate-200 bg-white p-8 shadow-sm">
        <h2 class="text-xl font-semibold text-slate-900">Gratis</h2>
        <p class="mt-2 text-sm text-slate-500">Para comenzar y validar tu flujo de trabajo.</p>
        <div class="mt-6 text-4xl font-semibold text-slate-900">0 €</div>
        <ul class="mt-6 space-y-3 text-sm text-slate-600">
          <li>Facturas ilimitadas</li>
          <li>1 plantilla básica</li>
          <li>Marca de agua en el PDF</li>
          <li>Datos fiscales básicos</li>
        </ul>
        <a href="/login" class="mt-8 inline-flex w-full items-center justify-center rounded-full border border-slate-200 px-4 py-3 text-sm font-semibold text-slate-700 hover:border-slate-300">
          Empezar gratis
        </a>
      </div>

      <div class="rounded-3xl border border-blue-200 bg-white p-8 shadow-lg">
        <div class="flex items-center justify-between">
          <h2 class="text-xl font-semibold text-slate-900">Pro</h2>
          <span class="rounded-full bg-blue-50 px-3 py-1 text-xs font-semibold text-blue-700">Recomendado</span>
        </div>
        <p class="mt-2 text-sm text-slate-500">Para empresas que necesitan imagen profesional total.</p>
        <div class="mt-6 text-4xl font-semibold text-slate-900">9 € <span class="text-sm text-slate-500">/mes</span></div>
        <ul class="mt-6 space-y-3 text-sm text-slate-600">
          <li>Sin marca de agua</li>
          <li>Plantillas profesionales ilimitadas</li>
          <li>Personalización avanzada y branding</li>
          <li>Soporte prioritario</li>
        </ul>
        <button class="mt-8 inline-flex w-full items-center justify-center rounded-full bg-blue-600 px-4 py-3 text-sm font-semibold text-white hover:bg-blue-700">
          Comprar plan Pro
        </button>
        <p class="mt-3 text-xs text-slate-400 text-center">Pago seguro. Cancela cuando quieras.</p>
      </div>
    </div>
  </main>
</div>
