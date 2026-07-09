# PT-PY-FILE-001

## 一、结论

这是当前样本里最清晰的“OpenAnt 命中目标，而当前系统 strict 被 gate 掉”的 case。

- Ground truth anchor：`app.py:download_file`，重点行段 `14-18`
- OpenAnt Stage1：`VULNERABLE`
- OpenAnt Stage2：`confirmed_vulnerable`
- 当前系统 strict：`no_finding_emitted`
- 当前系统 balanced：`emitted_but_missed_anchor`

## 二、Ground Truth

`datasets/synthetic/PT-PY-FILE-001/ground_truth.json` 的要求很直接：

- source：`request.args.get('filename', '')`
- propagation：`os.path.join(BASE_DIR, filename)`
- sink：`open(file_path, 'rb')`

benchmark 要求命中的是 `download_file()` 内未校验路径进入 `open()` 的 sink 区域。

## 三、OpenAnt 为什么成功

Stage1 顶部 finding：

- unit：`app.py:download_file`
- verdict：`VULNERABLE`
- confidence：`0.95`
- CWE：`22`
- attack vector：`GET /download?filename=../../etc/passwd`

Stage2 继续确认，并且解释里明确指出了两个独立利用面：

- `../` 相对路径穿越
- 绝对路径输入会让 `os.path.join()` 丢弃 `BASE_DIR`

这一点很关键：OpenAnt 不是只给了“像漏洞”的抽象判断，而是把 source、join、sink、攻击向量串成了完整路径。

## 四、当前系统为什么失败

strict 结果：

- status：`no_finding_emitted`
- reason：`conflicting_judgment`

balanced 结果：

- status：`emitted_but_missed_anchor`
- reason：`anchor_mismatch`

而 balanced 的 emitted finding 实际上不是 Path Traversal anchor，而是 Bandit `B201 flask_debug_true`：

- file：`app.py`
- line：`24`
- provider rule：`flask_debug_true`
- 被内部适配为 `path_traversal` finding

所以这个 case 暴露的是两层问题，不是一层：

1. strict gate 把结果压没了。
2. upstream evidence 还存在类型漂移，把 debug 告警映射成了 path traversal finding。

## 五、和“去掉 semantic gate”有什么关系

这个 case 可以支持“strict gate 过强”的判断，但不能被过度简化为“只要去掉 semantic verification 就能追上 OpenAnt”。

原因是：

- 去掉 gate 后，当前系统确实更容易发射 finding。
- 但它当前更容易发射的是 `debug=True` 这类 off-target finding，而不是 GT 指向的 `download_file` sink。

因此这类 case 的正确修复顺序应是：

1. 先修 evidence taxonomy / anchor 绑定。
2. 再评估 strict gate 是否需要放松。

## 六、归类

对应 taxonomy：

- `T1_strict_semantic_veto_on_true_positive`
- `T7_provider_evidence_type_drift`
