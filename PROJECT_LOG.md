# Delivery Status Tracker 项目日志

> 用途：记录实际发生的工作、时间、问题、决策、验证证据和 AI 参与情况。
>
> 规则：执行方式受 [DEVELOPMENT_RULES.md](DEVELOPMENT_RULES.md) 约束；产品范围和目标方案见 [DEVELOPMENT_PLAN.md](DEVELOPMENT_PLAN.md)。
>
> 原则：这是事实账本，不是事后美化稿。记录可以被后续条目取代，但不得删除失败证据或改写历史。

## 1. 维护规则

- 使用 ISO 日期/时间；开始正式编码后记录带时区的时间，例如 `2026-08-04T18:30:00+08:00`。
- 编号只增不复用：`WORK-###`、`ISS-###`、`DEC-###`、`VAL-###`、`AI-###`。
- 每个开发计划 Step 默认只建立一个 `WORK-###`；普通小修追加到当前工作，只有跨 Step 独立工作才新增编号。
- 摘要表用于导航，详细条目用于复盘；新事件应同时更新二者。
- Issue 状态：`open / investigating / resolved / deferred / wont-fix`。
- Decision 状态：`proposed / accepted / superseded / rejected`。
- Validation 状态：`passed / failed / blocked / not-run`。
- 普通安装、成功命令、拼写修正和当前 Step 内的小修不单独编号，只在工作结果中汇总；仅阶段闸门、重要问题、关键决策、例外和交付证据进入独立记录。
- 事实和假设必须分开写；根因不明时写 `unknown`。
- 大段原始日志不直接粘贴，只保留关键错误、复现命令和结果；必要时链接外部构建产物。
- 已接受决策若被替代，保留旧条目并链接新的 `DEC-###`。

## 2. 当前状态

| 项目 | 当前值 |
| --- | --- |
| 阶段 | Step 7：README 与必要文档已更新；最终冷启动排练和提交尚未完成 |
| 当前开发步骤 | MVP 实现和最终代码闸门已完成；正在做交付收尾 |
| 编码时间盒 | Step 0 `00:25:32`；Step 1 `02:22:40`；Step 2 `00:08:20`；Step 3–5 `00:41:05` wall-clock |
| MVP Core | schema、固定 seed、列表、状态规则、PATCH、React 纵向流程和 README 已完成；最终冷启动排练待执行 |
| 当前 blocker | 无 |
| 开放 issue | 0；另有 1 个 deferred 开发体验问题 |
| 最近验证 | `VAL-013`：README、开发计划和日志的 Markdown 及本地链接检查通过 |
| 下一步 | 增加统一测试脚本，按 README 做最终冷启动排练，再准备提交 |

状态只在有证据时更新。文件存在不等于步骤完成，计划目标不等于验证通过。

## 3. 时间盒记录

正式编码从开发计划 Step 0 开始计时。规划、需求分析和本治理文档准备单独记录，不伪装成 3-4 小时编码成果。

| 记录 | 开始 | 结束 | 有效时长 | 类型 | 说明 |
| --- | --- | --- | --- | --- | --- |
| TIME-001 | 2026-08-04，具体时间未记录 | 2026-08-04，具体时间未记录 | 未计量 | 前期规划 | 需求拆解、开发计划、规则和日志机制；编码时间盒尚未启动 |
| TIME-002 | 2026-08-04T18:34:08+08:00 | 2026-08-04T18:59:40+08:00 | 00:25:32 wall-clock | coding/setup | Step 0；包含 Docker 安装等待和 WSL 环境诊断，未单独测量纯编码时间 |
| TIME-003 | 2026-08-04T19:13:06+08:00 | 2026-08-04T21:35:46+08:00 | 02:22:40 wall-clock | coding/setup | Step 1：Windows 原生 FastAPI、React 和 PostgreSQL 最小骨架；包含 PostgreSQL 安装、依赖与 CORS 排障 |
| TIME-004 | 2026-08-04T21:35:46+08:00 | 2026-08-04T21:44:06+08:00 | 00:08:20 wall-clock | coding | Step 2：Alembic schema 和固定真实 CSV seed |
| TIME-005 | 2026-08-04T21:44:06+08:00 | 2026-08-04T22:25:11+08:00 | 00:41:05 wall-clock | coding/testing | Step 3–5：状态规则、API、React 纵向流程及真实浏览器验收；各 Step 边界未单独计时 |
| TIME-006 | 2026-08-05，具体时间未记录 | 2026-08-05，具体时间未记录 | 未计量 | documentation | 数据生命周期图、README 和交付日志收尾；不计入 `03:37:37` 编码时间 |

后续使用以下类型：`coding / testing / documentation / waiting / paused`。每个 Step 结束时补充累计编码时间。

## 4. 工作记录

### 4.1 工作摘要

