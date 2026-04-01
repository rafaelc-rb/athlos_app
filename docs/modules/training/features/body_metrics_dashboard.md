# Body Metrics Dashboard Feature Spec

## Status

Proposed

## Motivation

The app already stores body metrics (`weight`, optional `bodyFatPercent`) and already has a weekly prompt logic for stale weight updates. However, the current UX is fragmented:

- Summary appears in Profile
- Prompt appears as an isolated banner in Training Home
- There is no single dashboard component that combines status, trend, and action

This feature consolidates body-metrics feedback into one reusable dashboard card.

## Problem Statement

Users need an at-a-glance understanding of:

1. Current body metrics state
2. Whether tracking is up to date
3. Whether trend is moving in the desired direction
4. What action to take next

Current experience does not provide this in one place.

## Scope

### In Scope

- New unified dashboard card for body metrics
- Merge current stale-weight prompt behavior into the card
- Clear states for empty, up-to-date, and stale data
- Incremental rollout in V1, V2, V3

### Out of Scope

- Clinical interpretation of body composition
- Personalized medical advice
- Push notifications (this spec covers in-app dashboard behavior)

## UX Model

Single component in Training Home:

- `Body Metrics Dashboard Card`

Card responsibilities:

- Show latest weight and optional body-fat value
- Show freshness (`updated X days ago`)
- Show simple delta trend
- Show context alert when stale
- Provide immediate CTA to record a new entry

## Functional Requirements

### Data Rules

- Weight stale threshold: `>= 7 days` since latest weight entry
- Body fat stale threshold (initial): `>= 21 days` since latest body-fat entry
- Empty-state rule: no body metrics entries yet

### Priority of Card State

1. Empty state
2. Stale state
3. Up-to-date state

### Required Actions

- Record metric from dashboard card
- Open full history/details from dashboard card

## Delivery Plan

## V1 — Unified Card (MVP)

Goal: replace isolated alert banner with one useful card.

Includes:

- Latest weight
- Latest body-fat percentage (if present)
- Updated-at age (`X days ago`)
- Basic delta vs previous entry
- Embedded stale warning
- CTA `Record now`

Acceptance:

- If stale, card always communicates stale status
- If empty, card clearly asks for first entry
- Banner can be removed without losing stale-weight guidance

## V2 — Trend Clarity

Goal: improve progress readability.

Includes:

- Mini trend chart (recent points)
- Period quick filter (`4w`, `8w`, `12w`)
- Optional weekly average line/smoothing

Acceptance:

- Trend is understandable without opening history
- No additional mandatory user input introduced

## V3 — Insight Layer

Goal: convert data into guidance.

Includes:

- Goal-aware trend feedback (cut, maintain, gain)
- More nuanced stale alerts by metric type
- Stagnation hints (trend flat for N weeks)

Acceptance:

- Insights are informational, never blocking
- Users can still track metrics manually without suggestions

## Technical Notes

- Keep provider logic modular:
  - raw timeline provider
  - dashboard state provider (derived)
- Avoid duplicate stale logic between widgets
- Keep chart/insight layers additive over V1 state model

## Risks

- Overloading card with too much information
- Inconsistent stale calculations across screens
- Trend noise causing misleading interpretation

## Mitigations

- Progressive disclosure (summary on card, detail on tap)
- Single source of truth for freshness logic
- Prefer smoothed trend display over raw daily fluctuations

## Success Indicators

- Increased frequency of metric updates per user
- Reduced time gap between weight entries
- More users with >=2 historical metric records
