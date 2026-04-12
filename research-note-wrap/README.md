# research-note-wrap

[![License](https://img.shields.io/github/license/leonsong09/research-note-wrap)](https://github.com/leonsong09/research-note-wrap/blob/main/LICENSE)
[![Last Commit](https://img.shields.io/github/last-commit/leonsong09/research-note-wrap)](https://github.com/leonsong09/research-note-wrap/commits/main)
[![GitHub Stars](https://img.shields.io/github/stars/leonsong09/research-note-wrap)](https://github.com/leonsong09/research-note-wrap/stargazers)
[![Repo Size](https://img.shields.io/github/repo-size/leonsong09/research-note-wrap)](https://github.com/leonsong09/research-note-wrap)

> Turn research, issue-triage, and analysis sessions into reusable Markdown conclusion notes.

`research-note-wrap` is a public Codex skill for maintainers and power users who need to compress long analysis sessions into decision-ready notes.

Instead of dumping a chronological transcript, it prioritizes:
- the core questions being answered,
- the evidence behind each conclusion,
- the current recommendation,
- and what still needs follow-up.

## Why OSS maintainers use it

This skill is especially useful for open-source maintenance workflows such as:
- issue triage summaries,
- PR investigation notes,
- release-readiness research,
- architecture comparison writeups,
- contributor handoff notes,
- and postmortem-style analysis conclusions.

If you already use Codex or other agentic tooling for repo maintenance, this skill helps turn raw investigation into something reusable by humans.

## What it does

When triggered, it helps the agent:
1. determine the right scope for the note,
2. extract the main problem statements first,
3. summarize findings into compact comparison tables,
4. separate conclusions from supporting evidence,
5. and produce a reusable Markdown note rather than a verbose recap.

## Best-fit scenarios

Use it when the user wants to:
- summarize research,
- write conclusions,
- output a note,
- produce an analysis memo,
- or wrap a research-heavy session into a reusable artifact.

## Not the best fit

These cases are better served by related skills:
- current coding-session wrap-up: [`session-wrap`](https://github.com/leonsong09/session-wrap)
- commit-based daily summary: [`commit-daily-summary`](https://github.com/leonsong09/commit-daily-summary)
- project-level same-day report: [`project-daily-summary`](https://github.com/leonsong09/project-daily-summary)
- multi-worktree closeout triage: [`worktree-closeout`](https://github.com/leonsong09/worktree-closeout)

## Trigger phrases

Chinese:
- 总结调研
- 输出结论
- 总结分析
- 输出笔记
- 调研纪要
- 分析纪要

English:
- summarize the research
- write the conclusions
- output a note
- summarize the investigation

## Workflow

1. Determine scope first: default to the current session; expand only when the user clearly asks for same-day or broader related context.
2. Extract the main questions before the narrative.
3. Prefer comparison tables over chronological logs.
4. Separate key conclusions from the evidence that supports them.
5. If the note is saved to disk, respect the destination rules in `AGENTS.md` when present.
6. If code references are included, explain why those code locations support the conclusion.

## Example output shape

See [`examples/maintainer-note-example.md`](./examples/maintainer-note-example.md) for a fuller sample.

```markdown
## Problem Comparison
| Topic | Signal | Core Judgment | Current Conclusion | Impact |
|---|---|---|---|---|
| Issue A | ... | ... | ... | ... |

## Conclusion Table
| Conclusion | Evidence | Confidence | Next Step |
|---|---|---|---|
| A | ... | High | ... |

## Key Conclusions
- ...
```

## Installation

Copy this directory into your local skill directory, for example:

```text
~/.codex/skills/research-note-wrap
```

or:

```text
~/.agents/skills/research-note-wrap
```

## Repository structure

```text
research-note-wrap/
  SKILL.md
  README.md
  LICENSE
  .gitignore
  agents/
  examples/
```

## Configuration

This public repo intentionally does not hardcode any private note directory.

Recommended practice:
- define a default note destination in project-level `AGENTS.md`, or
- ask the user where the note should be saved the first time.

## Related public workflow skills

This repository is part of a public maintainer-workflow skill set:
- [`research-note-wrap`](https://github.com/leonsong09/research-note-wrap)
- [`session-wrap`](https://github.com/leonsong09/session-wrap)
- [`commit-daily-summary`](https://github.com/leonsong09/commit-daily-summary)
- [`project-daily-summary`](https://github.com/leonsong09/project-daily-summary)
- [`worktree-closeout`](https://github.com/leonsong09/worktree-closeout)

## Limitations

- It does not replace real research; it only compresses existing research into a readable conclusion note.
- If cross-session evidence is weak, the uncertainty should remain explicit.
- If the user actually needs long-term topic research rather than session summarization, the scope should be clarified first.

## License

MIT
