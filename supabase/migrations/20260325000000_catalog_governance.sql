-- Governance pipeline for multi-device catalog reconciliation.

CREATE TABLE IF NOT EXISTS catalog_governance_events (
  id               BIGSERIAL PRIMARY KEY,
  event_uuid       TEXT NOT NULL UNIQUE,
  event_type       TEXT NOT NULL,
  entity_type      TEXT NOT NULL,
  local_entity_id  INTEGER,
  catalog_remote_id TEXT,
  payload_json     JSONB NOT NULL DEFAULT '{}'::jsonb,
  source           TEXT NOT NULL DEFAULT 'mobile_client',
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS catalog_governance_rules (
  id               BIGSERIAL PRIMARY KEY,
  rule_version     INTEGER NOT NULL,
  action           TEXT NOT NULL,
  entity_type      TEXT NOT NULL,
  winner_remote_id TEXT,
  loser_remote_id  TEXT,
  payload_json     JSONB NOT NULL DEFAULT '{}'::jsonb,
  notes            TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (rule_version, action, entity_type, winner_remote_id, loser_remote_id)
);

CREATE INDEX IF NOT EXISTS idx_catalog_governance_rules_version
  ON catalog_governance_rules (rule_version);

ALTER TABLE catalog_governance_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE catalog_governance_rules ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public insert governance events" ON catalog_governance_events;
DROP POLICY IF EXISTS "Public read governance rules" ON catalog_governance_rules;

CREATE POLICY "Public insert governance events"
  ON catalog_governance_events
  FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Public read governance rules"
  ON catalog_governance_rules
  FOR SELECT
  USING (true);