| ID | 日期 | Step / Requirement | 目标 | 状态 | 验证 |
| --- | --- | --- | --- | --- | --- |
| WORK-001 | 2026-08-04 | 开发前 / R13, R15, R16 | 建立可执行的开发规则、问题/决策日志和证据机制 | completed | `VAL-001` 至 `VAL-006` |
| WORK-002 | 2026-08-04 | Step 0 / R2, R11, R13, R16 | 锁定环境、仓库、CSV 和文档基线 | completed | `VAL-008` |
| WORK-003 | 2026-08-04 | Step 1 / R3, R7, R11 | 搭建 Windows 原生 FastAPI、React、PostgreSQL 骨架 | completed | `VAL-009` |
| WORK-004 | 2026-08-04 | Step 2 / R1, R2 | 创建 PostgreSQL schema 并固定导入真实 CSV | completed | `VAL-010` |
| WORK-005 | 2026-08-04 | Step 3 / R4, R6 | 实现列表 API 与状态转换规则 | completed | `VAL-011` |
| WORK-006 | 2026-08-04 | Step 4 / R5, R6, R10 | 实现状态更新 API 与 PostgreSQL 集成测试 | completed | `VAL-011` |
| WORK-007 | 2026-08-04 | Step 5 / R7, R8, R9 | 实现 React 列表与无刷新状态更新 | completed | `VAL-011` |
| WORK-008 | 2026-08-04 | 用户调试需求 / R4, R8 | 增加手动状态 reset 和 Reference/Last updated 排序 | completed | `VAL-012` |
| WORK-009 | 2026-08-05 | Step 7 / R13, R14, R15 | 更新评审入口、数据生命周期和交付事实账本 | completed | `VAL-013` |

### 4.2 WORK-001：建立开发治理机制

- **状态**：`completed`
- **目标**：在业务实现前固定需求优先级、单次变更流程、测试闸门、时间盒、问题/决策模板和 AI 证据要求。
- **关联要求**：R13（关键决策与 README）、R15（AI 使用说明）、R16（3-4 小时时间盒）。
- **局部假设**：若规则能明确回答“做什么、何时编辑、编辑后验证什么、失败记哪里、何时进入下一步”，后续开发不会依赖口头记忆或只报告未经验证的完成状态。
- **证伪检查**：检查规则是否覆盖资料优先级、变更前置条件、首次编辑后的验证、失败处理、技术边界、问题/决策记录、时间盒和完成闸门。
- **不包含**：不创建后端、前端、数据库或 Docker 业务实现。
- **结果**：创建开发规则和统一项目日志；开发计划增加交叉入口。
- **影响**：后续每个实质工作单元都必须有编号、验收和验证证据。
- **验证**：见 `VAL-001` 至 `VAL-006`。

### 4.3 WORK-002：锁定环境、仓库和输入基线

- **状态**：`completed`
- **开始/结束**：`2026-08-04T18:34:08+08:00` / `2026-08-04T18:59:40+08:00`
- **Step / Requirement**：Step 0 / R2 / R11 / R13 / R16
- **目标行为**：仓库拥有可追溯且核验一致的 CSV、Git/忽略规则和提交文档骨架，并确认进入可运行骨架阶段所需环境。
- **局部假设**：Step 0 可独立完成；进入 Step 1 前必须启用 WSL 2 并让 Docker Linux Engine 就绪。
- **证伪检查**：检查 Git、Docker CLI、Compose、Engine 和 Windows 包管理器的真实可用状态。
- **范围内**：环境预检、Git 初始化、复制并核验 CSV、`.gitignore`、`.env.example`、README 骨架和时间记录。
- **范围外**：不创建 FastAPI/React 业务代码，不安装项目依赖，不进入 Step 1。
- **修改摘要**：Git `main` 仓库已初始化；原始 CSV、`.gitattributes`、忽略规则、环境样例和 README 骨架已建立；Docker Desktop 已安装。
- **问题/决策**：无项目问题；WSL 2 是待完成的本机前置条件。
- **验证**：`VAL-008`。
- **结果与剩余风险**：Step 0 完成；Step 1 在 WSL 2 启用并验证 Linux Engine 前被阻塞。

### 4.4 WORK-003：搭建 Windows 原生最小可运行骨架

- **状态**：`completed`
- **开始/结束**：`2026-08-04T19:13:06+08:00` / `2026-08-04T21:35:46+08:00`
- **Step / Requirement**：Step 1 / R3 / R7 / R11
- **目标行为**：通过 `./scripts/dev.ps1` 检查 PostgreSQL 并启动 FastAPI 和 React，浏览器可访问最小页面，API health endpoint 可确认数据库连接。
- **局部假设**：本机已有 Python 3.12 和 Node，只需安装 PostgreSQL 16，并用 PowerShell 管理依赖、就绪检查和两个开发进程，即可更快达到单命令 Demo。
- **证伪检查**：第一次代码编辑后运行后端语法/诊断和前端 TypeScript/build；随后运行 `./scripts/dev.ps1` 与 health 请求。
- **范围内**：后端/前端脚手架、精确依赖、PowerShell scripts、health endpoint 和最小页面。
- **范围外**：不建 shipment schema、不导入 CSV、不实现列表或状态更新业务。
- **修改摘要**：安装并初始化 PostgreSQL 16；创建 Python 3.12/FastAPI health API、React/TypeScript 状态页、精确依赖和 `setup.ps1`/`dev.ps1`；修正 Windows wheel 与本机 loopback CORS 差异。
- **问题/决策**：`DEC-003`；后端虚拟环境使用已安装的 Python 3.12。
- **验证**：`VAL-009`。
- **结果与剩余风险**：单命令可启动 API/Web，真实数据库 health 为 `200`；shipment schema 和业务数据按计划留给 Step 2。

