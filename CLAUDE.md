# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a collection of reusable skills for Claude Code. Each skill is a self-contained directory with a `SKILL.md` file that provides reference guidance for proven techniques, patterns, or tools.

**Skills are:** Reusable techniques, patterns, tools, and reference guides
**Skills are NOT:** Narratives about how you solved a problem once

## Repository Structure

```
skills/
  skill-name/
    SKILL.md              # Main reference (required)
    supporting-file.*     # Only if needed for heavy reference or reusable tools
```

All skills live in a flat namespace at the repository root. No nested directories.

## SKILL.md Format

Every skill must follow this format:

```yaml
---
name: skill-name-with-hyphens
description: Use when [specific triggering conditions and symptoms]
---

# Skill Name

## Overview
What is this? Core principle in 1-2 sentences.

## When to Use
[Small inline flowchart IF decision non-obvious]
Bullet list with SYMPTOMS and use cases
When NOT to use

## Core Pattern (for techniques/patterns)
Before/after code comparison

## Quick Reference
Table or bullets for scanning common operations

## Implementation
Inline code for simple patterns
Link to file for heavy reference or reusable tools

## Common Mistakes
What goes wrong + fixes
```

**Frontmatter requirements:**
- Only `name` and `description` fields supported (max 1024 chars total)
- `name`: Use letters, numbers, and hyphens only (no parentheses, special chars)
- `description`: Third-person, describes ONLY when to use
  - Start with "Use when..." to focus on triggering conditions
  - Include specific symptoms, situations, and contexts
  - **NEVER summarize the skill's process or workflow**
  - Keep under 500 characters if possible

**Critical principle:** Description = When to Use, NOT What the Skill Does. Summarizing workflow in the description causes agents to follow the description instead of reading the full skill.

## Adding or Modifying Skills

When adding a new skill or modifying an existing one:

1. **Follow the writing-skills skill** - This is the authoritative guide for skill creation, adapted from TDD principles
2. **Test before deploying** - Use subagent pressure scenarios to verify the skill works as intended
3. **Use the Skill tool** - Never use Read to examine skill files; use the Skill tool to invoke them
4. **Keep it concise** - Target <200 words for frequently-loaded skills, <500 words for others

## Supporting Files

Only create separate files when:
- **Heavy reference** (100+ lines) - API docs, comprehensive syntax
- **Reusable tools** - Scripts, utilities, templates

Keep inline:
- Principles and concepts
- Code patterns (< 50 lines)
- Everything else

## README.md Synchronization

**IMPORTANT:** Any change to the directory structure (adding, removing, or renaming skill directories) requires updating `README.md`.

The README.md contains a Chinese table listing all skills with:
- 技能名 (Skill name)
- 触发关键字 (Trigger keywords)
- 使用场景 (Usage scenarios)
- 功能描述 (Function description)

When modifying skills:
1. Add/remove/update the corresponding row in the skills table
2. Maintain the table format and language (Chinese)
3. Commit both the skill changes and README.md together

## Skill Categories

This repository contains skills organized by function:

- **Development workflow** - brainstorming, coding-agent, test-driven-development, systematic-debugging, etc.
- **Documentation** - docs-writer, technical-writer, docs-review, content-creator
- **File processing** - docx, pdf, xlsx, slide
- **Code review** - requesting-code-review, receiving-code-review
- **Agent coordination** - subagent-driven-development, dispatching-parallel-agents
- **Process disciplines** - verification-before-completion, writing-plans, using-git-worktrees
- **Specialized tools** - gh-fix-ci, sessions, java-coding-standards

## Common Patterns

**Flowcharts:** Use inline Graphviz DOT diagrams only for non-obvious decision points. Never use flowcharts for reference material, code examples, or linear instructions.

**Cross-references:** Use skill name only with explicit requirement markers:
- `**REQUIRED SUB-SKILL:** Use skill-name`
- `**REQUIRED BACKGROUND:** You MUST understand skill-name`
- Avoid `@` syntax which force-loads files and consumes context

**Code examples:** One excellent example in the most relevant language beats multiple mediocre examples in different languages.

## Discovery Optimization

Skills must be discoverable by future Claude instances:
- Use descriptive names with active verbs (creating-skills, not skill-creation)
- Include searchable terms (error messages, symptoms, tools, synonyms)
- Start descriptions with "Use when..." focusing on triggering conditions
- Write descriptions in third person (injected into system prompt)
