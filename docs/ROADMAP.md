# Roadmap estratégico (FacturasGen)

Basado en el informe de riesgos y escalabilidad. Prioridad: **antes del Public Launch**.

---

## 1. Hardening multi-tenant + auditoría RLS

- Definir claramente **user_id vs org_id**: si más adelante habrá equipos/empresas con varios usuarios, conviene introducir `org_id` y `org_members` desde el diseño.
- Políticas RLS **por operación** (SELECT/INSERT/UPDATE/DELETE) ya aplicadas; revisar que en UPDATE no se permitan cambios en columnas sensibles (ej. `status` de emitida, `number`).
- **Índices**: ejecutar `supabase/indexes.sql` (user_id, created_at desc) para rendimiento del dashboard.
- Tests de acceso: comprobar que un usuario A no puede leer/escribir facturas de B.

---

## 2. PDF "modo fiable" (server-side) + Storage privado

- **Problema actual**: PDF en cliente (html2pdf.js) no es determinista; CORS en logos/portadas y diferencias entre navegadores generan soporte y desconfianza.
- **Objetivo**: Para plan Pro, generar PDF en servidor (Headless Chrome / Browserless / Playwright), guardar en Supabase Storage (bucket privado) y servir con **signed URLs** (TTL corto).
- Flujo típico: ruta HTML "print" de la factura (SSR) → job (Edge Function o serverless) abre la URL autenticada → genera PDF → sube a Storage → devuelve enlace firmado.
- Mantener PDF en cliente para **demo** y **plan gratuito** (con marca de agua).

---

## 3. Rendimiento del dashboard

- **Hecho**: paginación por cursor (20 por página), "Cargar más", e índices recomendados.
- Opcional: `export const csr = false` en la página del listado (o CSR solo donde haga falta) para reducir hidratación.
- Opcional: virtualización si se quiere "infinite scroll" con muchas filas.
- Métricas (ingresos, contadores): se pueden cargar por separado o en streaming para no bloquear el HTML.

---

## 4. Autosave + estados claros en el editor

- **Hecho**: autosave de borrador con feedback (Guardando... / Guardado / Error), botones "Guardar borrador" y "Emitir factura", y aviso al editar factura emitida.
- **Emitir** = marcar como `sent` y redirigir al dashboard; en el futuro se puede "bloquear" la edición de emitidas o versionar.

---

## 5. Paquete Pro con features de retención

- El watermark solo convierte a unos usuarios; para **MRR recurrente** hace falta valor continuo.
- Prioridad 1: **Facturas recurrentes** + recordatorios (series mensuales/trimestrales, borradores automáticos).
- Prioridad 2: **Envío desde la app** + tracking (enviar por email, estado enviada/vista/pagada, portal cliente).
- Prioridad 3: **Cobro integrado** (Stripe link por factura, marcar pagada, export para gestoría).

---

## Otros puntos del informe

- **Logo / imágenes**: aviso en UI sobre URLs externas y CORS; a medio plazo recomendar (o exigir) subida a nuestro Storage.
- **Auth**: allowlist estricta de redirects, TTL corto del magic link, rate limiting en edge; MFA en roadmap para planes de pago.
- **Privacidad**: no loguear payloads de factura; política de privacidad clara (GDPR si UE).
- **Impuestos**: IVA global está bien para MVP; para España/micropymes valorar IRPF, recargo equivalencia, inversión sujeto pasivo, etc.