### 4.5 WORK-004：创建 schema 并导入固定真实 CSV

- **状态**：`completed`
- **开始/结束**：`2026-08-04T21:35:46+08:00` / `2026-08-04T21:44:06+08:00`
- **Step / Requirement**：Step 2 / R1 / R2
- **目标行为**：Alembic 从空 schema 创建约束完整的 `shipments` 表；启动只读取仓库内 `data/shipments.csv`，首次插入 20 条、后续跳过且不覆盖数据库状态。
- **局部假设**：固定输入、导入前完整校验和 PostgreSQL `ON CONFLICT DO NOTHING` 能同时满足真实 CSV、事务原子性、重启幂等与状态不覆盖。
- **证伪检查**：首个 migration 编辑后在 PostgreSQL 执行 `upgrade head` 并查询真实约束；seed 编辑后运行定向测试和两次真实导入。
- **范围内**：SQLAlchemy model、Alembic migration、严格固定 CSV seed、启动接线和显式 reset。
- **范围外**：不提供任意 CSV 路径、网页上传、导入 API、列表 API 或状态更新。
- **修改摘要**：新增 SQLAlchemy model、首个 Alembic migration、固定 CSV 严格解析和事务 seed；`dev.ps1` 自动 migration/seed，`reset.ps1` 只恢复固定样本。
- **问题/决策**：MVP 固定 CSV 边界已写入开发计划和规则。
- **验证**：`VAL-010`。
- **结果与剩余风险**：首次导入 20 条、后续跳过 20 条且不覆盖数据库状态；任意 CSV 导入按范围决策未实现。

### 4.6 WORK-005：实现列表 API 与状态规则

- **状态**：`completed`
- **开始/结束**：包含在合并时间记录 `TIME-005`；单独边界未记录
- **Step / Requirement**：Step 3 / R4 / R6
- **目标行为**：`GET /api/shipments` 按 reference 返回 20 条真实记录及服务端派生的下一状态；生命周期矩阵由纯函数和完整测试固定。
- **局部假设**：集中式状态规则和响应 schema 可避免前端复制转换矩阵，并为下一步 PATCH 复用同一权威逻辑。
- **证伪检查**：规则编辑后先跑完整转换矩阵单元测试；router 编辑后跑使用隔离测试库的列表 API 测试。
- **范围内**：状态规则、Pydantic schema、数据库 Session dependency 和列表 router。
- **范围外**：本切片先不实现 PATCH 和 React mutation。
- **修改摘要**：集中定义 5 个状态的完整转换矩阵；`GET /api/shipments` 按 `reference ASC` 返回数据库记录、总数、`updated_at` 和服务端派生的 `allowed_next_statuses`。
- **问题/决策**：none。
- **验证**：`VAL-011`；状态规则 5 个派生场景和 25 个完整状态组合通过，列表空态、排序和派生字段在 `tracker_test` 通过。
- **结果与剩余风险**：默认排序保持稳定，不因状态更新移动行；数据库已有 `updated_at`，本次不新增重复的 `lastModify` 字段。

### 4.7 WORK-006：实现状态更新 API

- **状态**：`completed`
- **开始/结束**：包含在合并时间记录 `TIME-005`；单独边界未记录
- **Step / Requirement**：Step 4 / R5 / R6 / R10
- **目标行为**：合法 PATCH 持久化；相同状态为不更新时间的 `200` no-op；非法转换为 `409`；不存在为 `404`；非法请求为 `422`。
- **修改摘要**：新增 Pydantic 请求/响应 schema；事务内用 `SELECT ... FOR UPDATE` 重读目标行；合法更新写入状态和数据库时间，结构化返回错误。
- **验证**：`VAL-011`；8 个 PostgreSQL API 场景通过，非法更新后数据库值不变。
- **结果与剩余风险**：正常启动 seed 不覆盖手动修改；只有显式 `scripts/reset.ps1` 会清空当前 demo 修改并恢复固定 CSV。

### 4.8 WORK-007：实现 React 纵向流程

- **状态**：`completed`
- **开始/结束**：包含在合并时间记录 `TIME-005`；单独边界未记录
- **Step / Requirement**：Step 5 / R7 / R8 / R9
- **目标行为**：展示 20 条真实 shipment；只提供服务端允许的下一状态；提交期间只锁定目标行；成功原位替换，失败保留旧值并显示行内消息。
- **修改摘要**：实现列表 loading/error/empty/success、状态 badge、服务端驱动的直接状态按钮、PATCH client 响应校验和行内错误；自定义 dev 端口标签来自真实运行配置。
- **问题/决策**：`ISS-002`。
- **验证**：`VAL-011`；单次点击只有 1 个 PATCH、目标行禁用而其他行可操作、主 frame 导航 0 次、刷新与 PostgreSQL 均保持新状态，模拟 `409` 时旧状态不变。
- **结果与剩余风险**：桌面和 390 px 页面均已验收且无整体横向溢出；最终冷启动排练仍属于交付收尾。

