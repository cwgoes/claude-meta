---
name: deep-reason
description: Structured reasoning for complex problems requiring careful analysis
constitution: CLAUDE.md
alignment:
  - Cognitive Architecture / Reflection Protocol
  - Failure Protocol
---

# Deep Reasoning Protocol

Use this for problems requiring careful decomposition and analysis beyond simple reflection.

## Constitutional Authority

This skill derives from CLAUDE.md. Key alignments:
- **Reflection Protocol** — Triple reflection for complex decisions
- **Failure Protocol** — Structured escalation when confidence insufficient

## When to Use

- Multiple valid approaches with non-obvious tradeoffs
- High consequence of wrong choice
- Need to surface hidden assumptions
- Complex technical decisions

## Process

### 1. DECOMPOSE
Break into sub-questions:
- What are the independent components?
- What are the dependencies?
- What's the minimal set of questions to answer?

### 2. ANALYZE
For each sub-question:
- State assumptions explicitly
- Identify evidence for/against
- Assign confidence (0.0-1.0)
- Note what would change the answer

### 3. VERIFY
Check your reasoning:
- Are there logical gaps?
- Are assumptions valid?
- What's missing?
- What could be wrong?

### 4. SYNTHESIZE
Combine findings:
- Weight by confidence
- Note where sub-answers conflict
- Identify the overall conclusion

### 5. REFLECT (per Cognitive Architecture)
Apply triple reflection:
- **Error avoidance** — What could go wrong with this conclusion?
- **Success patterns** — What's worked in similar situations?
- **Synthesis** — What's the unified lesson?

### 6. CAPTURE LEARNINGS
Note any non-obvious insights:
- Patterns discovered during analysis
- Assumptions that proved wrong
- Reasoning approaches that worked well

## Output Format

```
## Question
[Restate the core question]

## Decomposition
1. [Sub-question 1]
2. [Sub-question 2]
...

## Analysis
### [Sub-question 1]
- Assumptions: [list]
- Evidence: [for/against]
- Confidence: [0.0-1.0]

### [Sub-question 2]
...

## Synthesis
[Combined conclusion]
Confidence: [0.0-1.0]

## Triple Reflection
- Error avoidance: [what could go wrong]
- Success patterns: [what's worked before]
- Synthesis: [unified lesson]

## Learning Candidates
[Non-obvious insights discovered during reasoning]
- [Candidate]: [brief insight]

## Recommendation
[Clear decision/answer]
```

## Termination Criteria

Stop reasoning when:
- Confidence ≥ 0.8 on the synthesis
- 2 reasoning passes have failed to increase confidence
- Additional analysis would require information you don't have

**NEVER** reason indefinitely. Make a decision with stated confidence.

## Integration with Failure Protocol

If confidence remains < 0.6 after 2 passes:
1. Report the analysis with uncertainty clearly stated
2. Identify what information would increase confidence
3. Capture the failure pattern as a learning candidate
4. Escalate to user for decision or additional input
