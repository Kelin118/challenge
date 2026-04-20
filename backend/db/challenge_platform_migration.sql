ALTER TABLE challenges
ADD COLUMN IF NOT EXISTS creator_reward_percent INTEGER NOT NULL DEFAULT 5;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'chk_challenges_creator_reward_percent'
  ) THEN
    ALTER TABLE challenges
    ADD CONSTRAINT chk_challenges_creator_reward_percent
    CHECK (creator_reward_percent >= 0 AND creator_reward_percent <= 100);
  END IF;
END $$;

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

CREATE INDEX IF NOT EXISTS idx_challenge_participations_user_id ON challenge_participations (user_id);
CREATE INDEX IF NOT EXISTS idx_challenge_participations_challenge_id ON challenge_participations (challenge_id);
CREATE INDEX IF NOT EXISTS idx_challenge_participations_status ON challenge_participations (status);

ALTER TABLE challenge_submissions
ADD COLUMN IF NOT EXISTS participation_id INTEGER REFERENCES challenge_participations(id) ON DELETE CASCADE;

ALTER TABLE challenge_submissions
ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

ALTER TABLE challenge_submissions
ADD COLUMN IF NOT EXISTS reward_granted_at TIMESTAMP;

CREATE INDEX IF NOT EXISTS idx_challenge_submissions_participation_id
  ON challenge_submissions (participation_id);

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

CREATE INDEX IF NOT EXISTS idx_coin_transactions_user_id ON coin_transactions (user_id);
CREATE INDEX IF NOT EXISTS idx_coin_transactions_created_at ON coin_transactions (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_coin_transactions_submission_id ON coin_transactions (submission_id);

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

CREATE INDEX IF NOT EXISTS idx_completion_events_created_at ON completion_events (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_completion_events_user_id ON completion_events (user_id);
CREATE INDEX IF NOT EXISTS idx_completion_events_challenge_id ON completion_events (challenge_id);
