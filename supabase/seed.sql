-- ====================================================================
-- FINORYX SEED DATA: DEFAULT SYSTEM CATEGORIES
-- ====================================================================

INSERT INTO public.categories (name, icon, color_hex, type, is_system) VALUES
    -- Expense Categories
    ('Food & Dining', 'restaurant', '#EF4444', 'expense', TRUE),
    ('Groceries', 'shopping_cart', '#F97316', 'expense', TRUE),
    ('Transportation', 'directions_car', '#F59E0B', 'expense', TRUE),
    ('Housing & Rent', 'home', '#10B981', 'expense', TRUE),
    ('Utilities & Bills', 'bolt', '#06B6D4', 'expense', TRUE),
    ('Shopping & Clothing', 'shopping_bag', '#3B82F6', 'expense', TRUE),
    ('Entertainment & Leisure', 'movie', '#8B5CF6', 'expense', TRUE),
    ('Health & Medical', 'medical_services', '#EC4899', 'expense', TRUE),
    ('Education', 'school', '#6366F1', 'expense', TRUE),
    ('Travel & Vacation', 'flight', '#14B8A6', 'expense', TRUE),
    ('Personal Care', 'spa', '#D946EF', 'expense', TRUE),
    ('Miscellaneous Expense', 'more_horiz', '#6B7280', 'expense', TRUE),
    -- Income Categories
    ('Salary', 'payments', '#10B981', 'income', TRUE),
    ('Freelance & Side Gig', 'laptop', '#3B82F6', 'income', TRUE),
    ('Investments & Dividends', 'trending_up', '#8B5CF6', 'income', TRUE),
    ('Gifts & Grants', 'card_giftcard', '#F59E0B', 'income', TRUE),
    ('Rental Income', 'apartment', '#06B6D4', 'income', TRUE),
    ('Other Income', 'account_balance_wallet', '#6B7280', 'income', TRUE)
ON CONFLICT DO NOTHING;
