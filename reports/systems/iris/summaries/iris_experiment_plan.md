# IRIS 后续实验安排

## 1. 作用

这份文档把 `IRIS` 在本仓库中的后续实验安排固定下来，用于区分：

- 官方行为观察
- 运行兼容修复后的稳定性确认
- 能力改动实验
- 输入边界影响实验

目标不是立即形成正式大样本成绩，而是先把 `IRIS` 的失败模式、适用边界和可迁移机制讲清楚。

## 2. 总体原则

后续实验必须遵守以下约束：

1. 不混淆 `official upstream baseline`、`runtime compatibility variant`、`capability-changing variant`
2. 不同时改 `IRIS` 逻辑和 benchmark 输入边界
3. 不在同一轮中同时改 prompt、候选过滤、ranking、后处理
4. 每个 `run_id` 必须绑定一个 `variant_id`
5. 每轮实验都必须明确：
   - 实验线
   - 目标问题
   - 允许改动范围
   - 进入条件
   - 退出条件

## 3. 三条实验线

### 3.1 官方行为线

#### 目标

回答：

> 官方 `IRIS` 在当前 benchmark 输入边界和本机运行环境下，原始行为是什么？

#### 允许改动

只允许：

- `runtime compatibility variant`
- 本机运行接线修复
- OpenAI-compatible provider 兼容修复

不允许：

- 修改 candidate 选择逻辑
- 修改 source / sink 语义建模
- 修改 prompt 语义
- 修改 ranking / post-processing

#### 当前建议步骤

1. 跑完固定 5 个 Java smoke case
2. 对每个 case 记录：
   - 是否跑通
   - 是否产生可解析输出
   - Stage 1/2/3/4/5/6 的主要卡点
   - `top finding` 是否存在
   - `target_match / off_target / no_signal / runtime_failure`
3. 形成一份官方行为总结

#### 进入条件

- `runtime compatibility variant` 已能稳定执行

#### 退出条件

- 5 个 smoke case 都完成一轮可审计运行
- 已能明确总结 `IRIS` 在 `PT + SSRF` 上的主要失败模式

### 3.2 能力改动线

#### 目标

回答：

> 如果修改 `IRIS` 的候选生成或漏洞语义机制，它是否会更适合当前 benchmark？

#### 允许改动

只允许单变量能力改动，并必须归入 `capability-changing variant`。

典型范围：

- candidate 选择逻辑
- internal / external API 边界
- source / sink / taint-propagator 建模
- prompt 语义
- ranking
- 解析与后处理

#### 不允许

- 同一轮同时改多个能力模块
- 同时修改 benchmark 输入裁剪方式
- 修改后仍把结果写成“官方 IRIS 表现”

#### 推荐顺序

1. `candidate-selection` 实验
   - 目标：验证 internal wrapper API 是否应进入 Stage 3
2. `custom-project metadata` 实验
   - 目标：验证无 upstream CVE metadata 时 Stage 4 如何处理
3. `prompt / parsing` 实验
   - 目标：仅在前两项完成后，再看标签质量问题
4. `ranking / post-processing` 实验
   - 目标：最后再看结果排序与降噪

#### 每轮要求

- 每轮只改一个变量
- 每轮先在 `3-5` 个 case 上验证
- 每轮都登记：
  - `variant_id`
  - 修改文件
  - 修改内容
  - 修改动机
  - 预期影响
  - 首个 `run_id`

#### 进入条件

- 官方行为线已经完成
- 失败模式已经足够明确，值得验证机制改动

#### 退出条件

- 单变量改动能稳定改变某一类失败模式
- 或证明该改动不值得继续扩大

### 3.3 输入边界线

#### 目标

回答：

> 当前 benchmark 的 `Compile Recipe` 和 `Clean Input` 裁剪方式，是否天然限制了 `IRIS` 的可用性？

#### 性质

这条线是：

- `Boundary-Condition Diagnostic Expansion`

不是：

- 官方 IRIS 能力评估
- 能力改动实验

#### 允许改动

只允许改 benchmark 输入形态，不改 `IRIS` 逻辑。

例如：

- 官方 `Compile Recipe`
- 轻度扩展 recipe
- 更完整 repo slice

#### 不允许

- 同时改 `IRIS` 的候选逻辑
- 把输入扩展结果和官方输入边界结果混成一个结论

#### 推荐顺序

1. 官方 `Compile Recipe`
2. 轻度扩展 `Compile Recipe`
3. 更完整的 repo 子集

#### 进入条件

- 官方行为线或能力改动线已经暴露出“疑似输入边界导致”的失败

#### 退出条件

- 已能明确回答某类失败究竟来自 `IRIS` 机制，还是来自 benchmark 输入裁剪

## 4. 推荐执行顺序

建议按以下顺序推进：

1. 完成官方行为线的 5-case smoke 总结
2. 开始第一个能力改动实验：
   - `candidate-selection`
3. 若该实验明显改善行为，再进入 `10-15` case 的诊断性评估
4. 最后再做输入边界线，用于解释剩余失败是否来自 benchmark 裁剪

## 5. 每轮实验的最小记录要求

每轮至少记录：

```text
run_id:
variant_id:
experiment_line:
system_name:
system_version:
case_id:
vuln_type:
input_mode:
compile_recipe_mode:
allowed_modification_scope:
observed_stage_boundary:
system_verdict:
top_finding_valid:
target_match:
off_target:
failure_reason:
notes:
```

## 6. 当前建议的下一步

当前最合理的下一步不是继续同时改多个位置，而是：

1. 先完成官方行为线总结
2. 把 `candidate-selection` 作为第一条 `capability-changing variant`
3. 单独验证：
   - internal wrapper API 进入 Stage 3 后，是否能产生 `source / sink`
   - 该变化是否改变最终 `results.csv`

## 7. 结论解释规则

后续任何结论都必须带前缀说明它属于哪条线：

- `官方行为结论`
- `运行兼容结论`
- `能力改动结论`
- `输入边界结论`

不得只写“IRIS 表现如何”，否则会丢失版本边界。
