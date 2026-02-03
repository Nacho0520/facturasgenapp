-- Mejoras del informe: columnas, RPC métricas, Storage, recurrentes, org stub
-- Ejecutar en Supabase SQL Editor (después de rls.sql e indexes.sql)

-- 1) Columnas para envío y trazabilidad
ALTER TABLE invoices
  ADD COLUMN IF NOT EXISTS sent_at timestamptz,
  ADD COLUMN IF NOT EXISTS email_sent_to text;

-- 2) RPC para métricas del dashboard (evita cargar todas las facturas)
CREATE OR REPLACE FUNCTION get_user_invoice_stats(p_user_id uuid)
RETURNS TABLE(total_count bigint, draft_count bigint, total_revenue numeric)
LANGUAGE sql
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT
    count(*)::bigint,
    count(*) FILTER (WHERE (status IS NULL OR status = 'draft'))::bigint,
    coalesce(
      sum(
        (SELECT coalesce(sum((elem->>'price')::numeric * (elem->>'qty')::numeric), 0) FROM jsonb_array_elements(COALESCE(line_items, '[]'::jsonb)) elem)
        * (1 + COALESCE(tax_rate, 0) / 100)
      ),
      0
    )
  FROM invoices
  WHERE user_id = p_user_id AND auth.uid() = p_user_id;
$$;

-- 3) Tabla facturas recurrentes (stub para Pro)
CREATE TABLE IF NOT EXISTS recurring_invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  template_invoice_id uuid REFERENCES invoices(id) ON DELETE SET NULL,
  frequency text NOT NULL CHECK (frequency IN ('monthly', 'quarterly', 'yearly')),
  next_run_at date NOT NULL,
  last_run_at date,
  client_name text,
  line_items jsonb DEFAULT '[]'::jsonb,
  tax_rate numeric DEFAULT 21
);

ALTER TABLE recurring_invoices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "recurring_select_own" ON recurring_invoices FOR SELECT TO authenticated
  USING (auth.uid() = user_id);
CREATE POLICY "recurring_insert_own" ON recurring_invoices FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "recurring_update_own" ON recurring_invoices FOR UPDATE TO authenticated
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "recurring_delete_own" ON recurring_invoices FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_recurring_user_next ON recurring_invoices (user_id, next_run_at);

-- 4) Stub org/tenant (para futuro equipos; no usar aún)
CREATE TABLE IF NOT EXISTS orgs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS org_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES orgs(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role text NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'member')),
  created_at timestamptz DEFAULT now(),
  UNIQUE(org_id, user_id)
);

-- invoices sigue con user_id; más adelante se puede añadir org_id y migrar
-- ALTER TABLE invoices ADD COLUMN IF NOT EXISTS org_id uuid REFERENCES orgs(id);

COMMENT ON TABLE orgs IS 'Futuro: equipos/empresas con varios usuarios';
COMMENT ON TABLE org_members IS 'Futuro: membresía org';
