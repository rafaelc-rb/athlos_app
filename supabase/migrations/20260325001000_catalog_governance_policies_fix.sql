-- Allow upsert on catalog_governance_events from mobile clients.
-- Upsert can require UPDATE on conflict, so we expose both INSERT and UPDATE.

DROP POLICY IF EXISTS "Public insert governance events" ON catalog_governance_events;
DROP POLICY IF EXISTS "Public update governance events" ON catalog_governance_events;
DROP POLICY IF EXISTS "Public read governance events" ON catalog_governance_events;

CREATE POLICY "Public insert governance events"
  ON catalog_governance_events
  FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Public update governance events"
  ON catalog_governance_events
  FOR UPDATE
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Public read governance events"
  ON catalog_governance_events
  FOR SELECT
  USING (true);
