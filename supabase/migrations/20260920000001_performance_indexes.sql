-- ====================================================================
-- FINORYX PERFORMANCE COMPOSITE INDEXES
-- ====================================================================

-- 1. Accounts composite index for filtering non-archived accounts by user
CREATE INDEX IF NOT EXISTS idx_accounts_user_archived ON public.accounts(user_id, is_archived);

-- 2. Transactions composite index for analytics & reports queries
CREATE INDEX IF NOT EXISTS idx_transactions_user_date_type ON public.transactions(user_id, transaction_date DESC, type);

-- 3. Goals composite index for filtering active/completed goals by user
CREATE INDEX IF NOT EXISTS idx_goals_user_completed ON public.goals(user_id, is_completed);