### 4.9 WORK-008：手动恢复状态与可选排序

- **状态**：`completed`
- **开始/结束**：2026-08-04 / `2026-08-04T23:29:26+08:00`；开始时间未单独记录
- **目标行为**：用户可在页面确认后把固定 CSV 对应 shipment 的 status 恢复为初始值；列表可按 `reference ASC` 或 `updated_at DESC, reference ASC` 排序。
- **局部假设**：reset 只恢复 status、保留记录/客户数据并只更新时间发生变化的行，比暴露数据库 truncate 更适合作为 UI 调试功能；排序由 API 执行可保持刷新后一致。
- **修改摘要**：新增 `POST /api/shipments/reset`、`GET /api/shipments?sort=...`、排序白名单、Last updated 列、分段排序控件、确认对话框和 reset 结果提示；Last updated 模式下 PATCH 成功后立即本地重排。
- **问题/决策**：reset 只恢复 status，不删除 shipment、不重建 ID、不覆盖 customer；非法排序由 FastAPI 返回 `422`。
- **验证**：`VAL-012`。
- **结果与剩余风险**：真实 reset 恢复 7 条后总数仍为 20；实际恢复行的 `updated_at` 写为 reset 时间，本来已匹配的行不变；CSV 没有原始时间可恢复。第二次 reset 返回 `reset_count=0`；该 endpoint 没有认证，不应直接暴露到生产环境。

### 4.10 WORK-009：收敛交付文档

- **状态**：`completed`
- **开始/结束**：2026-08-05；具体时间未记录
- **Step / Requirement**：Step 7 / R13 / R14 / R15
- **目标行为**：评审可从精简 README 直接完成 setup、启动、reset 和质量检查，并能看到真实决策、AI 错误和后续计划。
- **修改摘要**：README 从过时骨架更新为 117 行交付入口；开发计划增加可维护 Mermaid 数据生命周期图；日志同步 reset 时间语义、验证状态和剩余风险。
- **问题/决策**：没有把普通文案修改登记为 issue；保留 `ISS-003` 这一真实运行问题，并明确当前没有统一 `scripts/test.ps1`。
- **验证**：`VAL-013`。
- **结果与剩余风险**：必要文档已同步；最终冷启动排练、统一测试入口和仓库提交仍待完成。

### 4.11 新工作条目模板

```markdown
### WORK-###：<目标行为>

- **状态**：`planned / in-progress / completed / blocked`
- **开始/结束**：<带时区时间>
- **Step / Requirement**：<例如 Step 3 / R6 / MVP-CORE>
- **目标行为**：<用户或系统可观察行为>
- **局部假设**：<当前认为行为由什么控制>
- **证伪检查**：<第一次编辑后立刻执行什么>
- **范围内**：<本工作单元包含什么>
- **范围外**：<明确不顺手做什么>
- **修改摘要**：<完成后填写>
- **问题/决策**：<ISS/DEC 链接或 none>
- **验证**：<VAL 链接>
- **结果与剩余风险**：<事实，不写宣传语>
```

## 5. 需求证据索引

这里只登记实际证据位置，不重复开发计划中的需求解释。

| Requirement | 实现证据 | 自动化验证 | 人工/Demo 证据 | 状态 |
| --- | --- | --- | --- | --- |
| R1 PostgreSQL schema | SQLAlchemy model + `0001_create_shipments` | `VAL-010` | PostgreSQL 系统目录约束查询 | verified |
| R2 CSV seed | 固定 CSV seed + `reset.ps1` | `VAL-010` | 20 条及完整状态分布 | verified |
| R3 FastAPI | `backend/app/main.py` health API | `VAL-009` | 浏览器显示 Connected | verified |
| R4 列表 API | `GET /api/shipments` + response schema | `VAL-011` | 真实页面显示 20 条、稳定排序 | verified |
| R5 状态更新 API | 行锁事务 PATCH | `VAL-011` | UI 更新后刷新与 PostgreSQL 一致 | verified |
| R6 转换校验 | 集中状态矩阵 + 结构化 `409` | `VAL-011` | 模拟冲突时 UI 保留旧值 | verified |
| R7 React 列表 | 四种列表状态 + 响应式表格 | `VAL-011`、`VAL-012` | 桌面和 390 px 页面通过 | verified |
| R8 UI 状态更新 | 直接状态按钮、行级 pending、error | `VAL-011` | 单行更新和错误恢复通过 | verified |
| R9 无整页刷新 | PATCH 响应原位替换目标行 | `VAL-011` | 主 frame navigation `0` | verified |
| R10 有意义的测试 | 领域矩阵、seed、health、配置和 PostgreSQL API 测试 | `VAL-011`、`VAL-012` | 最终完整后端 `51 passed` | verified |
| R11 可运行 Demo | `setup.ps1`、`dev.ps1`、`reset.ps1` | `VAL-009`、`VAL-011` | 默认及自定义端口启动可用；最终冷启动闸门待跑 | implemented |
| R12 仓库/zip | - | - | - | planned |
| R13 README 与决策 | README、开发计划和本文 | `VAL-013` | 精简评审入口和真实取舍已同步 | verified |
| R14 What I would do next | README 优先级列表 | `VAL-013` | 未完成能力未被夸大 | verified |
| R15 AI 使用说明 | README + 本文 AI/Issue 记录 | `ISS-001`、`ISS-002`、`VAL-013` | 记录具体 AI 错误及发现方式 | verified |
| R16 时间盒 | 本文时间盒记录 | - | - | ready |
| R17 排除无关范围 | 开发计划 `[OUT]` + 开发规则 | `VAL-004` | - | ready |

