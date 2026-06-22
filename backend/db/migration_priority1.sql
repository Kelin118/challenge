-- =============================================================================
-- AchivmentMVP — Migration Priority 1
-- Safe to run on existing production DB (idempotent)
-- Covers: groups, likes, follows, user_medal_showcase, title_definitions,
--         moderation_type on challenges, registration_bonus transaction type
-- =============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. GROUPS
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS groups (
  id          SERIAL PRIMARY KEY,
  name        TEXT NOT NULL UNIQUE,
  slug        TEXT NOT NULL UNIQUE,           -- URL-friendly, e.g. 'football'
  description TEXT,
  icon_url    TEXT,
  cover_url   TEXT,
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order  INTEGER NOT NULL DEFAULT 0,
  created_at  TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_groups_slug       ON groups (slug);
CREATE INDEX IF NOT EXISTS idx_groups_is_active  ON groups (is_active);
CREATE INDEX IF NOT EXISTS idx_groups_sort_order ON groups (sort_order);

-- Seed initial groups (matches hardcoded Flutter list + extras)
INSERT INTO groups (name, slug, sort_order) VALUES
  ('Футбол',     'football',    1),
  ('CSGO',       'csgo',        2),
  ('Кино',       'cinema',      3),
  ('Спорт',      'sport',       4),
  ('Музыка',     'music',       5),
  ('Фитнес',     'fitness',     6),
  ('Игры',       'gaming',      7),
  ('Образование','education',   8)
ON CONFLICT (slug) DO NOTHING;

-- Link challenges to groups (a challenge already has `category` TEXT;
-- groups.slug mirrors the category value so we keep backward compat)
CREATE TABLE IF NOT EXISTS challenge_groups (
  challenge_id INTEGER NOT NULL REFERENCES challenges(id)  ON DELETE CASCADE,
  group_id     INTEGER NOT NULL REFERENCES groups(id)      ON DELETE CASCADE,
  PRIMARY KEY (challenge_id, group_id)
);

CREATE INDEX IF NOT EXISTS idx_challenge_groups_group_id ON challenge_groups (group_id);

-- Link users to groups they follow
CREATE TABLE IF NOT EXISTS user_group_follows (
  user_id    INTEGER NOT NULL REFERENCES users(id)   ON DELETE CASCADE,
  group_id   INTEGER NOT NULL REFERENCES groups(id)  ON DELETE CASCADE,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, group_id)
);

CREATE INDEX IF NOT EXISTS idx_user_group_follows_user_id  ON user_group_follows (user_id);
CREATE INDEX IF NOT EXISTS idx_user_group_follows_group_id ON user_group_follows (group_id);

-- ---------------------------------------------------------------------------
-- 2. CHALLENGE LIKES
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS challenge_likes (
  user_id      INTEGER NOT NULL REFERENCES users(id)       ON DELETE CASCADE,
  challenge_id INTEGER NOT NULL REFERENCES challenges(id)  ON DELETE CASCADE,
  created_at   TIMESTAMP NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, challenge_id)
);

CREATE INDEX IF NOT EXISTS idx_challenge_likes_challenge_id ON challenge_likes (challenge_id);
CREATE INDEX IF NOT EXISTS idx_challenge_likes_user_id      ON challenge_likes (user_id);

-- Denormalised counter on challenges (avoids COUNT(*) on hot path)
ALTER TABLE challenges
  ADD COLUMN IF NOT EXISTS likes_count INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS saves_count INTEGER NOT NULL DEFAULT 0;

ALTER TABLE challenges
  DROP CONSTRAINT IF EXISTS chk_challenges_likes_count,
  DROP CONSTRAINT IF EXISTS chk_challenges_saves_count;

ALTER TABLE challenges
  ADD CONSTRAINT chk_challenges_likes_count CHECK (likes_count >= 0),
  ADD CONSTRAINT chk_challenges_saves_count CHECK (saves_count >= 0);

-- Trigger: keep likes_count in sync
CREATE OR REPLACE FUNCTION trg_challenge_likes_count()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE challenges SET likes_count = likes_count + 1 WHERE id = NEW.challenge_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE challenges SET likes_count = GREATEST(likes_count - 1, 0) WHERE id = OLD.challenge_id;
  END IF;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_challenge_likes_insert ON challenge_likes;
CREATE TRIGGER trg_challenge_likes_insert
  AFTER INSERT ON challenge_likes
  FOR EACH ROW EXECUTE FUNCTION trg_challenge_likes_count();

DROP TRIGGER IF EXISTS trg_challenge_likes_delete ON challenge_likes;
CREATE TRIGGER trg_challenge_likes_delete
  AFTER DELETE ON challenge_likes
  FOR EACH ROW EXECUTE FUNCTION trg_challenge_likes_count();

