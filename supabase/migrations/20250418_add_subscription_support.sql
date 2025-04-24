--======================================================================
--  Add subscription + point-tracking support  (safe to run multiple times)
--======================================================================

-- ⚠️ 必要なら UUID 関数を有効化
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

------------------------------------------------------------------
-- 0. public.users が無い環境を考慮し、まず確実に作成しておく
------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.users (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email      TEXT,
  points     INTEGER NOT NULL DEFAULT 0,
  plan       TEXT    NOT NULL DEFAULT 'free',
  created_at TIMESTAMPTZ      DEFAULT NOW()
);

------------------------------------------------------------------
-- 1. users テーブルに plan / points 列が無ければ追加
------------------------------------------------------------------
ALTER TABLE IF EXISTS public.users
  ADD COLUMN IF NOT EXISTS plan   TEXT    NOT NULL DEFAULT 'free',
  ADD COLUMN IF NOT EXISTS points INTEGER NOT NULL DEFAULT 0;

------------------------------------------------------------------
-- 2. subscription_history テーブル
------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.subscription_history (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  plan_id                TEXT NOT NULL,
  status                 TEXT NOT NULL,
  start_date             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  end_date               TIMESTAMPTZ,
  created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  stripe_subscription_id TEXT,
  stripe_customer_id     TEXT,
  metadata               JSONB
);

CREATE INDEX IF NOT EXISTS idx_sub_hist_user_id
  ON public.subscription_history (user_id);

CREATE INDEX IF NOT EXISTS idx_sub_hist_stripe_id
  ON public.subscription_history (stripe_subscription_id);

ALTER TABLE public.subscription_history ENABLE ROW LEVEL SECURITY;

DROP  POLICY IF EXISTS sub_hist_read_own            ON public.subscription_history;
CREATE POLICY        sub_hist_read_own
  ON public.subscription_history
  FOR SELECT
  USING (auth.uid() = user_id);

DROP  POLICY IF EXISTS sub_hist_service_role_all    ON public.subscription_history;
CREATE POLICY        sub_hist_service_role_all
  ON public.subscription_history
  TO authenticated
  USING (auth.role() = 'service_role');

------------------------------------------------------------------
-- 3. point_history テーブル
------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.point_history (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  type        TEXT NOT NULL,
  amount      INTEGER NOT NULL,
  description TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expiry_date TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_point_hist_user_id
  ON public.point_history (user_id);

ALTER TABLE public.point_history ENABLE ROW LEVEL SECURITY;

DROP  POLICY IF EXISTS point_hist_read_own          ON public.point_history;
CREATE POLICY        point_hist_read_own
  ON public.point_history
  FOR SELECT
  USING (auth.uid() = user_id);

DROP  POLICY IF EXISTS point_hist_service_role_all  ON public.point_history;
CREATE POLICY        point_hist_service_role_all
  ON public.point_history
  TO authenticated
  USING (auth.role() = 'service_role');

------------------------------------------------------------------
-- 4. updated_at 自動更新トリガ
------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_touch_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_touch_subscription_history
  ON public.subscription_history;

CREATE TRIGGER trg_touch_subscription_history
  BEFORE UPDATE ON public.subscription_history
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_touch_updated_at();

------------------------------------------------------------------
-- 5. サブスク状態に応じてユーザーポイント付与
------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_add_points_on_subscription()
RETURNS TRIGGER AS $$
DECLARE
  pts INTEGER := 0;
BEGIN
  CASE NEW.plan_id
    WHEN 'plan_ume'  THEN pts := 500;
    WHEN 'plan_take' THEN pts := 1000;
    WHEN 'plan_matsu' THEN pts := 2000;
  END CASE;

  IF NEW.status = 'active'
     AND (TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND OLD.status <> 'active')) THEN

     UPDATE public.users
        SET points = points + pts
      WHERE id = NEW.user_id;

     INSERT INTO public.point_history (user_id, type, amount, description)
       VALUES (NEW.user_id, 'subscription', pts, concat(NEW.plan_id, ' サブスクポイント'));
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_add_points_on_subscription
  ON public.subscription_history;

CREATE TRIGGER trg_add_points_on_subscription
  AFTER INSERT OR UPDATE OF status
  ON public.subscription_history
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_add_points_on_subscription();
