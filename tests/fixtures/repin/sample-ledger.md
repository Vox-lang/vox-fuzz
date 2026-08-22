# Fake ledger — one row per citation shape the repin tool has to get right

Source: `../vox/LANGUAGE.md` lines 3-9 (the ledger header form).
And the other header spelling: LANGUAGE.md line 3.

| id | line | claim | status |
|---|---|---|---|
| FAK-01 | 3 | above every hunk — must not move | todo |
| FAK-02 | 12 | below the insertion — must gain 2 | todo |
| FAK-03 | 12-14 | an ascii range — both ends map | todo |
| FAK-04 | 12–14 | an en dash range — both ends map, dash kept | todo |
| FAK-05 | 3, 12 | a comma pair — each item maps on its own | todo |
| FAK-06 | 12, 20-21 | a comma pair whose second item is a range | todo |
| FAK-07 | 20 | the claim's text was rewritten — becomes ? | todo |
| FAK-08 | 21 | the claim survives further down — recovered as moved | todo |
| FAK-09 | 25 | the claim was deleted outright — becomes ? | todo |
| FAK-10 | 28 | below the deletion as well as the insertion | todo |
| FAK-11 | 3 (undocumented precision) | only the leading run is a citation | todo |
| FAK-12 | see `FAK-01.vox` | digits, but no citation — must be flagged, not rewritten | todo |
| FAK-13 | — | no citation at all | todo |

A table with no `line` column is left alone entirely:

| who | says |
|---|---|
| 12 | this 12 is not a line number and must not move |

Prose citations: LANGUAGE.md:12, and LANGUAGE.md:20-21, and LANGUAGE.md:3, 28.
A citation that runs into a row ID: LANGUAGE.md:12, 28, FAK-02 — the ID keeps its digits.
Bare numbers in prose (12, 20, 25) are not citations and must not move.
Vox 0.4.9 is a version, not a line.
