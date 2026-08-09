---
description: Run the full graph — research, design, human checkpoint, build, review, ship
argument-hint: <mission-slug> <what to build>
allowed-tools: Task, Read, Write, Bash
---

Mission slug: `$1`
Goal: $ARGUMENTS

Run these steps IN ORDER. Do not skip, do not reorder, do not merge steps.
Do not do the work yourself — delegate each node to its subagent via the Task tool.

1. Create `.mission/$1/brief.md` containing the goal above, plus acceptance criteria
   you infer from it. Show it to me.

2. Delegate to the **researcher** subagent. Wait for `.mission/$1/facts.md` to exist.

3. Delegate to the **architect** subagent. Wait for `.mission/$1/plan.md` to exist.

4. HUMAN CHECKPOINT — stop here and print:
   - the step list from plan.md
   - the HIGH-IMPACT section verbatim
   Then ask me: "approve / revise / abort". Do NOT proceed until I reply "approve".
   If I say revise, send my notes back to the architect and repeat step 4.

5. Delegate to the **builder** subagent.

6. Delegate to the **reviewer** subagent.

7. Read the last line of `.mission/$1/review.md`.
   - `VERDICT: FAIL` → send review.md to the builder and return to step 6.
     After 3 failed loops, stop and escalate to me.
   - `VERDICT: PASS` → continue.

8. SHIP — stage the changes and print a commit message. Do not push.
   Print a one-screen summary: what shipped, what was rejected, what's still open.