状态含义：`planned / in-progress / implemented / verified / deferred`。只有实现和验证证据均存在时才能标为 `verified`。

## 6. 问题记录

### 6.1 Issue 摘要

| ID | 日期 | 严重度 | 摘要 | 状态 | 关联验证 |
| --- | --- | --- | --- | --- | --- |
| ISS-001 | 2026-08-04 | low | PowerShell 5.1 默认编码和大小写检查导致文档覆盖脚本误报 | resolved | `VAL-001` |
| ISS-002 | 2026-08-04 | medium | 自定义 `WebPort` 启动后 API CORS 仍写死允许 5173 | resolved | `VAL-011` |
| ISS-003 | 2026-08-04 | low | Windows 开发进程在 Uvicorn 热重载后曾退出并使 `dev.ps1` 返回 1 | deferred | 干净重启恢复；未完成稳定复现 |

### 6.2 ISS-001：文档覆盖检查误报缺少中文章节

- **状态**：`resolved`
- **严重度**：`low`
- **上下文**：验证 [DEVELOPMENT_PLAN.md](DEVELOPMENT_PLAN.md) 是否包含人工验收、Demo、AI 使用和 what-next 等必需主题。
- **症状**：首次 PowerShell 覆盖脚本报告缺少 `人工验收`、`5 分钟`、`AI 使用` 和 `What I would do next`，但文件人工阅读确认这些内容存在。
- **预期**：脚本应识别 UTF-8 Markdown 中的中文文本，并对英文标题采用合适的匹配语义。
- **实际**：`Get-Content -Raw` 在 Windows PowerShell 5.1 中使用默认本地编码读取无 BOM UTF-8 文件；脚本同时使用大小写敏感的 `.Contains()`。
- **复现条件**：Windows PowerShell 5.1；对 UTF-8 Markdown 使用未指定编码的 `Get-Content -Raw`，再用 `.Contains()` 检查中文和大小写不完全一致的英文。
- **调查证据**：缺失项在编辑器读取结果中真实存在；失败集中在中文和英文大小写差异项，而 ASCII 技术词可匹配。
- **根因**：验证脚本未显式指定 UTF-8，并选择了不符合预期的大小写敏感匹配。
- **处置**：改为 `Get-Content -Raw -Encoding UTF8`，并使用 PowerShell 默认不区分大小写的 `-match` 配合 `[regex]::Escape()`。
- **验证**：修正后的同类检查输出 `Plan coverage OK: sections=19, must-markers=20, stretch-markers=5`，exit code 为 0，见 `VAL-001`。
- **影响**：只影响文档检查，没有修改业务需求或产品数据。
- **回归保护**：后续 PowerShell 5.1 读取仓库 UTF-8 文本时显式使用 `-Encoding UTF8`。
- **AI 使用说明候选**：是。AI 首次生成的验证命令忽略了 PowerShell 5.1 编码和匹配语义；若后续出现更贴近产品实现的真实 AI 错误，可优先选更有技术代表性的事件写入 README。

### 6.3 ISS-002：自定义 Web 端口被 CORS 拒绝

- **状态**：`resolved`
- **严重度**：`medium`
- **发现时间/工作单元**：2026-08-04 / `WORK-007`
- **症状**：`./scripts/dev.ps1 -ApiPort 8011 -WebPort 5184` 能启动两个进程，但浏览器的 health 和 shipment 请求被 CORS 拒绝。
- **预期/实际**：脚本公开的端口参数应端到端可用；实际后端默认 origins 固定为 `5173`。
- **根因**：`WEB_PORT` 已由脚本设置，但 `Settings` 未用它生成默认 loopback origins；前端端口标签也写死默认值。
- **处置**：未显式设置 `CORS_ORIGINS` 时，用 `WEB_PORT` 生成 localhost/127.0.0.1 origins；显式 origins 仍优先；前端显示真实 API/Web 端口。
- **验证**：配置单元测试 `2 passed`；隔离端口页面显示 `20 total`，footer 为 `API :8011`、`Web :5184`，真实 PATCH 返回 `200`。
- **剩余风险**：none；后续 `VAL-012` 已完成全量后端和前端代码闸门。
- **AI 使用说明候选**：`yes`；AI 实现端口参数时遗漏了 CORS 配置传播，真实浏览器跨源验收发现该错误。

### 6.4 ISS-003：Uvicorn 热重载后开发脚本退出

