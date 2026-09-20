-- ====================================================================
-- FINORYX INITIAL SCHEMA MIGRATION
-- ====================================================================

-- 1. Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Custom Enumeration Types
DO $$ BEGIN
    CREATE TYPE account_type_enum AS ENUM ('cash', 'bank', 'credit_card', 'digital_wallet', 'other');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE category_type_enum AS ENUM ('income', 'expense');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE transaction_type_enum AS ENUM ('income', 'expense', 'transfer');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE ai_message_role_enum AS ENUM ('user', 'assistant', 'tool');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 3. Automatic updated_at trigger helper
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. User Profiles Table (Linked to Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    base_currency VARCHAR(3) NOT NULL DEFAULT 'INR',
    biometric_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    month_start_day SMALLINT NOT NULL DEFAULT 1 CHECK (month_start_day BETWEEN 1 AND 28),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. Financial Accounts Table
CREATE TABLE IF NOT EXISTS public.accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    account_type account_type_enum NOT NULL DEFAULT 'bank',
    currency VARCHAR(3) NOT NULL DEFAULT 'INR',
    current_balance NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    credit_limit NUMERIC(15, 2) CHECK (credit_limit IS NULL OR credit_limit >= 0),
    billing_cycle_day SMALLINT CHECK (billing_cycle_day IS NULL OR billing_cycle_day BETWEEN 1 AND 28),
    is_archived BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. Categories Table
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    icon TEXT NOT NULL DEFAULT 'category',
    color_hex VARCHAR(9) NOT NULL DEFAULT '#6366F1',
    type category_type_enum NOT NULL,
    parent_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    is_system BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT category_ownership_check CHECK (
        (is_system = TRUE AND user_id IS NULL) OR 
        (is_system = FALSE AND user_id IS NOT NULL)
    )
);

-- 7. Transactions Table
CREATE TABLE IF NOT EXISTS public.transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    account_id UUID NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
    destination_account_id UUID REFERENCES public.accounts(id) ON DELETE RESTRICT,
    category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    type transaction_type_enum NOT NULL,
    amount NUMERIC(15, 2) NOT NULL CHECK (amount > 0),
    fee_amount NUMERIC(15, 2) NOT NULL DEFAULT 0.00 CHECK (fee_amount >= 0),
    transaction_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    description TEXT,
    tags TEXT[] DEFAULT '{}',
    receipt_url TEXT,
    is_recurring BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT transfer_integrity_check CHECK (
        type != 'transfer' OR (destination_account_id IS NOT NULL AND destination_account_id != account_id)
    )
);

-- 8. Budgets Table
CREATE TABLE IF NOT EXISTS public.budgets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES public.categories(id) ON DELETE CASCADE,
    month SMALLINT NOT NULL CHECK (month BETWEEN 1 AND 12),
    year INT NOT NULL CHECK (year >= 2020),
    limit_amount NUMERIC(15, 2) NOT NULL CHECK (limit_amount > 0),
    notify_threshold_pct SMALLINT NOT NULL DEFAULT 80 CHECK (notify_threshold_pct BETWEEN 1 AND 100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_user_category_month_budget UNIQUE (user_id, category_id, month, year)
);

