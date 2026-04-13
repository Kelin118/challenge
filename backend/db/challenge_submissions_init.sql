CREATE TABLE IF NOT EXISTS challenge_submissions (
  id SERIAL PRIMARY KEY,
  challenge_id INTEGER NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  proof_url TEXT,
  proof_type TEXT NOT NULL DEFAULT 'photo',
  comment TEXT,
  status TEXT NOT NULL DEFAULT 'pending',
  reviewed_by_user_id INTEGER REFERENCES users(id),
  reviewed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  CONSTRAINT chk_challenge_submissions_status CHECK (status IN ('pending', 'accepted', 'rejected')),
  CONSTRAINT chk_challenge_submissions_proof_type CHECK (proof_type IN ('photo', 'video', 'text', 'none'))
);

CREATE INDEX IF NOT EXISTS idx_challenge_submissions_challenge_id
  ON challenge_submissions (challenge_id);

CREATE INDEX IF NOT EXISTS idx_challenge_submissions_user_id
  ON challenge_submissions (user_id);

CREATE INDEX IF NOT EXISTS idx_challenge_submissions_status
  ON challenge_submissions (status);
