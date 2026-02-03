import { sequence } from '@sveltejs/kit/hooks';

/** Rate limit simple en memoria: por IP, máx N peticiones por ventana (para auth y API) */
const RATE_WINDOW_MS = 60 * 1000; // 1 minuto
const RATE_MAX = 30; // máx 30 peticiones por minuto por IP en rutas protegidas

/** @type {Map<string, { count: number; resetAt: number }>} */
const rateMap = new Map();

function getClientId(request) {
  const forwarded = request.headers.get('x-forwarded-for');
  const ip = forwarded ? forwarded.split(',')[0].trim() : request.headers.get('x-real-ip') ?? 'unknown';
  return ip;
}

function rateLimit(identifier) {
  const now = Date.now();
  let entry = rateMap.get(identifier);
  if (!entry) {
    rateMap.set(identifier, { count: 1, resetAt: now + RATE_WINDOW_MS });
    return { ok: true, remaining: RATE_MAX - 1 };
  }
  if (now > entry.resetAt) {
    entry = { count: 1, resetAt: now + RATE_WINDOW_MS };
    rateMap.set(identifier, entry);
    return { ok: true, remaining: RATE_MAX - 1 };
  }
  entry.count += 1;
  if (entry.count > RATE_MAX) {
    return { ok: false, remaining: 0 };
  }
  return { ok: true, remaining: RATE_MAX - entry.count };
}

/** Rutas donde aplicar rate limit (login, API) */
function shouldRateLimit(pathname) {
  return pathname.startsWith('/login') || pathname.startsWith('/api/');
}

/** @type {import('@sveltejs/kit').Handle} */
async function handleRateLimit({ event, resolve }) {
  if (!shouldRateLimit(event.url.pathname)) {
    return resolve(event);
  }
  const id = getClientId(event.request);
  const { ok, remaining } = rateLimit(id);
  event.setHeaders({ 'X-RateLimit-Remaining': String(remaining) });
  if (!ok) {
    return new Response(JSON.stringify({ error: 'Demasiadas peticiones. Intenta más tarde.' }), {
      status: 429,
      headers: { 'Content-Type': 'application/json' }
    });
  }
  return resolve(event);
}

export const handle = sequence(handleRateLimit);