-- ---------------------------------------------------------------------------
-- 3. CHALLENGE SAVES (bookmarks)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS challenge_saves (
  user_id      INTEGER NOT NULL REFERENCES users(id)       ON DELETE CASCADE,
  challenge_id INTEGER NOT NULL REFERENCES challenges(id)  ON DELETE CASCADE,
  created_at   TIMESTAMP NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, challenge_id)
);

CREATE INDEX IF NOT EXISTS idx_challenge_saves_user_id      ON challenge_saves (user_id);
CREATE INDEX IF NOT EXISTS idx_challenge_saves_challenge_id ON challenge_saves (challenge_id);

-- Trigger: keep saves_count in sync
CREATE OR REPLACE FUNCTION trg_challenge_saves_count()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE challenges SET saves_count = saves_count + 1 WHERE id = NEW.challenge_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE challenges SET saves_count = GREATEST(saves_count - 1, 0) WHERE id = OLD.challenge_id;
  END IF;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_challenge_saves_insert ON challenge_saves;
CREATE TRIGGER trg_challenge_saves_insert
  AFTER INSERT ON challenge_saves
  FOR EACH ROW EXECUTE FUNCTION trg_challenge_saves_count();

DROP TRIGGER IF EXISTS trg_challenge_saves_delete ON challenge_saves;
CREATE TRIGGER trg_challenge_saves_delete
  AFTER DELETE ON challenge_saves
  FOR EACH ROW EXECUTE FUNCTION trg_challenge_saves_count();

-- ---------------------------------------------------------------------------
-- 4. USER FOLLOWS
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_follows (
  follower_id  INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  following_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at   TIMESTAMP NOT NULL DEFAULT NOW(),
  PRIMARY KEY (follower_id, following_id),
  CONSTRAINT chk_user_follows_no_self_follow CHECK (follower_id <> following_id)
);

CREATE INDEX IF NOT EXISTS idx_user_follows_follower_id  ON user_follows (follower_id);
CREATE INDEX IF NOT EXISTS idx_user_follows_following_id ON user_follows (following_id);

-- Denormalised counters on users
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS followers_count  INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS following_count  INTEGER NOT NULL DEFAULT 0;

ALTER TABLE users
  DROP CONSTRAINT IF EXISTS chk_users_followers_count,
  DROP CONSTRAINT IF EXISTS chk_users_following_count;

ALTER TABLE users
  ADD CONSTRAINT chk_users_followers_count CHECK (followers_count >= 0),
  ADD CONSTRAINT chk_users_following_count CHECK (following_count >= 0);

-- Trigger: keep follower/following counts in sync
CREATE OR REPLACE FUNCTION trg_user_follows_count()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE users SET following_count = following_count + 1 WHERE id = NEW.follower_id;
    UPDATE users SET followers_count = followers_count + 1 WHERE id = NEW.following_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE users SET following_count = GREATEST(following_count - 1, 0) WHERE id = OLD.follower_id;
    UPDATE users SET followers_count = GREATEST(followers_count - 1, 0) WHERE id = OLD.following_id;
  END IF;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_user_follows_insert ON user_follows;
CREATE TRIGGER trg_user_follows_insert
  AFTER INSERT ON user_follows
  FOR EACH ROW EXECUTE FUNCTION trg_user_follows_count();

DROP TRIGGER IF EXISTS trg_user_follows_delete ON user_follows;
CREATE TRIGGER trg_user_follows_delete
  AFTER DELETE ON user_follows
  FOR EACH ROW EXECUTE FUNCTION trg_user_follows_count();

-- ---------------------------------------------------------------------------
-- 5. USER MEDAL SHOWCASE
--    Top-3 pinned medals shown on profile
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_medal_showcase (
  id             SERIAL PRIMARY KEY,
  user_id        INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  achievement_id INTEGER NOT NULL REFERENCES user_achievements(id) ON DELETE CASCADE,
  slot_position  INTEGER NOT NULL,           -- 1, 2, or 3
  pinned_at      TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_medal_showcase_user_slot    UNIQUE (user_id, slot_position),
  CONSTRAINT uq_medal_showcase_user_achieve UNIQUE (user_id, achievement_id),
  CONSTRAINT chk_medal_showcase_slot CHECK (slot_position BETWEEN 1 AND 3)
);

CREATE INDEX IF NOT EXISTS idx_user_medal_showcase_user_id ON user_medal_showcase (user_id);

