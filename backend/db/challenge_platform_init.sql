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
  updated_at TIMESTAMP DEFAULT NOW(),
  CONSTRAINT chk_challenges_type CHECK (type IN ('daily', 'yearly', 'permanent')),
  CONSTRAINT chk_challenges_rarity CHECK (rarity IN ('common', 'rare', 'epic', 'legendary', 'mythic')),
  CONSTRAINT chk_challenges_status CHECK (status IN ('active', 'draft', 'archived')),
  CONSTRAINT chk_challenges_proof_type CHECK (proof_type IN ('photo', 'video', 'text', 'none')),
  CONSTRAINT chk_challenges_coin_cost CHECK (coin_cost >= 0),
  CONSTRAINT chk_challenges_coin_reward CHECK (coin_reward >= 0),
  CONSTRAINT chk_challenges_creator_reward_percent CHECK (creator_reward_percent >= 0 AND creator_reward_percent <= 100)
);

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
  updated_at TIMESTAMP DEFAULT NOW(),
  CONSTRAINT chk_challenge_participations_status CHECK (status IN ('in_progress', 'submitted', 'approved', 'rejected')),
  CONSTRAINT chk_challenge_participations_progress_value CHECK (progress_value >= 0 AND progress_value <= 100),
  CONSTRAINT uq_challenge_participations_challenge_user UNIQUE (challenge_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_challenge_participations_user_id
  ON challenge_participations (user_id);
CREATE INDEX IF NOT EXISTS idx_challenge_participations_challenge_id
  ON challenge_participations (challenge_id);
CREATE INDEX IF NOT EXISTS idx_challenge_participations_status
  ON challenge_participations (status);

CREATE TABLE IF NOT EXISTS challenge_submissions (
  id SERIAL PRIMARY KEY,
  challenge_id INTEGER NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
  participation_id INTEGER NOT NULL REFERENCES challenge_participations(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  proof_url TEXT,
  proof_type TEXT NOT NULL DEFAULT 'photo',
  comment TEXT,
  status TEXT NOT NULL DEFAULT 'pending',
  rejection_reason TEXT,
  reward_granted_at TIMESTAMP,
  reviewed_by_user_id INTEGER REFERENCES users(id),
  reviewed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  CONSTRAINT chk_challenge_submissions_status CHECK (status IN ('pending', 'accepted', 'rejected')),
  CONSTRAINT chk_challenge_submissions_proof_type CHECK (proof_type IN ('photo', 'video', 'text', 'none'))
);

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
  created_at TIMESTAMP DEFAULT NOW(),
  CONSTRAINT chk_coin_transactions_type CHECK (
    transaction_type IN (
      'challenge_creation_cost',
      'challenge_reward',
      'challenge_creator_reward',
      'manual_adjustment',
      'refund'
    )
  )
);

CREATE INDEX IF NOT EXISTS idx_coin_transactions_user_id
  ON coin_transactions (user_id);
CREATE INDEX IF NOT EXISTS idx_coin_transactions_created_at
  ON coin_transactions (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_coin_transactions_submission_id
  ON coin_transactions (submission_id);

CREATE TABLE IF NOT EXISTS completion_events (
  id SERIAL PRIMARY KEY,
  submission_id INTEGER NOT NULL REFERENCES challenge_submissions(id) ON DELETE CASCADE,
  challenge_id INTEGER NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  coins_earned INTEGER NOT NULL DEFAULT 0,
  medal_awarded BOOLEAN NOT NULL DEFAULT FALSE,
  image_proof TEXT,
  likes_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  CONSTRAINT uq_completion_events_submission_id UNIQUE (submission_id)
);

CREATE INDEX IF NOT EXISTS idx_completion_events_created_at
  ON completion_events (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_completion_events_user_id
  ON completion_events (user_id);
CREATE INDEX IF NOT EXISTS idx_completion_events_challenge_id
  ON completion_events (challenge_id);
