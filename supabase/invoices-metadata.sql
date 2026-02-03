-- Extensiones para personalización de facturas
alter table invoices
  add column if not exists template text default 'classic',
  add column if not exists cover_image_url text,
  add column if not exists section_order jsonb default '["header","client","items","totals","footer"]'::jsonb;
