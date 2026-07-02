# Themed dishes — the pop-culture shelf

Real dishes whose *copy* tips its hat to gaming and nerd culture. The food
is canonical, cookable, and passes every wave-4 gate like any other dish;
the homage lives in the dish's hero line, captions, intro winks and a tag —
never in the recipe itself and never in a trademark.

## The contract

- **Real archetypes only.** A themed dish is a dish people genuinely cook
  (cinnamon rolls, katsudon, beef stew) whose identity resonates with a
  game, series, or corner of nerd culture. Novelty food that only exists as
  a prop does not pass the scout reviewer.
- **Homage, never trademark.** No franchise names, character names, or
  quoted lines in any field, either language. Allusion carries the wink:
  "a certain snowy province", "a certain testing facility". This keeps a
  commercial app clear of franchise marks; it is enforced as prompt
  guardrails (`THEME_GUARDRAILS` in `pipeline/wave4_lattice.py`) and backed
  by every reviewer stage.
- **The theme changes zero cooking.** Same lattice contract, same honesty
  rules, same allergen machinery as `corpus-brief-4.md`. Recipe titles keep
  selling the food.
- **Routing.** Themed dishes live in the `pop-culture` partition (on
  demand), carry one theme tag in `cuisine_tags` (e.g. `gaming`,
  `game-night`) beside their real cuisine tags, and cross-reference their
  natural cuisine partition via `secondary_partitions`. Recipe-level tags
  make them searchable ("game night" finds the nachos).

## How to add one

```sh
# one dish, end to end (scout → lattice → merge)
pipeline/wave4_lattice.py --new-dish "cinnamon rolls" \
  --theme "Homage: the sweet pastry every guard in a certain nordic
           fantasy RPG suspects you stole. Vibe: cozy, hoardable."

# queue several first, then generate them in parallel
pipeline/wave4_lattice.py --new-dish "katsudon" --theme "..." --queue-only
pipeline/wave4_lattice.py --new-dish "nachos"   --theme "..." --queue-only
pipeline/wave4_lattice.py --jobs 6      # writes all queued lattices, merges

# let codex pick the dish for a theme
pipeline/wave4_lattice.py --suggest-dish --theme "cozy farm-sim harvest food"
```

The brief is persisted per dish under `pipeline/wave4/themes/<dish-id>.md`,
so interrupted runs resume themed. Every stage sees it: scout and scout
reviewer via the request, planner/writer/reviewers via `MODE_NOTES`.

## Why not themed variants of existing dishes?

A "roadhouse burger" is still a burger — per the corpus soul, variants of
an existing dish belong to that dish's lattice, not to a new entry. The
themed shelf therefore only adds archetypes the corpus is missing; an
existing dish keeps its identity. (This is the scout reviewer's
"duplicate in disguise" rule doing its job.)
