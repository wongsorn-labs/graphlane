---
description: Run the full graph — research, design, human checkpoint, build, review, ship
argument-hint: <mission-slug> <what to build>
allowed-tools: Task, Read, Write, Bash
---

Raw arguments: $ARGUMENTS

Do NOT use `$1` anywhere below — Claude Code's positional-argument substitution has been
observed to return the wrong token for mixed-script input (see CLAUDE.md "Known gaps").
Instead, extract the slug yourself: it is the first whitespace-separated token of "Raw
arguments" above, taken byte-for-byte. Do NOT translate it, summarize it, or replace it
with a different word pulled from the rest of the text, even if the rest is in another
language. Everything after that first token is the goal.

Run these steps IN ORDER. Do not skip, do not reorder, do not merge steps.
Do not do the work yourself — delegate each node to its subagent via the Task tool.

1. If "Raw arguments" has no clear first token (empty or missing), STOP and ask me for a
   slug before creating anything. Otherwise state the slug you extracted, then create
   `.mission/<slug>/brief.md` (directory name = that slug, verbatim) containing the goal
   text plus acceptance criteria you infer from it. The "Slug" field inside brief.md must
   match too — do not restate it in another language or wording. Show me the brief.

2. Delegate to the **researcher** subagent, telling it the slug. Wait for
   `.mission/<slug>/facts.md` to exist.

3. Delegate to the **architect** subagent, telling it the slug. Wait for
   `.mission/<slug>/plan.md` to exist.

4. HUMAN CHECKPOINT — stop here and print:
   - the step list from plan.md
   - the HIGH-IMPACT section verbatim
   Then ask me: "approve / revise / abort". Do NOT proceed until I reply "approve".
   If I say revise, send my notes back to the architect and repeat step 4.

5. Delegate to the **builder** subagent, telling it the slug.

6. Delegate to the **reviewer** subagent, telling it the slug.

7. Read the last line of `.mission/<slug>/review.md`.
   - `VERDICT: FAIL` → send review.md to the builder and return to step 6.
     After 3 failed loops, stop and escalate to me.
   - `VERDICT: PASS` → continue.

8. SHIP — stage the changes and print a commit message. Do not push.
   Print a one-screen summary: what shipped, what was rejected, what's still open.
