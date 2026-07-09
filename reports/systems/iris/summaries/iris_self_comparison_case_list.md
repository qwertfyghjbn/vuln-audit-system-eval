# IRIS 自有对照 Case 冻结清单

## 1. 文档定位

这份清单冻结本轮 `DeepSeek + IRIS` 可信度对照学习批次中的 `Self Comparison Case`。

它们不属于 `Official Asset-Chain Case`，也不用于回答“官方结果是否原样复现”。它们的作用是回答：

1. 同一条 `DeepSeek + IRIS` 运行链下，为什么官方 case 和自有 case 会出现不同结果。
2. 官方 case 是否对 `IRIS` 更友好。
3. 官方 case 的 build / metadata / slice 是否比自有 case 更容易让 `IRIS` 成功。

## 2. 冻结原则

本轮自有对照组按以下原则冻结：

1. 优先选择已经暴露出稳定问题的真实 Java repo case
2. 优先保留 `PT` 与 `SSRF` 两条当前最关键的问题线
3. 优先选择输入契约相对清晰、与当前官方学习线更可比的 case
4. 暂不把“缺少 compile recipe 的 case”放进第一轮主对照组
5. 暂不把 synthetic smoke case 作为主对照证据

## 3. 主对照组

本轮主对照组固定为 3 个 case。

| 组内角色 | case_id | 类型 | 标签 | 选择理由 |
|---|---|---|---|---|
| `self-pt-vuln` | `PT-JA-REPO-CVE-2024-53677-VULN` | real-world Java repo | vulnerable | 当前 `PT` 主问题线；已暴露 `source` 缺失与 Stage 3 候选偏移问题；带 compile recipe |
| `self-ssrf-vuln` | `SSRF-JA-REPO-CVE-2023-3432-VULN` | real-world Java repo | vulnerable | 当前 `SSRF` 主问题线；已暴露 caller-side / source 缺失 / path 不成链问题；带 compile recipe |
| `self-ssrf-fixed` | `SSRF-JA-REPO-CVE-2023-3432-FIXED` | real-world Java repo | near_miss | 与 `self-ssrf-vuln` 形成同构修复对照；带 compile recipe；可观察 fix-awareness 与共享缓存影响 |

## 4. 冻结依据

### 4.1 `PT-JA-REPO-CVE-2024-53677-VULN`

理由：

1. 这是当前最关键的 `PT` repo case。
2. 之前已稳定出现：
   - `source = 0`
   - Stage 3 候选偏向 JDK / 集合类 API
   - multipart 包装层未进入核心候选
3. 该 case 自带 `build_support/java_compile_recipe.json`，输入契约比 `PT` fixed 更清晰。

### 4.2 `SSRF-JA-REPO-CVE-2023-3432-VULN`

理由：

1. 这是当前最关键的 `SSRF` repo case。
2. 之前已稳定出现：
   - `source` 稀缺
   - `SURL` 包装层候选边界问题
   - caller-side 路径扩展后仍然不成最终 path
3. 该 case 自带 `build_support/java_compile_recipe.json`，适合与官方 case 做输入边界对照。

### 4.3 `SSRF-JA-REPO-CVE-2023-3432-FIXED`

理由：

1. 它与 `SSRF-JA-REPO-CVE-2023-3432-VULN` 形成天然对照对。
2. 之前已暴露：
   - 与 `VULN` 类似的 source 缺失症状
   - 同 `run_id` / 同 `CWE` 的缓存复用问题
3. 它能帮助判断：
   - `IRIS` 在 `DeepSeek` 下是否只会“无信号”
   - 还是会对 `FIXED` / `VULN` 产生不同的标签结构

## 5. 暂不纳入第一轮主对照组的 case

### 5.1 `PT-JA-REPO-CVE-2024-53677-FIXED`

当前不纳入第一轮主对照组。

原因：

1. 当前目录下没有 `build_support/java_compile_recipe.json`
2. 它是“迁移后真实子集”，与 `PT` vuln 的输入契约并不完全对称
3. 若现在直接纳入主对照组，容易把：
   - `IRIS` 能力差异
   - 输入边界不对称
   - compile contract 缺失
   混成一个结论

处理方式：

1. 保留为 `reserve-self-case`
2. 若后续需要专门回答“迁移后 Struts 子集对 `IRIS` 是否天然不友好”，再作为第二轮边界诊断样本单独引入

### 5.2 Synthetic `PT/SSRF` repo smoke case

例如：

1. `PT-JA-REPO-001`
2. `SSRF-JA-REPO-001`

当前不作为主对照证据。

原因：

1. 这批 case 更适合 smoke 和最小机制观察
2. 它们对“官方 case 是否可信”这个问题的解释力不如真实 repo case

## 6. 执行约束

主对照组必须满足以下约束：

1. 与官方 case 使用同一个 `DeepSeek` 模型别名
2. 与官方 case 使用同一个 `IRIS` 变体边界
   - 允许：`iris-runtime-compat-001`
   - 不允许：`capability-changing variant`
3. 与官方 case 使用同一种结果记录口径
4. 与官方 case 一样保存完整 `Reproduction Evidence Package`

## 7. 当前结论

本轮 `Self Comparison Case` 冻结如下：

1. `PT-JA-REPO-CVE-2024-53677-VULN`
2. `SSRF-JA-REPO-CVE-2023-3432-VULN`
3. `SSRF-JA-REPO-CVE-2023-3432-FIXED`

保留但不进入第一轮主对照组：

1. `PT-JA-REPO-CVE-2024-53677-FIXED`
