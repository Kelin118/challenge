-- Synchronizes PostgreSQL schema with the current backend code.
-- Safe to run on an existing database: creates missing tables, columns,
-- indexes and constraints, and migrates legacy XP fields to coin fields.

BEGIN;

-- ---------------------------------------------------------------------------
-- Core auth tables that other schemas depend on.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  username TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  avatar_url TEXT,
  bio TEXT,
  status TEXT DEFAULT 'offline',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users (email);
CREATE INDEX IF NOT EXISTS idx_users_username ON users (username);

CREATE TABLE IF NOT EXISTS sessions (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  refresh_token TEXT NOT NULL,
  device_name TEXT,
  platform TEXT,
  user_agent TEXT,
  ip_address TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  last_used_at TIMESTAMP DEFAULT NOW(),
  expires_at TIMESTAMP NOT NULL,
  revoked_at TIMESTAMP NULL
);

CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions (user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_refresh_token ON sessions (refresh_token);
CREATE INDEX IF NOT EXISTS idx_sessions_revoked_at ON sessions (revoked_at);

-- ---------------------------------------------------------------------------
-- Achievements schema: migrate XP fields to coins and ensure current tables.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS achievement_definitions (
  id SERIAL PRIMARY KEY,
  key TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL,
  rarity TEXT NOT NULL DEFAULT 'common',
  icon TEXT NOT NULL,
  coin_reward INTEGER NOT NULL DEFAULT 0,
  target_value INTEGER NOT NULL DEFAULT 1,
  is_hidden BOOLEAN NOT NULL DEFAULT FALSE,
  verification_type TEXT NOT NULL DEFAULT 'none',
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_name = 'achievement_definitions'
      AND column_name = 'xp_reward'
  ) AND NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_name = 'achievement_definitions'
      AND column_name = 'coin_reward'
  ) THEN
    ALTER TABLE achievement_definitions RENAME COLUMN xp_reward TO coin_reward;
  END IF;
END $$;

ALTER TABLE achievement_definitions
  ADD COLUMN IF NOT EXISTS coin_reward INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS target_value INTEGER NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS is_hidden BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS verification_type TEXT NOT NULL DEFAULT 'none',
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP NOT NULL DEFAULT NOW();

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_name = 'achievement_definitions'
      AND column_name = 'xp_reward'
  ) THEN
    EXECUTE 'UPDATE achievement_definitions SET coin_reward = COALESCE(coin_reward, xp_reward, 0)';
  END IF;
END $$;

ALTER TABLE achievement_definitions
  DROP CONSTRAINT IF EXISTS chk_achievement_definitions_rarity,
  DROP CONSTRAINT IF EXISTS chk_achievement_definitions_verification_type,
  DROP CONSTRAINT IF EXISTS chk_achievement_definitions_coin_reward,
  DROP CONSTRAINT IF EXISTS chk_achievement_definitions_target_value;

ALTER TABLE achievement_definitions
  ADD CONSTRAINT chk_achievement_definitions_rarity
    CHECK (rarity IN ('common', 'rare', 'epic', 'legendary')),
  ADD CONSTRAINT chk_achievement_definitions_verification_type
    CHECK (verification_type IN ('none', 'text', 'ai_text')),
  ADD CONSTRAINT chk_achievement_definitions_coin_reward
    CHECK (coin_reward >= 0),
  ADD CONSTRAINT chk_achievement_definitions_target_value
    CHECK (target_value > 0);

CREATE INDEX IF NOT EXISTS idx_achievement_definitions_category
  ON achievement_definitions (category);
CREATE INDEX IF NOT EXISTS idx_achievement_definitions_rarity
  ON achievement_definitions (rarity);

CREATE TABLE IF NOT EXISTS user_achievements (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  achievement_definition_id INTEGER NOT NULL REFERENCES achievement_definitions(id) ON DELETE CASCADE,
  progress INTEGER NOT NULL DEFAULT 0,
  is_unlocked BOOLEAN NOT NULL DEFAULT FALSE,
  unlocked_at TIMESTAMP NULL,
  verification_status TEXT NOT NULL DEFAULT 'none',
  last_evidence_text TEXT,
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_user_achievement UNIQUE (user_id, achievement_definition_id),
  CONSTRAINT chk_user_achievements_verification_status
    CHECK (verification_status IN ('none', 'pending', 'approved', 'rejected')),
  CONSTRAINT chk_user_achievements_progress
    CHECK (progress >= 0)
);

CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id
  ON user_achievements (user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_definition_id
  ON user_achievements (achievement_definition_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_unlocked
  ON user_achievements (is_unlocked);

CREATE TABLE IF NOT EXISTS user_stats (
  user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  total_coins INTEGER NOT NULL DEFAULT 0,
  unlocked_count INTEGER NOT NULL DEFAULT 0,
  achievements_count INTEGER NOT NULL DEFAULT 0,
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_name = 'user_stats'
      AND column_name = 'total_xp'
  ) AND NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_name = 'user_stats'
      AND column_name = 'total_coins'
  ) THEN
    ALTER TABLE user_stats RENAME COLUMN total_xp TO total_coins;
  END IF;
END $$;

ALTER TABLE user_stats
  ADD COLUMN IF NOT EXISTS total_coins INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS unlocked_count INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS achievements_count INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP NOT NULL DEFAULT NOW();

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

ALTER TABLE user_stats
  DROP CONSTRAINT IF EXISTS chk_user_stats_total_coins,
  DROP CONSTRAINT IF EXISTS chk_user_stats_unlocked_count,
  DROP CONSTRAINT IF EXISTS chk_user_stats_achievements_count;

ALTER TABLE user_stats
  ADD CONSTRAINT chk_user_stats_total_coins CHECK (total_coins >= 0),
  ADD CONSTRAINT chk_user_stats_unlocked_count CHECK (unlocked_count >= 0),
  ADD CONSTRAINT chk_user_stats_achievements_count CHECK (achievements_count >= 0);

-- ---------------------------------------------------------------------------
-- Challenge platform schema used by repositories/services/controllers.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS challenges (
  id SERIAL PRIMARY KEY,
  creator_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL,
  type TEXT NOT NULL,
  rarity TEXT NOT NULL DEFAULT 'common',
  coin_cost INTEGER NOT NULL DEFAULT 0,
  coin_reward INTEGER NOT NULL DEFAULT 0,
  creator_reward_percent INTEGER NOT NULL DEFAULT 5,
  proof_type TEXT NOT NULL DEFAULT 'photo',
  status TEXT NOT NULL DEFAULT 'active',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

ALTER TABLE challenges
  ADD COLUMN IF NOT EXISTS creator_reward_percent INTEGER NOT NULL DEFAULT 5,
  ADD COLUMN IF NOT EXISTS coin_cost INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS coin_reward INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS proof_type TEXT NOT NULL DEFAULT 'photo',
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'active',
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW();

ALTER TABLE challenges
  DROP CONSTRAINT IF EXISTS chk_type,
  DROP CONSTRAINT IF EXISTS chk_rarity,
  DROP CONSTRAINT IF EXISTS chk_status,
  DROP CONSTRAINT IF EXISTS chk_proof_type,
  DROP CONSTRAINT IF EXISTS chk_challenges_type,
  DROP CONSTRAINT IF EXISTS chk_challenges_rarity,
  DROP CONSTRAINT IF EXISTS chk_challenges_status,
  DROP CONSTRAINT IF EXISTS chk_challenges_proof_type,
  DROP CONSTRAINT IF EXISTS chk_challenges_coin_cost,
  DROP CONSTRAINT IF EXISTS chk_challenges_coin_reward,
  DROP CONSTRAINT IF EXISTS chk_challenges_creator_reward_percent;

ALTER TABLE challenges
  ADD CONSTRAINT chk_challenges_type CHECK (type IN ('daily', 'yearly', 'permanent')),
  ADD CONSTRAINT chk_challenges_rarity CHECK (rarity IN ('common', 'rare', 'epic', 'legendary', 'mythic')),
  ADD CONSTRAINT chk_challenges_status CHECK (status IN ('active', 'draft', 'archived')),
  ADD CONSTRAINT chk_challenges_proof_type CHECK (proof_type IN ('photo', 'video', 'text', 'none')),
  ADD CONSTRAINT chk_challenges_coin_cost CHECK (coin_cost >= 0),
  ADD CONSTRAINT chk_challenges_coin_reward CHECK (coin_reward >= 0),
  ADD CONSTRAINT chk_challenges_creator_reward_percent CHECK (creator_reward_percent >= 0 AND creator_reward_percent <= 100);

CREATE INDEX IF NOT EXISTS idx_challenges_creator_user_id ON challenges (creator_user_id);
CREATE INDEX IF NOT EXISTS idx_challenges_category ON challenges (category);
CREATE INDEX IF NOT EXISTS idx_challenges_status ON challenges (status);
CREATE INDEX IF NOT EXISTS idx_challenges_rarity ON challenges (rarity);

CREATE TABLE IF NOT EXISTS challenge_conditions (
  id SERIAL PRIMARY KEY,
  challenge_id INTEGER NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
  conditions_text TEXT NOT NULL,
  success_criteria_text TEXT NOT NULL,
  proof_instructions TEXT,
  deadline_label TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

ALTER TABLE challenge_conditions
  ADD COLUMN IF NOT EXISTS conditions_text TEXT,
  ADD COLUMN IF NOT EXISTS success_criteria_text TEXT,
  ADD COLUMN IF NOT EXISTS proof_instructions TEXT,
  ADD COLUMN IF NOT EXISTS deadline_label TEXT,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW();

UPDATE challenge_conditions
SET
  conditions_text = COALESCE(conditions_text, ''),
  success_criteria_text = COALESCE(success_criteria_text, '');

ALTER TABLE challenge_conditions
  ALTER COLUMN conditions_text SET NOT NULL,
  ALTER COLUMN success_criteria_text SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_challenge_conditions_challenge_id
  ON challenge_conditions (challenge_id);

CREATE TABLE IF NOT EXISTS challenge_participations (
  id SERIAL PRIMARY KEY,
  challenge_id INTEGER NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'in_progress',
  progress_value INTEGER NOT NULL DEFAULT 0,
  accepted_at TIMESTAMP DEFAULT NOW(),
  submitted_at TIMESTAMP,
  approved_at TIMESTAMP,
  rejected_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

ALTER TABLE challenge_participations
  ADD COLUMN IF NOT EXISTS progress_value INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS accepted_at TIMESTAMP DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS submitted_at TIMESTAMP,
  ADD COLUMN IF NOT EXISTS approved_at TIMESTAMP,
  ADD COLUMN IF NOT EXISTS rejected_at TIMESTAMP,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW();

ALTER TABLE challenge_participations
  DROP CONSTRAINT IF EXISTS chk_challenge_participations_status,
  DROP CONSTRAINT IF EXISTS chk_challenge_participations_progress_value,
  DROP CONSTRAINT IF EXISTS uq_challenge_participations_challenge_user;

ALTER TABLE challenge_participations
  ADD CONSTRAINT chk_challenge_participations_status
    CHECK (status IN ('in_progress', 'submitted', 'approved', 'rejected')),
  ADD CONSTRAINT chk_challenge_participations_progress_value
    CHECK (progress_value >= 0 AND progress_value <= 100),
  ADD CONSTRAINT uq_challenge_participations_challenge_user
    UNIQUE (challenge_id, user_id);

CREATE INDEX IF NOT EXISTS idx_challenge_participations_user_id
  ON challenge_participations (user_id);
CREATE INDEX IF NOT EXISTS idx_challenge_participations_challenge_id
  ON challenge_participations (challenge_id);
CREATE INDEX IF NOT EXISTS idx_challenge_participations_status
  ON challenge_participations (status);

CREATE TABLE IF NOT EXISTS challenge_submissions (
  id SERIAL PRIMARY KEY,
  challenge_id INTEGER NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
  participation_id INTEGER REFERENCES challenge_participations(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  proof_url TEXT,
  proof_type TEXT NOT NULL DEFAULT 'photo',
  comment TEXT,
  status TEXT NOT NULL DEFAULT 'pending',
  rejection_reason TEXT,
  reward_granted_at TIMESTAMP,
  reviewed_by_user_id INTEGER REFERENCES users(id),
  reviewed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

ALTER TABLE challenge_submissions
  ADD COLUMN IF NOT EXISTS participation_id INTEGER REFERENCES challenge_participations(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS rejection_reason TEXT,
  ADD COLUMN IF NOT EXISTS reward_granted_at TIMESTAMP,
  ADD COLUMN IF NOT EXISTS reviewed_by_user_id INTEGER REFERENCES users(id),
  ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMP,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW();

ALTER TABLE challenge_submissions
  DROP CONSTRAINT IF EXISTS chk_challenge_submissions_status,
  DROP CONSTRAINT IF EXISTS chk_challenge_submissions_proof_type,
  DROP CONSTRAINT IF EXISTS chk_status,
  DROP CONSTRAINT IF EXISTS chk_proof_type;

ALTER TABLE challenge_submissions
  ADD CONSTRAINT chk_challenge_submissions_status
    CHECK (status IN ('pending', 'accepted', 'rejected')),
  ADD CONSTRAINT chk_challenge_submissions_proof_type
    CHECK (proof_type IN ('photo', 'video', 'text', 'none'));

CREATE INDEX IF NOT EXISTS idx_challenge_submissions_challenge_id
  ON challenge_submissions (challenge_id);
CREATE INDEX IF NOT EXISTS idx_challenge_submissions_participation_id
  ON challenge_submissions (participation_id);
CREATE INDEX IF NOT EXISTS idx_challenge_submissions_user_id
  ON challenge_submissions (user_id);
CREATE INDEX IF NOT EXISTS idx_challenge_submissions_status
  ON challenge_submissions (status);

CREATE TABLE IF NOT EXISTS coin_transactions (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  challenge_id INTEGER REFERENCES challenges(id) ON DELETE SET NULL,
  submission_id INTEGER REFERENCES challenge_submissions(id) ON DELETE SET NULL,
  transaction_type TEXT NOT NULL,
  amount INTEGER NOT NULL,
  description TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

ALTER TABLE coin_transactions
  ADD COLUMN IF NOT EXISTS challenge_id INTEGER REFERENCES challenges(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS submission_id INTEGER REFERENCES challenge_submissions(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS description TEXT,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW();

UPDATE coin_transactions
SET description = COALESCE(description, 'Coin transaction');

ALTER TABLE coin_transactions
  ALTER COLUMN description SET NOT NULL;

ALTER TABLE coin_transactions
  DROP CONSTRAINT IF EXISTS chk_coin_transactions_type;

ALTER TABLE coin_transactions
  ADD CONSTRAINT chk_coin_transactions_type CHECK (
    transaction_type IN (
      'challenge_creation_cost',
      'challenge_reward',
      'challenge_creator_reward',
      'manual_adjustment',
      'refund'
    )
  );

CREATE INDEX IF NOT EXISTS idx_coin_transactions_user_id
  ON coin_transactions (user_id);
CREATE INDEX IF NOT EXISTS idx_coin_transactions_created_at
  ON coin_transactions (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_coin_transactions_submission_id
  ON coin_transactions (submission_id);
CREATE INDEX IF NOT EXISTS idx_coin_transactions_challenge_id
  ON coin_transactions (challenge_id);

CREATE TABLE IF NOT EXISTS completion_events (
  id SERIAL PRIMARY KEY,
  submission_id INTEGER NOT NULL REFERENCES challenge_submissions(id) ON DELETE CASCADE,
  challenge_id INTEGER NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  coins_earned INTEGER NOT NULL DEFAULT 0,
  medal_awarded BOOLEAN NOT NULL DEFAULT FALSE,
  image_proof TEXT,
  likes_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);

ALTER TABLE completion_events
  ADD COLUMN IF NOT EXISTS coins_earned INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS medal_awarded BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS image_proof TEXT,
  ADD COLUMN IF NOT EXISTS likes_count INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW();

ALTER TABLE completion_events
  DROP CONSTRAINT IF EXISTS uq_completion_events_submission_id;

ALTER TABLE completion_events
  ADD CONSTRAINT uq_completion_events_submission_id UNIQUE (submission_id);

CREATE INDEX IF NOT EXISTS idx_completion_events_created_at
  ON completion_events (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_completion_events_user_id
  ON completion_events (user_id);
CREATE INDEX IF NOT EXISTS idx_completion_events_challenge_id
  ON completion_events (challenge_id);

COMMIT;
