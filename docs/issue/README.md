# Issue 管理规范

`docs/issue/` 用于记录仓库内已经确认但尚未完成处理的事项，包括：

- 待修复的已知问题
- 待开发的需求
- 已确认但延后的技术任务

## 基本规则

- 一个 issue 对应一个 Markdown 文件，不要把多个独立事项写在同一个文件里。
- issue 文件统一放在 `docs/issue/` 下。
- issue 文件名必须直接使用 issue 编号，格式为 `<TYPE>-<MODULE>-<FEATURE>-<NNN>.md`。
- issue 编号必须体现类型、模块、功能和顺序号，全部使用 kebab-case 或大写类型前缀。
- 同一类 `TYPE + MODULE + FEATURE` 组合下，顺序号从 `001` 开始递增。
- issue 关闭后保留原文件，只更新状态和处理结果，不删除历史记录。

## 编号规则

格式：

```text
<TYPE>-<MODULE>-<FEATURE>-<NNN>
```

字段说明：

- `TYPE`：事项类型
  - `BUG`：已知问题、缺陷、回归
  - `REQ`：待开发需求、功能请求
  - `TASK`：已确认的整理、重构、技术债任务
- `MODULE`：对应模块，使用仓库内真实模块或入口名，例如 `install`、`powershell`、`scripts-lib`、`docs`
- `FEATURE`：对应功能或能力点，例如 `offline-package`、`verify`、`xdg-path`
- `NNN`：三位顺序号，例如 `001`、`002`

示例：

- `BUG-install-verify-001`
- `REQ-powershell-offline-deploy-001`
- `TASK-docs-issue-governance-001`

## 推荐模板

新建 issue 时，请复制 `docs/issue/TEMPLATE.md` 并替换占位内容。

必填字段：

- 编号
- 标题
- 类型
- 状态
- 优先级
- 模块
- 功能
- 提出日期
- 背景
- 当前问题或目标
- 验收标准

推荐状态：

- `todo`
- `in_progress`
- `blocked`
- `done`
- `wontfix`

推荐优先级：

- `high`
- `medium`
- `low`

## 使用建议

- 发现明确问题但暂不处理时，先补 issue，再继续其他工作。
- 需求范围较大时，可在 issue 中链接对应的 `docs/plans/` 设计或实现计划。
- 提交代码时，如果和某个 issue 直接相关，提交说明和相关文档里应引用 issue 编号。
