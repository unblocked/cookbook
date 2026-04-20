# Finding Categories

Ordered by priority. When reporting, group findings by category in this order.

## 1. Pattern Mismatch

The PR uses approach X, but the team has an established pattern Y for this kind of thing. Most common and highest-value finding from context-aware review.

**Validate with:** `context_research` (`effort: low`) — "Does the team use [pattern X or Y] for [this kind of thing]?"

## 2. Reinvented Wheel

The PR creates something that already exists as a utility, helper, or shared module in the codebase.

**Validate with:** `context_research` (`effort: low`) — "Does a utility for [X] already exist?"

## 3. Convention Drift

The code works but doesn't match how the team writes this kind of code — naming, error handling, file organization, testing approach.

## 4. Missing Context

The PR doesn't account for a related system, a recent change, a known constraint, or a decision that Unblocked surfaces.

## 5. Risk

The change could cause issues based on historical patterns, known edge cases, or prior incidents in this area.
