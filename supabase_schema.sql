-- ═══════════════════════════════════════════════════════════════
-- DALTEX Asia Fruit Logistica 2026 — Supabase Database Schema
-- Run this entire script in: Supabase Dashboard → SQL Editor
-- ═══════════════════════════════════════════════════════════════

-- ── 1. PROFILES (linked to auth.users) ──────────────────────────
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  full_name TEXT NOT NULL,
  email TEXT,
  role TEXT CHECK (role IN ('admin', 'sales')) DEFAULT 'sales',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role)
  VALUES (new.id, new.email, COALESCE(new.raw_user_meta_data->>'full_name', split_part(new.email,'@',1)), 'sales');
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- ── 2. VISITORS ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.visitors (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  user_id UUID REFERENCES auth.users(id),
  user_name TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ── 3. MEETINGS ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.meetings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  visitor_name TEXT NOT NULL,
  company TEXT NOT NULL,
  job_title TEXT,
  country TEXT,
  email TEXT,
  phone TEXT,
  business_lines TEXT[] DEFAULT '{}',
  meeting_type TEXT CHECK (meeting_type IN ('New Customer','Existing Customer','Distributor','Supplier','Partner','Media')),
  lead_quality TEXT CHECK (lead_quality IN ('Hot','Warm','Cold')) DEFAULT 'Warm',
  estimated_value NUMERIC(12,2),
  notes TEXT,
  follow_up_required TEXT CHECK (follow_up_required IN ('Yes','No')) DEFAULT 'No',
  follow_up_date DATE,
  user_id UUID REFERENCES auth.users(id),
  salesperson_name TEXT,
  date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS trigger AS $$ BEGIN NEW.updated_at = now(); RETURN NEW; END; $$ LANGUAGE plpgsql;
CREATE TRIGGER meetings_updated_at BEFORE UPDATE ON public.meetings FOR EACH ROW EXECUTE PROCEDURE update_updated_at();

-- ── 4. ROW LEVEL SECURITY ────────────────────────────────────────

-- Profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view all profiles" ON public.profiles FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Admins can manage all profiles" ON public.profiles FOR ALL USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Visitors: all authenticated users can insert/read
ALTER TABLE public.visitors ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Auth users can insert visitors" ON public.visitors FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Auth users can view all visitors" ON public.visitors FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Users can delete own visitors" ON public.visitors FOR DELETE USING (auth.uid() = user_id);
CREATE POLICY "Admins can manage all visitors" ON public.visitors FOR ALL USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Meetings: sales users see only their own, admins see all
ALTER TABLE public.meetings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Sales users can insert meetings" ON public.meetings FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Sales users see own meetings" ON public.meetings FOR SELECT USING (
  auth.uid() = user_id OR
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "Sales users update own meetings" ON public.meetings FOR UPDATE USING (
  auth.uid() = user_id OR
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "Admins can delete meetings" ON public.meetings FOR DELETE USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);

-- ── 5. INDEXES ───────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_meetings_user_id ON public.meetings(user_id);
CREATE INDEX IF NOT EXISTS idx_meetings_date ON public.meetings(date);
CREATE INDEX IF NOT EXISTS idx_meetings_lead_quality ON public.meetings(lead_quality);
CREATE INDEX IF NOT EXISTS idx_visitors_date ON public.visitors(date);
CREATE INDEX IF NOT EXISTS idx_visitors_user_id ON public.visitors(user_id);

-- ── 6. SEED: FIRST ADMIN USER ────────────────────────────────────
-- After running this schema, create your admin user in:
-- Supabase Dashboard → Authentication → Users → Invite user
-- Then run this to promote them to admin (replace the email):
--
-- UPDATE public.profiles SET role = 'admin' WHERE email = 'admin@daltex.com';

-- ── 7. REALTIME (for live visitor count) ─────────────────────────
ALTER PUBLICATION supabase_realtime ADD TABLE public.visitors;
ALTER PUBLICATION supabase_realtime ADD TABLE public.meetings;

-- ═══════════════════════════════════════════════════════════════
-- Done! Your schema is ready. Next steps:
-- 1. Go to Authentication → Settings → disable email confirmation for internal use
-- 2. Create your admin user via Invite
-- 3. Run: UPDATE public.profiles SET role = 'admin' WHERE email = 'YOUR_ADMIN_EMAIL';
-- 4. Update index.html: SUPABASE_URL and SUPABASE_ANON_KEY
-- ═══════════════════════════════════════════════════════════════
