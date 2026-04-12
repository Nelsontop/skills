# project-daily-summary

<p align="center">
    <a href="https://linux.do" alt="LINUX DO"><img src="https://shorturl.at/ggSqS" /></a>
</p>

[![License](https://img.shields.io/github/license/leonsong09/project-daily-summary)](https://github.com/leonsong09/project-daily-summary/blob/main/LICENSE)
[![Last Commit](https://img.shields.io/github/last-commit/leonsong09/project-daily-summary)](https://github.com/leonsong09/project-daily-summary/commits/main)
[![Repo Size](https://img.shields.io/github/repo-size/leonsong09/project-daily-summary)](https://github.com/leonsong09/project-daily-summary)

> 按项目汇总当天的 Codex 工作，整合同日会话、计划、完成事项、提交与未提交改动，输出高密度日报。

## 适用场景

当用户想要：
- 项目日报
- 日报
- 今日工作总结
- 按项目总结今天
- 总结今天所有 Codex 会话
- 总结今天会话 + 提交 + 未提交改动

## 不适用场景

以下情况更适合其他 skill：
- 当前单次会话收尾：`session-wrap`
- 纯提交日报：`commit-daily-summary`
- 调研/分析结论整理：`research-note-wrap`
- worktree / branch 收口盘点：`worktree-closeout`

## 触发词

中文：
- 项目日报
- 日报
- 今日工作总结
- 按项目总结今天
- 总结今天所有 Codex 会话
- 总结今天会话+提交+未提交改动

English:
- daily report
- summarize today's Codex work
- summarize today's sessions by project

## 工作流

1. 以本地当天日期为准确定时间范围。
2. 读取当天 Codex session transcript，并映射到项目根目录。
3. 以项目为主轴整合同主会话与子代理证据。
4. 再补充 git 提交与未提交改动。
5. 最终按“项目 -> 工作流/主题”输出，而不是按时间流水账输出。
6. 若用户额外要求当天的收口附录，可追加调用 `worktree-closeout`。

## 安装

将整个目录复制到本地技能目录，例如：

```text
~/.codex/skills/project-daily-summary
```

或：

```text
~/.agents/skills/project-daily-summary
```

## 仓库结构

```text
project-daily-summary/
  SKILL.md
  README.md
  LICENSE
  .gitignore
  agents/
```

## 配置

公开版不硬编码任何私人日报目录。

推荐做法：
- 在项目 `AGENTS.md` 中配置日报输出目录；或
- 首次使用时询问输出路径。

建议文件名格式：

```text
YYYY-MM-DD-project-daily-summary.md
```

## 用法示例

### 示例输入

```text
项目日报
```

### 预期行为

- 读取当天 session 证据
- 按项目归组
- 提炼目标、计划、完成事项
- 追加提交与未提交改动
- 避免冗长过程复述

## 输出示例

```markdown
## 今日项目日报

### trading-system
- 工作流 A：...
- 工作流 B：...
- 今日提交：...
- 未提交改动：...

### another-repo
- ...
```

## 限制

- 依赖同日 Codex transcript 是否可用。
- 不会伪造缺失的 session、git 或验证信息。
- 它适合“同日按项目汇总”，不适合长期历史分析。

## License

MIT


