DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_name = 'achievement_definitions'
      AND column_name = 'xp_reward'
  ) THEN
    ALTER TABLE achievement_definitions RENAME COLUMN xp_reward TO coin_reward;
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_name = 'user_stats'
      AND column_name = 'total_xp'
  ) THEN
    ALTER TABLE user_stats RENAME COLUMN total_xp TO total_coins;
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_name = 'user_stats'
      AND column_name = 'level'
  ) THEN
    ALTER TABLE user_stats DROP COLUMN level;
  END IF;
END $$;

ALTER TABLE achievement_definitions
  ALTER COLUMN coin_reward SET DEFAULT 0;

ALTER TABLE user_stats
  ALTER COLUMN total_coins SET DEFAULT 0;
