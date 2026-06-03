-- ═══════════════════════════════════════════════════════════════════
-- Supabase SQL: Auto-insert public.users when new auth.users created
-- Run this in: Supabase Dashboard → SQL Editor → New Query
-- ═══════════════════════════════════════════════════════════════════

-- Step 1: Create the trigger function
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER AS $$
BEGIN
    -- 1. Check if email already exists in public.users (Sync issue from old backend data)
    IF EXISTS (SELECT 1 FROM public.users WHERE email = NEW.email) THEN
        RETURN NEW;
    END IF;

    -- 2. Try to insert new user
    BEGIN
        INSERT INTO public.users (
            id, name, email, password_hash, avatar_url, bio, interests,
            is_active, joined_at_utc, created_at_utc, reputation_score,
            badges_count, friends_count
        )
        VALUES (
            NEW.id,
            COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
            NEW.email,
            '$2a$11$' || encode(gen_random_bytes(22), 'base64'),
            COALESCE(NEW.raw_user_meta_data->>'avatar_url', NEW.raw_user_meta_data->>'picture', 'https://api.dicebear.com/7.x/avataaars/svg?seed=' || NEW.email),
            '', '', true, NOW(), NOW(), 0, 0, 0
        )
        ON CONFLICT (id) DO NOTHING;
    EXCEPTION WHEN OTHERS THEN
        -- BỎ QUA MỌI LỖI (Ví dụ: thiếu cột, sai kiểu dữ liệu)
        -- Điều này giúp Google Login KHÔNG BAO GIỜ bị Crash (Lỗi 500)
        RAISE WARNING 'Lỗi khi copy user sang public.users: %', SQLERRM;
    END;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 2: Drop existing trigger (if any) and create new one
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_auth_user();

-- ═══════════════════════════════════════════════════════════════════
-- Verification: Check the trigger was created
-- ═══════════════════════════════════════════════════════════════════
SELECT trigger_name, event_manipulation, event_object_table
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';
