# SSRF-JA-REPO-001 E1 Pilot Memo

这个 family 的 `E1` pilot 使用了 3 份既有权威原始证据，重新封装成架构归因实验线下的 `A/B/C` 证据包，并按 runbook 记录 `D` 的停止条件。

结果很清楚：

- `A original` 复现了 baseline：`source=0, sink=0, results=0`
- `B oracle candidate` 补回 `RestTemplate.getForObject` 后，`sink` 从 `0` 变成 `1`，但 `MySinks.qll` 仍然是 `1 = 0`
- `C oracle summary/path` 再补最小 source/sink 物化语义后，恢复了 target-aligned SSRF finding

因此，这个 pilot 支持的结论是：

`SSRF-JA-REPO-001` 的 baseline miss 先表现为 candidate gate，但真正恢复 target-aligned result 仍依赖最小 source/sink QLL 物化语义修正。

按 `E1` runbook 的停止规则，`C` 已经恢复 target-aligned result，因此 `D oracle slice` 不再继续执行，只保留显式 `skipped` 记录。