- **状态**：`deferred`
- **严重度**：`low`
- **发现时间/工作单元**：2026-08-04 / 文档与后端编辑期间
- **症状**：运行 `./scripts/dev.ps1` 时修改 Python 文件，曾出现 API 子进程退出，父脚本随后以 code 1 结束；干净重启后 API 和页面恢复。
- **影响范围**：只影响本地开发连续性；没有证据表明已提交的 API 业务请求或持久化数据损坏。
- **调查证据**：终端记录存在 `dev.ps1` exit code 1；无热重载时的 smoke test、完整 API 测试和浏览器验收均通过。
- **根因**：`unknown`；尚未完成稳定复现，可能与 Windows 下 Uvicorn reloader 和 PowerShell 子进程生命周期组合有关。
- **处置**：当前 workaround 是重新运行 `./scripts/dev.ps1`；不在交付文档收尾中改动进程管理代码。
- **验证**：干净重启恢复；`VAL-012` 证明业务代码闸门通过，但不视为热重载问题已修复。
- **剩余风险**：编辑后端代码时可能需要手动重启开发命令。
- **AI 使用说明候选**：`no`；根因未证实，不将它包装成 AI 实现错误。

### 6.5 新 Issue 模板

```markdown
### ISS-###：<可观察症状>

- **状态**：`open / investigating / resolved / deferred / wont-fix`
- **严重度**：`blocker / high / medium / low`
- **发现时间/工作单元**：<时间 / WORK-###>
- **上下文**：<正在做什么>
- **症状**：<原始错误摘要或用户可见行为>
- **预期/实际**：<明确对比>
- **复现步骤**：<最短稳定步骤>
- **影响范围**：<数据/API/UI/Demo/文档>
- **调查证据**：<事实>
- **根因**：<事实或 unknown>
- **处置**：<修复、workaround 或 defer>
- **验证**：<VAL-### 和结果>
- **剩余风险**：<没有则 none>
- **关联决策**：<DEC-### 或 none>
- **AI 使用说明候选**：`yes / no`，原因
```

## 7. 决策记录

### 7.1 Decision 摘要

| ID | 日期 | 摘要 | 状态 | 影响 |
| --- | --- | --- | --- | --- |
| DEC-001 | 2026-08-04 | 采用“开发计划 + 开发规则 + 统一项目日志”三层治理 | accepted | 后续全部工作 |
| DEC-002 | 2026-08-04 | 对每个实质工作单元采用首次编辑后立即验证的证据闸门 | accepted | 实现、测试和问题处理 |
| DEC-003 | 2026-08-04 | 从 Docker/WSL 主路径切换到 Windows 原生 PowerShell 启动 | accepted | 运行方式、脚本、README 和验收 |

### 7.2 DEC-001：采用三层治理与统一项目日志

- **状态**：`accepted`
- **背景**：作业要求同时交代技术决策、时间盒、what-next 和 AI 使用，且最终需要 5 分钟 live demo。只靠 README 末尾补写容易遗漏真实过程。
- **约束**：总开发时间只有 3-4 小时，记录机制不能演变成重型项目管理。
- **选项 A**：所有计划、规则、问题和决策放进一个大文件。优点是文件少；缺点是目标方案和运行事实会混在一起，更新容易产生噪声。
- **选项 B**：每个问题、ADR 和验证分别建文件。优点是历史粒度高；缺点是对本作业维护成本过大。
- **选择**：使用三层文档：开发计划管“做什么”，开发规则管“怎么做”，统一项目日志管“实际发生了什么”。问题和决策使用唯一 ID，但保留在一个日志中。
- **理由**：在可追踪和低维护成本之间取得平衡，也便于最终提炼 README 和 AI 使用说明。
- **正面效果**：需求、流程和证据边界清楚；可从日志直接生成 Demo/README 的真实材料。
- **代价/风险**：必须持续更新摘要表；若项目长期扩大，单一日志会变长。
- **受影响内容**：全部后续工作单元、问题、决策和验证。
- **验证**：三个文档互相链接，规则覆盖检查通过，见 `VAL-004`。
- **实施后的实际效果**：三个文档职责已分离并互相链接；结构检查通过。对开发时间成本的实际影响仍需在 Step 0-2 后复盘。

### 7.3 DEC-002：采用编辑后立即验证的证据闸门

- **状态**：`accepted`
- **背景**：纵向切片跨数据库、API 和 UI，批量实现后再测试会让根因定位变慢，也容易在 3-4 小时时间盒末尾才发现接线失败。
- **选项 A**：先完成一个大阶段的所有文件，再统一运行测试。
- **选项 B**：每个可验证工作单元第一次实质编辑后，立即运行最窄证伪检查，通过后再扩展。
- **选择**：选项 B。
- **理由**：更快发现错误假设，限制修改范围，并为问题和 AI 说明留下明确证据。
- **正面效果**：失败更容易归因；每个 Step 都保持接近可运行状态。
- **代价/风险**：会增加若干次短测试执行，但总排障成本更低。
- **受影响内容**：所有代码、migration、配置和文档工作单元。
- **验证**：开发规则第 4 节已把该流程写成 MUST；本次规则文件创建后立即执行诊断，见 `VAL-003`。
- **实施后的实际效果**：治理文档每次修改后均立即执行定向诊断，成功捕获并修正一次补丁片段顺序错误；业务开发中的成本与效果仍待验证。

### 7.4 DEC-003：采用 Windows 原生单命令开发路径

