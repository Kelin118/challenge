CREATE TABLE IF NOT EXISTS achievement_definitions (
  id SERIAL PRIMARY KEY,
  key TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL,
  rarity TEXT NOT NULL DEFAULT 'common',
  icon TEXT NOT NULL,
  xp_reward INTEGER NOT NULL DEFAULT 0 CHECK (xp_reward >= 0),
  target_value INTEGER NOT NULL DEFAULT 1 CHECK (target_value > 0),
  is_hidden BOOLEAN NOT NULL DEFAULT FALSE,
  verification_type TEXT NOT NULL DEFAULT 'none',
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT chk_achievement_definitions_rarity
    CHECK (rarity IN ('common', 'rare', 'epic', 'legendary')),
  CONSTRAINT chk_achievement_definitions_verification_type
    CHECK (verification_type IN ('none', 'text', 'ai_text'))
);

CREATE INDEX IF NOT EXISTS idx_achievement_definitions_category
  ON achievement_definitions (category);

CREATE INDEX IF NOT EXISTS idx_achievement_definitions_rarity
  ON achievement_definitions (rarity);

CREATE TABLE IF NOT EXISTS user_achievements (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  achievement_definition_id INTEGER NOT NULL REFERENCES achievement_definitions(id) ON DELETE CASCADE,
  progress INTEGER NOT NULL DEFAULT 0 CHECK (progress >= 0),
  is_unlocked BOOLEAN NOT NULL DEFAULT FALSE,
  unlocked_at TIMESTAMP NULL,
  verification_status TEXT NOT NULL DEFAULT 'none',
  last_evidence_text TEXT,
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_user_achievement UNIQUE (user_id, achievement_definition_id),
  CONSTRAINT chk_user_achievements_verification_status
    CHECK (verification_status IN ('none', 'pending', 'approved', 'rejected'))
);

CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id
  ON user_achievements (user_id);

CREATE INDEX IF NOT EXISTS idx_user_achievements_definition_id
  ON user_achievements (achievement_definition_id);

CREATE INDEX IF NOT EXISTS idx_user_achievements_unlocked
  ON user_achievements (is_unlocked);

CREATE TABLE IF NOT EXISTS user_stats (
  user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  total_xp INTEGER NOT NULL DEFAULT 0 CHECK (total_xp >= 0),
  level INTEGER NOT NULL DEFAULT 1 CHECK (level >= 1),
  unlocked_count INTEGER NOT NULL DEFAULT 0 CHECK (unlocked_count >= 0),
  achievements_count INTEGER NOT NULL DEFAULT 0 CHECK (achievements_count >= 0),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