-- 9. Financial Goals Table
CREATE TABLE IF NOT EXISTS public.goals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    linked_account_id UUID REFERENCES public.accounts(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    target_amount NUMERIC(15, 2) NOT NULL CHECK (target_amount > 0),
    current_amount NUMERIC(15, 2) NOT NULL DEFAULT 0.00 CHECK (current_amount >= 0),
    target_date DATE NOT NULL,
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 10. AI Conversations Table
CREATE TABLE IF NOT EXISTS public.ai_conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL DEFAULT 'Financial Chat',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 11. AI Messages Table
CREATE TABLE IF NOT EXISTS public.ai_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES public.ai_conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role ai_message_role_enum NOT NULL,
    content TEXT NOT NULL,
    tool_calls JSONB,
    tool_results JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ====================================================================
-- PERFORMANCE INDEXES
-- ====================================================================
CREATE INDEX IF NOT EXISTS idx_accounts_user_id ON public.accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_categories_user_system ON public.categories(user_id, is_system);
CREATE INDEX IF NOT EXISTS idx_transactions_user_date ON public.transactions(user_id, transaction_date DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_account ON public.transactions(account_id);
CREATE INDEX IF NOT EXISTS idx_transactions_category ON public.transactions(category_id);
CREATE INDEX IF NOT EXISTS idx_budgets_user_period ON public.budgets(user_id, year, month);
CREATE INDEX IF NOT EXISTS idx_goals_user_id ON public.goals(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_messages_convo ON public.ai_messages(conversation_id, created_at ASC);

-- ====================================================================
-- UPDATED_AT TRIGGERS
-- ====================================================================
DROP TRIGGER IF EXISTS update_profiles_modtime ON public.profiles;
CREATE TRIGGER update_profiles_modtime BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS update_accounts_modtime ON public.accounts;
CREATE TRIGGER update_accounts_modtime BEFORE UPDATE ON public.accounts FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS update_categories_modtime ON public.categories;
CREATE TRIGGER update_categories_modtime BEFORE UPDATE ON public.categories FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS update_transactions_modtime ON public.transactions;
CREATE TRIGGER update_transactions_modtime BEFORE UPDATE ON public.transactions FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS update_budgets_modtime ON public.budgets;
CREATE TRIGGER update_budgets_modtime BEFORE UPDATE ON public.budgets FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS update_goals_modtime ON public.goals;
CREATE TRIGGER update_goals_modtime BEFORE UPDATE ON public.goals FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS update_ai_conversations_modtime ON public.ai_conversations;
CREATE TRIGGER update_ai_conversations_modtime BEFORE UPDATE ON public.ai_conversations FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ====================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ====================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_messages ENABLE ROW LEVEL SECURITY;

-- Profiles Policy
DO $$ BEGIN
    DROP POLICY IF EXISTS "Users can manage own profile" ON public.profiles;
    CREATE POLICY "Users can manage own profile" ON public.profiles
        FOR ALL USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
END $$;

-- Accounts Policy
DO $$ BEGIN
    DROP POLICY IF EXISTS "Users can manage own accounts" ON public.accounts;
    CREATE POLICY "Users can manage own accounts" ON public.accounts
        FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
END $$;

-- Categories Policies
DO $$ BEGIN
    DROP POLICY IF EXISTS "Users can view system or own categories" ON public.categories;
    CREATE POLICY "Users can view system or own categories" ON public.categories
        FOR SELECT USING (is_system = TRUE OR auth.uid() = user_id);

    DROP POLICY IF EXISTS "Users can manage own custom categories" ON public.categories;
    CREATE POLICY "Users can manage own custom categories" ON public.categories
        FOR INSERT WITH CHECK (auth.uid() = user_id AND is_system = FALSE);

    DROP POLICY IF EXISTS "Users can update own custom categories" ON public.categories;
    CREATE POLICY "Users can update own custom categories" ON public.categories
        FOR UPDATE USING (auth.uid() = user_id AND is_system = FALSE) WITH CHECK (auth.uid() = user_id);

    DROP POLICY IF EXISTS "Users can delete own custom categories" ON public.categories;
    CREATE POLICY "Users can delete own custom categories" ON public.categories
        FOR DELETE USING (auth.uid() = user_id AND is_system = FALSE);
END $$;

-- Transactions Policy
DO $$ BEGIN
    DROP POLICY IF EXISTS "Users can manage own transactions" ON public.transactions;
    CREATE POLICY "Users can manage own transactions" ON public.transactions
        FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
END $$;

-- Budgets Policy
DO $$ BEGIN
    DROP POLICY IF EXISTS "Users can manage own budgets" ON public.budgets;
    CREATE POLICY "Users can manage own budgets" ON public.budgets
        FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
END $$;

-- Goals Policy
DO $$ BEGIN
    DROP POLICY IF EXISTS "Users can manage own goals" ON public.goals;
    CREATE POLICY "Users can manage own goals" ON public.goals
        FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
END $$;

-- AI Conversations & Messages Policies
DO $$ BEGIN
    DROP POLICY IF EXISTS "Users can manage own ai conversations" ON public.ai_conversations;
    CREATE POLICY "Users can manage own ai conversations" ON public.ai_conversations
        FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

    DROP POLICY IF EXISTS "Users can manage own ai messages" ON public.ai_messages;
    CREATE POLICY "Users can manage own ai messages" ON public.ai_messages
        FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
END $$;

-- ====================================================================
-- AUTOMATIC PROFILE CREATION TRIGGER ON AUTH.USERS SIGNUP
-- ====================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, base_currency, biometric_enabled, month_start_day)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'Finoryx User'),
        COALESCE(NEW.raw_user_meta_data->>'base_currency', 'INR'),
        FALSE,
        1
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