- **状态**：`accepted`
- **日期/工作单元**：2026-08-04 / `WORK-003`
- **背景与约束**：brief 只固定 PostgreSQL、FastAPI 和 React；启动命令由候选人选择，单命令只是 ideal。Docker Desktop 已安装，但 WSL 下载长期未完成并开始消耗 3-4 小时时间盒。
- **选项 A**：继续等待 WSL，使用 Docker Compose。优点是运行时隔离；缺点是当前环境前置不可用且下载耗时不可控。
- **选项 B**：Windows 原生安装 PostgreSQL 16，复用已安装的 Python 3.12 和 Node，由 PowerShell 提供 setup/dev/test/reset 命令。优点是最快进入业务实现；缺点是 README 需要明确三个系统前提。
- **选择与理由**：选择 B。当前只需在本机完成可演示纵向切片，Windows 原生完全满足原文，且显著降低即时环境阻塞。
- **正面效果**：停止等待 WSL；保留单命令启动目标；直接使用本机调试工具。
- **代价与剩余风险**：运行说明偏 Windows；PostgreSQL 仍需一次性安装；PowerShell 必须可靠清理两个子进程。
- **影响范围**：开发计划、规则、README、Step 1、启动/测试/重置脚本和 Demo 命令。
- **验证方式**：`./scripts/dev.ps1` 能启动 API/Web，health 返回数据库 ready，README 命令逐字可执行。
- **实施后的实际效果**：PostgreSQL 16、FastAPI 和 Vite 已由 `dev.ps1` 单命令启动；health 返回 `200`，smoke test 退出后 `8000/5173` 残留监听数为 0，见 `VAL-009`。
- **取代/被取代关系**：取代开发计划中原 Docker Compose 运行决策。

### 7.5 新 Decision 模板

```markdown
### DEC-###：<决策标题>

- **状态**：`proposed / accepted / superseded / rejected`
- **日期/工作单元**：<时间 / WORK-###>
- **背景与约束**：<为什么现在必须决定>
- **选项 A**：<方案、优点、缺点>
- **选项 B**：<方案、优点、缺点>
- **选择与理由**：<最终答案>
- **正面效果**：<达到什么效果>
- **代价与剩余风险**：<诚实写明>
- **影响范围**：<需求、schema、API、UI、测试、Demo>
- **验证方式**：<如何证明选择有效>
- **实施后的实际效果**：<决定刚接受时写 pending，验证后回填事实>
- **取代/被取代关系**：<DEC-### 或 none>
```

## 8. 阶段验证记录

普通成功检查只汇总到当前 `WORK-###`。此处仅保留阶段闸门、重要失败修复、MVP/Demo 和提交证据。

### 8.1 Validation 摘要

| ID | 日期 | 验证对象 | 命令/方式 | 结果 | 状态 |
| --- | --- | --- | --- | --- | --- |
| VAL-001 | 2026-08-04 | 开发计划内容覆盖 | UTF-8 PowerShell 关键词/标记检查 | 19 个主章节，20 个 MUST 标记，5 个 STRETCH 标记；exit 0 | passed |
| VAL-002 | 2026-08-04 | 开发计划 Markdown | VS Code diagnostics | No errors found | passed |
| VAL-003 | 2026-08-04 | 开发规则 Markdown | VS Code diagnostics | No errors found | passed |
| VAL-004 | 2026-08-04 | 治理文档结构覆盖 | UTF-8 PowerShell 关键词、交叉链接和模板存在性检查 | `files=3, rule-topics=13, rule-sections=17, log-sections=11, broken-links=0`；exit 0；只证明文档结构，不证明技术方案已运行 | passed |
| VAL-005 | 2026-08-04 | 原始 CSV 附件 | PowerShell `Import-Csv` 结构校验 + `Get-FileHash -Algorithm SHA256` | header 正确；20 行；`TV-1001` 至 `TV-1020`；重复/空值/非法状态均为 0；分布 `created=8, delivered=2, in_transit=6, picked_up=4, failed=0`；SHA-256 `069a6ad7e8adf798584458eb57d7637641a87d9e1bfbfd87cec8c52bf7c3cb3d`；exit 0 | passed |
| VAL-006 | 2026-08-04 | 治理文档审计修订一致性 | UTF-8 PowerShell 检查 Step 工作粒度、依赖锁定、测试库隔离、CSV 证据、日志命名和本地链接 | `files=3, rule-checks=8, plan-checks=3, log-checks=5, broken-links=0`；exit 0 | passed |
| VAL-008 | 2026-08-04T18:59:40+08:00 | Step 0 阶段闸门 | PowerShell 检查 Git 分支、8 个基线文件、CSV、属性、忽略规则和 Markdown 链接 | `branch=main`；20 条；状态分布正确；CSV SHA-256 匹配；`broken_links=0`；exit 0 | passed |
| VAL-009 | 2026-08-04T21:35:46+08:00 | Step 1 阶段闸门 | `setup.ps1` 幂等运行；`dev.ps1 -SmokeTest`；Ruff/pytest/Oxlint/TypeScript/Vite；Playwright 桌面与手机检查 | PostgreSQL `Running/Automatic`；health `200`；smoke test 后端口残留 `0`；后端 `3 passed`；lint/build 通过；1440×900 与 390×844 均无横向溢出，页面显示 `Connected/Ready` | passed |
| VAL-010 | 2026-08-04T21:44:06+08:00 | Step 2 阶段闸门 | 真实 PostgreSQL migration/约束查询；两次 seed 与两次启动；状态保留/reset；Ruff、Alembic check、pytest | revision `0001_create_shipments`；6 列非空，PK/UNIQUE/3 CHECK；首次 `20/0/20`、后续 `0/20/20`；20 个唯一 reference；分布 `created=8,picked_up=4,in_transit=6,delivered=2,failed=0`；`8 passed`；无 metadata drift | passed |
| VAL-011 | 2026-08-04T22:25:11+08:00 | Step 3–5 聚焦闸门 | Ruff；状态矩阵与 PostgreSQL API 测试；前端 Oxlint/TypeScript/build；隔离端口 Playwright + SQL 核对 | 规则 `30 passed`；API `8 passed`；完整后端曾连续两遍 `46 passed`；配置 `2 passed`；前端构建通过；20 条；单击 1 PATCH；目标行独立 pending；navigation `0`；刷新和 DB 均为 `picked_up`；模拟 `409` 保留旧值 | passed |
| VAL-012 | 2026-08-04T23:29:26+08:00 | 手动 reset、可选排序与最终代码闸门 | PostgreSQL API 测试；Ruff；Alembic check；Oxlint/TypeScript/build；Playwright 桌面/390px | `51 passed`；无 metadata drift；前端构建通过；Last updated API/UI 同为最新行且时间降序；reset 取消 0 POST、确认 1 POST，恢复 7 条且仍 20 条；移动端无页面溢出，确认框完整 | passed |
| VAL-013 | 2026-08-05 | 交付 Markdown | VS Code diagnostics；根目录 Markdown 本地链接检查；README 行数检查 | 3 个必要文档无 diagnostics；本地链接 0 broken；README 117 行 | passed |

