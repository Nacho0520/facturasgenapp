<script>
  // Layout mínimo para impresión: sin sidebar ni navegación
</script>

<svelte:head>
  <title>Factura - Impresión</title>
  <style>
    @media print {
      body { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
    }
  </style>
</svelte:head>

<slot />
