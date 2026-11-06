# 12 — Sizing: Capacity Units and Machines

A trainer books a workshop for N seats; Orbital decides **how many machines to buy**. It does that with one number per machine and one number per training:

```text
seats per machine = units(instance) // units(training)
```

## The unit

**One unit is one Kubernetes-101 session** — the workload measured most, across five load tests. Everything else is priced relative to it, so a box that holds 20 Kubernetes-101 sessions and one that holds 5 Astroshop sessions are both "a 20-unit machine".

| Training | Units | Seats on m6a.4xlarge (20 units) | Seats on m6a.2xlarge (10 units) | Where the number comes from |
|---|---|---|---|---|
| Kubernetes 101 | 1 | 20 → **15** (the per-worker seat cap) | 10 | measured — it *is* the unit |
| Astroshop (`demo-astroshop-problems`) | 4 | **5** | 2 | measured: ~7 GiB per session at plateau |
| **any training nobody measured** | **4** | **5** | 2 | `HEAVY_DEFAULT` — priced like Astroshop, flagged *estimated* |

The machine numbers are **measurements, not a formula**: 20 sessions on an m6a.4xlarge passed 20/20; 30 passed 0/30.

## Two rules that only ever reduce the number

- **An unmeasured training is priced as the heaviest one known.** A new training you never measured plans 5 seats per m6a.4xlarge. The opposite default oversells, and the workshop fails in front of the room.
- **Physical memory clamps a derived figure.** Scaling by size class can lower a number, never raise one.

So a light training should be **measured**: an operator records its units (`repo:units`) after a load test, and from then on it plans more seats per machine. Until then it costs four units — safe, never cheap.

## What a workshop books

- **Seats planned = `maxSeats` + the trainer team** — the capacity *booked*, never the turnout. Learners join with a code and never touch a roster.
- **Small workshops launch nothing.** At or below the standing lane's seat cap, the workshop rides a standing box that is always there. Read the cap from the host (`GET /api/workshops/{id}/fleet` → `standing_max_seats`); it is a setting, not a constant.
- **Prewarm and hold.** Machines launch `prewarmLeadMinutes` (default 45, up to 6 h) before the start and are held at least `holdMinutes` (default 240) — never shorter than the booking itself. The trainer sees and can move both in the workshop's fleet banner.

## The shared machine's shape

A shared-infrastructure training can ask for its machine in `delivery.yaml`:

```yaml title=".devcontainer/delivery.yaml (excerpt)"
shared:
  instance: m6a.4xlarge
```

It is checked when the workshop is booked, against the settings at that moment: the allowlist (default `m6a.2xlarge, m6a.4xlarge, r6a.2xlarge, r6a.4xlarge`), a memory ceiling (default 128 GiB) and the capacity table — a shape nobody has measured is refused even when allowlisted. A refused shape is **refused** (`400 shared_instance_not_allowed`), never silently replaced. Without `shared:`, the workshop gets the default shared machine.

## Design for the box you will get

- Keep the per-learner footprint small: deploy what the lesson needs, not the whole catalog. Every app you add in `post-create.sh` is paid for by every seat.
- Start-up is the peak: a full machine of sessions installing at once reaches ~94% CPU for minutes. Orbital paces admission for that — do not add parallel installs of your own.
- A training that needs more than one Astroshop's footprint per learner is a candidate for **shared infrastructure** ([previous module](m4-shared-workshops.md)).

<!-- LAB_QUESTION
type: multiple-choice
question: "You publish a new training and nobody has measured it. A trainer books 20 seats. How many seats does Orbital plan per m6a.4xlarge?"
options:
  - "20 — the machine holds 20 units"
  - "15 — the per-worker cap"
  - "5 — an unmeasured training is priced at 4 units, like Astroshop"
  - "It refuses to plan until the training is measured"
correct: 2
explanation: "Unmeasured trainings cost HEAVY_DEFAULT = 4 units, so 20 // 4 = 5 seats per machine: four machines for 20 seats. Measure the training to plan more seats per box."
-->

<!-- LAB_QUESTION
type: multiple-choice
question: "A workshop is booked with maxSeats 40 and a trainer team of 2, but only 25 learners turn up. What did Orbital plan for?"
options:
  - "25 seats — the turnout"
  - "42 seats — the booked capacity plus the trainer team"
  - "40 seats — maxSeats only"
  - "1 seat — the roster"
correct: 1
explanation: "Seats planned = maxSeats + the trainer team: the capacity booked, never the turnout."
-->

<!-- LAB_NO_SOLUTION: reading step with knowledge checks — sizing is decided by Orbital, nothing runs in the environment -->
