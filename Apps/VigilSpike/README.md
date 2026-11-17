# VigilSpike

A test app, not the Vigil product. It answers one question: can an Apple Watch feed Vigil's alert rule reliably enough to be worth building on?

## What it does

- The watch app runs a workout session, reads heart rate about every 5 seconds, counts wrist movement, and sends one row to the iPhone every 5 seconds.
- The iPhone app shows the live numbers, runs alert rule v0.1 from `specs/alert-rule-v0.1.md` in the Vigil project, and writes every row to a CSV file you can share.
- A button on the iPhone starts the watch alert, and another stops it.
- A switch on the iPhone decides whether the rule vibrates the watch when it fires. It starts off, so the first sits record your body without alerts.

## Differences from the real Vigil app

- The session starts on the watch. In Vigil, the nurse starts it from the iPhone.
- The alert is firm taps that repeat until she turns her wrist. If she doesn't turn it within 30 seconds, the iPhone marks the nurse as alerted. The spike only logs this; Vigil will notify the nurse.
- Sits are not saved to the Health app.

## CSV columns

| Column | Meaning |
|---|---|
| time | When the watch made the row |
| received_at | When the iPhone got it |
| delivery_delay_s | received_at minus time |
| heart_rate_bpm | Latest heart rate on the watch |
| hr_sample_age_s | Seconds since that heart rate was measured |
| movement_count | Movement readings in the last 5 seconds |
| rule_state | baseline, watching, drowsy, alerting, nurse alerted, signal lost, or late |
| baseline_bpm | The session baseline, once set at minute 6 |
| event | Session start and end, rule events, alerts, wrist turns |
| delivery | live, or queued if the iPhone was out of reach |

## Settings

The rule's numbers live in `VigilSpike/AlertRule.swift`, in `AlertRuleSettings`. Change one there and run the app again.
