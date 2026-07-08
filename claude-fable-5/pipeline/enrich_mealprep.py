#!/usr/bin/env python3
"""One-shot corpus enrichment for the meal-prep update (2026.07).

Three deterministic passes over the bundled recipe partitions:

1. fridge_life_days — how long leftovers keep in the fridge, derived from
   ingredients and techniques (conservative, 1–5 days):
     raw seafood (sushi-style: raw + fish, nothing seared or baked) 1
     raw dishes 2 · cooked seafood 2 · quick egg dishes 2
     cooked rice capped at 2 · long-simmered stews 4 · sweet bakes 5
     everything else 3.

2. total-easy — a category attribute (NOT a variant coordinate, so the
   wave-4 lattice contract is untouched): easy-effort recipes at
   ≤ 25 minutes with ≤ 6 steps. Feierabend food.

3. effort rebalance — dishes whose "medium" column is genuinely a project
   (median ≥ 60 min, minimum ≥ 50 min) get that whole column relabelled
   "hard". Renaming a full per-dish level keeps the effort pair and the
   diet × effort × calorie product intact.

Run from the app assets directory or pass it as argv[1]. Idempotent.
"""

import json
import statistics
import sys
from collections import Counter, defaultdict
from pathlib import Path

CORPUS_VERSION = "2026.07.5"

COOKING_TECHNIQUES = {
    "bake", "saute", "simmer", "grill", "fry", "steam", "roast", "broil",
    "pan-fry", "deep-fry", "stir-fry", "poach", "blanch",
}
SEAFOOD = {"fish", "shellfish", "molluscs"}

TOTAL_EASY_MAX_MINUTES = 25
TOTAL_EASY_MAX_STEPS = 6
HARD_MEDIAN_MINUTES = 60
HARD_MIN_MINUTES = 50


def fridge_life_days(recipe):
    contains = set(recipe["contains"])
    techniques = set(recipe["attributes"]) & COOKING_TECHNIQUES
    ingredient_ids = {i["ingredient_id"] for i in recipe["ingredients"]}
    cooked = bool(techniques)
    seafood = bool(contains & SEAFOOD)

    # Sushi-style: seafood declared raw and nothing actually seared/baked
    # (rice simmering does not cook the fish).
    raw_seafood = (seafood and "raw" in recipe["attributes"]
                   and not (techniques - {"simmer"}))

    if not cooked:
        days = 1 if seafood else 2
    elif raw_seafood:
        days = 1
    elif seafood:
        days = 2
    elif "bake" in techniques and "added-sugar" in contains:
        days = 5  # cookies, brownies, granola — baked through, sugar-cured
    elif "simmer" in techniques and recipe["time_minutes"] >= 60:
        days = 4  # stews, ragùs, long soups — keep better than they started
    else:
        days = 3

    if cooked and any("rice" in i for i in ingredient_ids):
        days = min(days, 2)  # cooked rice is the strictest ingredient
    if "egg" in contains and recipe["time_minutes"] <= 25 \
            and "bake" not in techniques:
        days = min(days, 2)  # quick egg dishes (omelette, shakshuka…)
    return max(1, min(days, 5))


def is_total_easy(recipe):
    return (recipe["variant"]["effort"] == "easy"
            and recipe["time_minutes"] <= TOTAL_EASY_MAX_MINUTES
            and len(recipe["steps"]) <= TOTAL_EASY_MAX_STEPS)


def main():
    assets = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.cwd()
    manifest_path = assets / "partition-manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    partition_files = [Path(p["file"]).name for p in manifest["partitions"]]
    partitions = {f: json.loads((assets / f).read_text(encoding="utf-8"))
                  for f in partition_files}
    recipes = [r for p in partitions.values() for r in p["recipes"]]
    by_dish = defaultdict(list)
    for r in recipes:
        by_dish[r["dish_id"]].append(r)

    # Pass 3 pre-computation: which dishes promote medium -> hard.
    promoted_dishes = set()
    for dish, dish_recipes in by_dish.items():
        efforts = {r["variant"]["effort"] for r in dish_recipes}
        if efforts != {"easy", "medium"}:
            continue
        med_times = [r["time_minutes"] for r in dish_recipes
                     if r["variant"]["effort"] == "medium"]
        if (statistics.median(med_times) >= HARD_MEDIAN_MINUTES
                and min(med_times) >= HARD_MIN_MINUTES):
            promoted_dishes.add(dish)

    stats = Counter()
    for r in recipes:
        r["fridge_life_days"] = fridge_life_days(r)
        stats[f"fridge={r['fridge_life_days']}"] += 1

        attrs = [a for a in r["attributes"] if a != "total-easy"]
        if is_total_easy(r):
            attrs.append("total-easy")
            stats["total-easy"] += 1
        r["attributes"] = attrs

        if r["dish_id"] in promoted_dishes \
                and r["variant"]["effort"] == "medium":
            r["variant"]["effort"] = "hard"
            r["attributes"] = ["hard" if a == "medium" else a
                               for a in r["attributes"]]
            stats["promoted medium->hard"] += 1
        stats[f"effort={r['variant']['effort']}"] += 1

    for name, data in partitions.items():
        (assets / name).write_text(
            json.dumps(data, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8")

    # ontology.json is hand-formatted — the "total-easy" category attribute
    # is added there by hand, not rewritten here.
    manifest["corpus_version"] = CORPUS_VERSION
    manifest_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8")

    print(f"dishes promoted to hard column: {sorted(promoted_dishes)}")
    for key in sorted(stats):
        print(f"  {key}: {stats[key]}")


if __name__ == "__main__":
    main()
