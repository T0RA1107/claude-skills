---
name: deep-review
description: Performs a careful, thorough, and critical review of current code changes by analyzing the git diff against the main branch.
---

# Deep Review Skill

## Purpose
This skill is designed for a rigorous and holistic review of code changes. It moves beyond simple syntax checking to evaluate the underlying intent, design efficiency, and potential architectural pitfalls.

## Phase 1: Context Gathering (The Diff)
First, identify the changes by checking the diff against the main branch. Execute these commands in order of priority until a diff is found:
1. `git diff --cached` (Staged changes)
2. `git diff` (Unstaged changes)
3. `git diff main..HEAD` or `git diff master..HEAD` (Committed changes on the feature branch)

## Phase 2: Cognitive Analysis
Before providing feedback, perform a deep mental walkthrough of the changes:

### 1. Intent Discovery
- What is the fundamental goal of this change? 
- What problem is it trying to solve, and what is the "why" behind it?

### 2. Value Assessment
- How does this change achieve its goal?
- List the clear benefits, improvements, and strengths of this implementation.

### 3. Critical Critique
- **Potential Pitfalls**: What could go wrong? Think about edge cases, performance bottlenecks, or side effects. (Note: Do not worry about backwards compatibility).
- **Missing Elements**: Is there an obvious requirement, test case, or error handling that was overlooked?
- **Potential Improvements**: How can we make the logic more robust or cleaner?

## Phase 3: Simplification Strategy
Evaluate if the solution can be made more elegant:
- **High-level Design**: Can the overall approach be simplified? Is the architecture over-engineered?
- **Implementation**: Are there specific code blocks that can be rewritten more concisely or efficiently?

## Workflow
1. **Fetch Diff**: Execute the git commands to see the code.
2. **Internal Review**: Follow the analysis steps in Phase 2 & 3.
3. **Report**: Present a structured review to the user, highlighting Intent, Benefits, Risks, and specific Simplification suggestions.