-- ---------------------------------------------------------------------------
-- 6. TITLE DEFINITIONS (звания / плашки)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS title_definitions (
  id           SERIAL PRIMARY KEY,
  key          TEXT NOT NULL UNIQUE,
  label        TEXT NOT NULL,               -- displayed in UI
  description  TEXT,
  icon         TEXT,                        -- emoji or icon key
  color_hex    TEXT,                        -- badge colour, e.g. '#FFD700'
  trigger_type TEXT NOT NULL,               -- how the title is awarded
  trigger_value INTEGER NOT NULL DEFAULT 1, -- threshold value
  is_active    BOOLEAN NOT NULL DEFAULT TRUE,
  created_at   TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT chk_title_definitions_trigger_type CHECK (
    trigger_type IN (
      'challenges_completed',   -- N challenges done
      'coins_earned_total',     -- total lifetime coins
      'followers_count',        -- follower milestone
      'streak_days',            -- consecutive active days
      'manual'                  -- assigned by admin
    )
  ),
  CONSTRAINT chk_title_definitions_trigger_value CHECK (trigger_value > 0)
);

CREATE INDEX IF NOT EXISTS idx_title_definitions_trigger_type ON title_definitions (trigger_type);

-- Seed default titles
INSERT INTO title_definitions (key, label, description, icon, color_hex, trigger_type, trigger_value) VALUES
  ('newcomer',      'Новичок',         'Первый выполненный челлендж',      '🌱', '#78C758', 'challenges_completed',  1),
  ('challenger',    'Челленджер',      '10 выполненных челленджей',        '⚡', '#4A90D9', 'challenges_completed', 10),
  ('pro',           'Профи',           '50 выполненных челленджей',        '🔥', '#E67E22', 'challenges_completed', 50),
  ('legend',        'Легенда',         '100 выполненных челленджей',       '👑', '#F1C40F', 'challenges_completed',100),
  ('coin_starter',  'Монетчик',        '500 монет заработано суммарно',    '💰', '#2ECC71', 'coins_earned_total',  500),
  ('coin_master',   'Мастер монет',    '5000 монет заработано суммарно',   '💎', '#9B59B6', 'coins_earned_total', 5000),
  ('popular',       'Популярный',      '100 подписчиков',                  '⭐', '#E74C3C', 'followers_count',     100),
  ('influencer',    'Инфлюенсер',      '1000 подписчиков',                 '🚀', '#E74C3C', 'followers_count',    1000)
ON CONFLICT (key) DO NOTHING;

-- Which title a user currently wears (active display title)
CREATE TABLE IF NOT EXISTS user_titles (
  user_id          INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title_id         INTEGER NOT NULL REFERENCES title_definitions(id) ON DELETE CASCADE,
  awarded_at       TIMESTAMP NOT NULL DEFAULT NOW(),
  is_active_display BOOLEAN NOT NULL DEFAULT FALSE, -- the one shown on profile
  PRIMARY KEY (user_id, title_id)
);

CREATE INDEX IF NOT EXISTS idx_user_titles_user_id          ON user_titles (user_id);
CREATE INDEX IF NOT EXISTS idx_user_titles_is_active_display ON user_titles (is_active_display) WHERE is_active_display = TRUE;

-- ---------------------------------------------------------------------------
-- 7. MODERATION TYPE on challenges
-- ---------------------------------------------------------------------------
ALTER TABLE challenges
  ADD COLUMN IF NOT EXISTS moderation_type TEXT NOT NULL DEFAULT 'creator';

ALTER TABLE challenges
  DROP CONSTRAINT IF EXISTS chk_challenges_moderation_type;

ALTER TABLE challenges
  ADD CONSTRAINT chk_challenges_moderation_type
    CHECK (moderation_type IN ('team', 'community', 'creator'));

-- Community moderation votes (for moderation_type = 'community')
CREATE TABLE IF NOT EXISTS submission_votes (
  id            SERIAL PRIMARY KEY,
  submission_id INTEGER NOT NULL REFERENCES challenge_submissions(id) ON DELETE CASCADE,
  voter_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  vote          TEXT NOT NULL,
  voted_at      TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_submission_votes_voter UNIQUE (submission_id, voter_user_id),
  CONSTRAINT chk_submission_votes_vote CHECK (vote IN ('approve', 'reject'))
);

CREATE INDEX IF NOT EXISTS idx_submission_votes_submission_id ON submission_votes (submission_id);
CREATE INDEX IF NOT EXISTS idx_submission_votes_voter_user_id ON submission_votes (voter_user_id);

-- ---------------------------------------------------------------------------
-- 8. REGISTRATION BONUS — add to allowed transaction_type values
-- ---------------------------------------------------------------------------
ALTER TABLE coin_transactions
  DROP CONSTRAINT IF EXISTS chk_coin_transactions_type;

ALTER TABLE coin_transactions
  ADD CONSTRAINT chk_coin_transactions_type CHECK (
    transaction_type IN (
      'registration_bonus',
      'challenge_creation_cost',
      'challenge_reward',
      'challenge_creator_reward',
      'manual_adjustment',
      'refund'
    )
  );

-- ---------------------------------------------------------------------------
-- Done
-- ---------------------------------------------------------------------------
COMMIT;