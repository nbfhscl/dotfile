# Repository Agent Rules

## 开发流程规范

- **每次较大修改必须通过 E2E 测试验证**
  - 使用 Docker 容器进行端到端测试：`docker-compose -f tests/docker-compose.test.yml up --abort-on-container-exit`
  - 测试脚本位于 `tests/docker/run-e2e-test.sh`
  - 只有在所有测试通过后才能合并代码

- **保持文档一致性**
  - `AGENTS.md` 和 `CLAUDE.md` 必须保持完全一致
  - 修改其中一个文件时，必须同步更新另一个文件
  - 两个文件的内容应该反映相同的仓库规则和开发规范

## Issue 管理

- `docs/issue/` 是仓库内已知问题、待开发需求和延期任务的唯一登记目录。
- 每个事项使用单独的 Markdown 文件管理，不合并多个独立事项。
- 文件名必须遵循 `<TYPE>-<MODULE>-<FEATURE>-<NNN>.md`。
- `TYPE` 使用 `BUG`、`REQ`、`TASK` 区分缺陷、需求和任务。
- `MODULE` 必须对应实际模块或入口；`FEATURE` 必须对应具体功能点，两者都使用 kebab-case。
- `NNN` 使用三位顺序号，并在相同 `TYPE + MODULE + FEATURE` 范围内递增。
- 新增 issue 时使用 `docs/issue/TEMPLATE.md` 作为结构基线。
- issue 文档必须包含状态、优先级、背景、问题或目标、验收标准和处理记录。
- 状态统一为 `todo`、`in_progress`、`blocked`、`done`、`wontfix`。
- issue 完成后更新状态和结果，保留完整历史，不直接删除文件。
- 如 issue 触发设计或实现计划，应在 `docs/plans/` 中补充对应文档，并互相引用 issue 编号。