### 8.2 新 Validation 模板

```markdown
### VAL-###：<验证目标>

- **时间/工作单元**：<时间 / WORK-###>
- **验证行为**：<它能证实或证伪什么>
- **环境**：<Compose service、浏览器或 OS>
- **命令/步骤**：`<精确命令>`
- **预期**：<明确结果>
- **实际**：<exit code、计数、HTTP 状态或 UI 行为>
- **状态**：`passed / failed / blocked / not-run`
- **关联问题**：<ISS-### 或 none>
```

## 9. AI 参与记录

### 9.1 AI 摘要

| ID | 日期 | 工具 | 辅助内容 | 人类负责/验证 | 结果 |
| --- | --- | --- | --- | --- | --- |
| AI-001 | 2026-08-04 | GitHub Copilot | 需求拆解、开发计划、开发规则和日志模板草拟与审计 | 用户确定目标；文档通过诊断、覆盖检查和独立审计 | accepted with correction `ISS-001` |
| AI-002 | 2026-08-04 | GitHub Copilot | Step 3–5 状态规则、API、React 和测试实现 | 用户确认 MVP 范围并手动操作页面；Ruff、pytest、build、浏览器和 PostgreSQL 共同验证 | accepted with correction `ISS-002` |
| AI-003 | 2026-08-05 | GitHub Copilot | reset/排序说明、数据生命周期图和 README 收尾 | 用户决定 UI/reset 语义并要求精简；文档诊断和链接检查验证 | accepted |

### 9.2 新 AI 记录模板

```markdown
### AI-###：<工作单元>

- **工具/模型**：<如 GitHub Copilot>
- **AI 辅助或生成**：<具体文件/逻辑>
- **人类负责**：<需求解释、取舍、审查、修改>
- **验证证据**：<VAL-###>
- **AI 错误**：<ISS-### 或 none>
- **是否用于最终 AI note**：`yes / no / candidate`
```

## 10. 开放风险与延期项

| ID | 来源 | 风险/延期项 | 影响 | 下一步 | 状态 |
| --- | --- | --- | --- | --- | --- |
| RISK-001 | 招聘邮件 | 准确提交日期、时间和时区尚未确认 | 可能影响交付安排 | 向招聘方确认，至少预留 60 分钟提交缓冲 | open |
| RISK-002 | `WORK-008` | 页面 reset endpoint 无认证 | 若直接部署会允许任意调用者改写状态 | 生产前增加认证/授权或移除该调试接口 | deferred |
| RISK-003 | Step 7 | 尚无统一 `scripts/test.ps1`，也未按 README 做最终干净环境排练 | 提交者需逐条运行命令，环境可复现性仍有最后一段未验证 | 增加脚本并执行最终冷启动验收 | open |

## 11. 每次结束工作前更新顺序

1. 更新当前 `WORK-###` 状态和结果。
2. 新增或关闭相关 `ISS-###`，确保有验证证据。
3. 新增/更新 `DEC-###`，不要删除被取代的历史。
4. 把实际命令加入 `VAL-###`，失败也记录。
5. 更新需求证据索引和当前状态。
6. 记录累计时间、开放风险和下一步。
7. 检查 README 是否需要同步；未验证命令不得提前写成事实。
