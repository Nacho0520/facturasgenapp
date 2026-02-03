-- RLS: perfiles y facturas
alter table profiles enable row level security;
alter table invoices enable row level security;

-- profiles: cada usuario solo ve y edita su perfil
create policy "profiles_select_own"
on profiles
for select
to authenticated
using (auth.uid() = id);

create policy "profiles_insert_own"
on profiles
for insert
to authenticated
with check (auth.uid() = id);

create policy "profiles_update_own"
on profiles
for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

-- invoices: cada usuario solo ve y edita sus facturas
create policy "invoices_select_own"
on invoices
for select
to authenticated
using (auth.uid() = user_id);

create policy "invoices_insert_own"
on invoices
for insert
to authenticated
with check (auth.uid() = user_id);

create policy "invoices_update_own"
on invoices
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "invoices_delete_own"
on invoices
for delete
to authenticated
using (auth.uid() = user_id);
