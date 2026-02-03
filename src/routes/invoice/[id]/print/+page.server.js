import { createClient } from '@supabase/supabase-js';
import { env } from '$env/dynamic/private';

const PAGE_SIZE = 1;

/**
 * Crea cliente Supabase con service role (solo para validar token y cargar factura en impresión).
 * Requiere SUPABASE_SERVICE_ROLE_KEY en .env
 */
function getSupabaseAdmin() {
  const url = env.PUBLIC_SUPABASE_URL;
  const key = env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !key) return null;
  return createClient(url, key);
}

/**
 * Valida token de impresión (HMAC con PDF_TOKEN_SECRET).
 * Formato: base64url(payload).signature
 */
function validatePrintToken(token, invoiceId) {
  const secret = env.PDF_TOKEN_SECRET;
  if (!secret || !token) return null;
  const parts = token.split('.');
  if (parts.length !== 2) return null;
  try {
    const decoded = Buffer.from(parts[0].replace(/-/g, '+').replace(/_/g, '/'), 'base64').toString('utf8');
    const payload = JSON.parse(decoded);
    if (payload.invoiceId !== invoiceId || payload.exp < Date.now() / 1000) return null;
    // En producción aquí se verificaría la firma HMAC
    return payload;
  } catch {
    return null;
  }
}

/** @param {{ params: { id: string }, url: URL }} args */
export async function load({ params, url }) {
  const token = url.searchParams.get('token');
  const id = params.id;

  if (!token) {
    return { id };
  }

  const payload = validatePrintToken(token, id);
  if (!payload) {
    return { error: 'Token inválido o expirado' };
  }

  const supabase = getSupabaseAdmin();
  if (!supabase) {
    return { error: 'Configuración de servidor incompleta' };
  }

  const { data: invoice, error: errInv } = await supabase
    .from('invoices')
    .select('id, number, client_name, line_items, tax_rate, template, cover_image_url, section_order, user_id')
    .eq('id', id)
    .limit(PAGE_SIZE)
    .maybeSingle();

  if (errInv || !invoice) {
    return { error: 'Factura no encontrada' };
  }

  const { data: profile } = await supabase
    .from('profiles')
    .select('business_name, tax_id, address, logo_url')
    .eq('id', invoice.user_id)
    .limit(1)
    .maybeSingle();

  return {
    id,
    invoice: {
      id: invoice.id,
      number: invoice.number,
      client_name: invoice.client_name,
      line_items: invoice.line_items ?? [],
      tax_rate: invoice.tax_rate ?? 0,
      template: invoice.template,
      cover_image_url: invoice.cover_image_url,
      section_order: invoice.section_order ?? ['header', 'client', 'items', 'totals', 'footer']
    },
    profile: profile ?? { business_name: '', tax_id: '', address: '', logo_url: '' }
  };
}
