# Learn Flappy Bird - 强化学习训练与推理说明

本项目由两部分组成：

| 目录 | 说明 |
| --- | --- |
| `Godot/` | Flappy Bird 游戏本体（Godot 4.6 .NET），内置 `godot_rl_agents` 插件，负责提供环境/观测/动作，并可通过 ONNX 在游戏内直接推理 |
| `Backend/` | Python 端（`godot_rl`），负责通过 TCP 连接 Godot、训练 PPO、导出 ONNX |

- 模型保存位置：`Backend/model/ppo_model.zip`
- 导出的 ONNX：`Backend/model/ppo_model.onnx`（当前已由 `ppo_model.zip` 导出）
- 训练日志：`Backend/logs/sb3/`

环境交互方式：Python 启动一个 TCP 服务端（默认端口 `11008`），Godot 里的 `Sync` 节点作为客户端连接；Python 收集观测并下发动作。

- 观测（8 维）：6 个射线传感器距离 + 金币传感器纵向偏移 + 小鸟纵向速度
- 动作（离散 2 个）：`0` = 不扇翅膀，`1` = 向上飞

---

## 1. 环境准备

### 1.1 Godot

- 需要 **Godot 4.x .NET（C# / Mono）版本**，下载文件名带 `_mono`（例如 `Godot_v4.7.2-stable_mono_win64`）。用这个编辑器打开 `Godot/` 目录。
- 项目已启用 `godot_rl_agents` 插件，主场景为 `Godot/main/main.tscn`。
- `project.godot` 中已配置 `config/features` 包含 `C#`，并有 `[dotnet] project/assembly_name="Godot RL Agents"`。
- `Godot RL Agents.csproj` 使用 `Godot.NET.Sdk/4.7.2` + `net8.0`，其中引用了 `Microsoft.ML.OnnxRuntime`。需要安装 .NET SDK（8.0 或更高）。
- **`Godot.NET.Sdk` 版本要和你实际使用的 Godot 编辑器版本一致**；换用其它 4.x 版本时，同步修改 csproj 里的 `Godot.NET.Sdk/x.y.z`。
- 首次打开项目后先构建 C# 程序集：编辑器右上角的 **Build** 按钮，或在 `Godot/` 目录执行 `dotnet build "Godot RL Agents.csproj"`。ONNX 推理依赖该程序集。

> **普通版（非 .NET）Godot 无法加载 `.cs` 脚本**，会报：
> `No loader found for resource: res://addons/godot_rl_agents/onnx/csharp/ONNXInference.cs`。
> 这不是模型路径的问题，换成 .NET 版编辑器并完成 C# 构建即可。

### 1.2 Python（conda 环境）

不要污染系统 Python，本项目使用独立 conda 环境 `flappy_rl`：

```powershell
conda create -n flappy_rl python=3.11 -y
conda activate flappy_rl
pip install numpy==1.26.4 gymnasium==1.0.0 stable-baselines3==2.4.0 torch tensorboard onnx==1.19.0 ml-dtypes==0.5.4 onnxruntime
```

版本约束很重要：

- `stable-baselines3 2.4.0` 要求 `numpy < 2.0`，所以固定 `numpy==1.26.4`。
- `onnx 1.19.0` 需要 `ml-dtypes >= 0.5`，而 Python 3.11 下 `ml-dtypes 0.5.4` 仍兼容 `numpy 1.26`。
- 如果 `onnx` 和 `ml-dtypes` 版本不匹配，导出时会报
  `AttributeError: module 'ml_dtypes' has no attribute 'float4_e2m1fn'`。

以下所有 Python 命令都默认：

```powershell
conda activate flappy_rl
cd Backend
```

---

## 2. 训练

训练脚本：`Backend/train/stable_baselines3_example.py`。

### 2.1 方式 A：在 Godot 编辑器里训练（推荐，方便观察）

1. 在 Godot 编辑器中打开 `Godot/` 项目。
2. 确认 `main.tscn` 的 `Sync` 节点 `control_mode` 为 `TRAINING`（默认值）。
3. 启动 Python 训练脚本：

   ```powershell
   conda activate flappy_rl
   cd Backend
   python train/stable_baselines3_example.py --timesteps 1000000 --speedup 1
   ```

4. 终端出现 `waiting for remote GODOT connection on port 11008` 后，**60 秒内**在 Godot 编辑器按 `F5`（或点击右上角运行按钮）。

编辑器模式会一直渲染，且 `--viz` 在此模式下没有意义、`--n_parallel` 只能为 1。

### 2.2 方式 B：用导出的游戏 exe 训练（可无头、可并行）

先在 Godot 中 `项目 -> 导出` 添加一个 Windows 导出预设并导出 exe，然后：

```powershell
python train/stable_baselines3_example.py --env_path "D:\path\to\LearnFlappyBird.exe" --timesteps 1000000
```

- 不加 `--viz` 时游戏以 `--headless --disable-render-loop` 无头运行，训练更快。
- 加 `--viz` 可以看到游戏窗口。
- 可加 `--speedup 4` 加速物理；`--n_parallel 4` 启动多个实例并行采样（必须提供 `--env_path`）。

### 2.3 常用参数

| 参数 | 默认值 | 说明 |
| --- | --- | --- |
| `--env_path` | 无 | 游戏 exe 路径；不填则在编辑器中手动 Play |
| `--timesteps` | `1000000` | 训练总步数 |
| `--save_model_path` | `model/ppo_model.zip` | 训练结束/中断后保存模型的位置（自动加 `.zip`） |
| `--resume_model_path` | 无 | 从已有 `.zip` 继续训练 |
| `--save_checkpoint_frequency` | 无 | 每 N 个环境步保存一次 checkpoint 到 `logs/sb3/<experiment_name>_checkpoints/` |
| `--experiment_dir` | `logs/sb3` | TensorBoard 日志目录 |
| `--experiment_name` | `godot_flappy` | TensorBoard 运行名 |
| `--onnx_export_path` | 无 | 训练结束后导出 ONNX（自动加 `.onnx`） |
| `--n_parallel` | `1` | 并行环境实例数 |
| `--speedup` | `1` | 物理加速倍数 |
| `--action_repeat` | 无 | 每隔 N 帧才执行一次动作/采样；不填则用 Godot 同步节点里的设置 |
| `--viz` | 关闭 | 显示游戏窗口（仅 exe 模式有效） |
| `--learning_rate` / `--n_steps` / `--batch_size` / `--ent_coef` / `--clip_range` | 见脚本 | PPO 超参数 |
| `--linear_lr_schedule` | 关闭 | 线性衰减学习率 |

查看 TensorBoard：

```powershell
tensorboard --logdir logs/sb3
```

### 2.4 继续训练（微调）

```powershell
python train/stable_baselines3_example.py --resume_model_path model/ppo_model.zip --timesteps 500000
```

### 2.5 训练完成后的产物

- `model/ppo_model.zip`：SB3 模型，可继续训练、做 Python 推理，或再次导出 ONNX。
- `logs/sb3/`：TensorBoard 曲线。
- 如果传了 `--onnx_export_path`，还会得到 `.onnx` 文件。

> 注意：脚本只在训练正常结束、`Ctrl+C` 中断或连接异常时执行 `cleanup()` 保存模型/导出 ONNX。使用 `--inference` 时不会执行该逻辑。

---

## 3. 使用 `ppo_model.zip`（Python 推理 / 看模型玩游戏）

```powershell
conda activate flappy_rl
cd Backend
python train/stable_baselines3_example.py --resume_model_path model/ppo_model.zip --inference --timesteps 100000
```

- 启动后同样在 60 秒内在 Godot 编辑器按 `F5`（`Sync.control_mode` 保持 `TRAINING`），或加 `--env_path` 使用 exe。
- `--timesteps` 在这里表示推理步数。
- 推理使用 `model.predict(obs, deterministic=True)`，动作不带随机性。
- 这种方式**必须保持 Python 进程运行**，适合调试和录制；想脱离 Python 独立运行请用下一节的 ONNX。

---

## 4. 导出 ONNX

### 4.1 从已保存的 `.zip` 导出（不需要启动 Godot）

```powershell
conda activate flappy_rl
cd Backend
python -c "from stable_baselines3 import PPO; from godot_rl.wrappers.onnx.stable_baselines_export import export_model_as_onnx; export_model_as_onnx(PPO.load('model/ppo_model.zip'), 'model/ppo_model.onnx')"
```

### 4.2 训练结束时自动导出

```powershell
python train/stable_baselines3_example.py --timesteps 1000000 --onnx_export_path model/ppo_model.onnx
```

导出说明：

- 必须在 `Backend` 目录下运行（保证能导入 `godot_rl`）。
- 离散动作空间（本项目是 `Discrete(2)`）的模型跳过数值校验，ONNX 输出的是**动作 logits**，Godot 端会对 logits 取 argmax 得到动作。
- ONNX 导出依赖 `onnx`，它又会导入 `ml-dtypes`/`numpy`，所以请使用第 1.2 节固定的版本组合。

---

## 5. 在 Godot 中使用 ONNX（脱离 Python 运行）

1. 把导出的模型复制到 Godot 项目里，例如：

   ```powershell
   New-Item -ItemType Directory -Force "Godot\model"
   Copy-Item "Backend\model\ppo_model.onnx" "Godot\model\ppo_model.onnx"
   ```

2. 打开 `Godot/main/main.tscn`，选中 `Sync` 节点，在检查器中设置：

   - `control_mode`：`ONNX_INFERENCE`
   - `onnx_model_path`：`res://model/ppo_model.onnx`

   或者把模型路径直接设在 `Bird/AIController2D` 节点的 `onnx_model_path` 上（此时该节点的 `control_mode` 用 `ONNX_INFERENCE`；若为 `INHERIT_FROM_SYNC` 则继承 `Sync` 的模式）。

3. 直接运行项目（`F5`），小鸟就会由 ONNX 模型控制，不再需要启动 Python。

注意事项：

- **必须使用 Godot .NET 版本**，且 C# 程序集已成功编译，否则 `ONNXModel` 无法加载。
- `onnx_model_path` 使用 `res://` 路径，导出游戏时该资源必须被包含。
- 推理时的 `action_repeat` 应与训练时一致（本项目默认都是 `1`），否则模型表现会变差。
- `Sync` 节点的控制模式枚举与 `AIController2D` 的不同：
  - `Sync`：`0=HUMAN`、`1=TRAINING`、`2=ONNX_INFERENCE`
  - `AIController2D`：`0=INHERIT_FROM_SYNC`、`1=HUMAN`、`2=TRAINING`、`3=ONNX_INFERENCE`、`4=RECORD_EXPERT_DEMOS`

---

## 6. 推荐工作流

1. `conda activate flappy_rl`，进入 `Backend`。
2. 编辑器内训练得到 `model/ppo_model.zip`（可反复 `--resume_model_path` 续训）。
3. 用 `--inference` 在 Python 里快速验证效果。
4. 导出 `model/ppo_model.onnx`。
5. 复制到 `Godot/model/`，把 `Sync` 设为 `ONNX_INFERENCE`，直接运行游戏。

---

## 7. 常见问题

| 现象 | 原因 / 解决 |
| --- | --- |
| `AttributeError: module 'ml_dtypes' has no attribute 'float4_e2m1fn'` | `onnx` 与 `ml-dtypes` 版本不匹配。用 `flappy_rl` 环境中的固定版本组合，不要随意升级 `numpy` 到 2.x |
| `stable-baselines3 ... requires numpy<2.0` | 同上，保持 `numpy==1.26.4` |
| 一直停在 `waiting for remote GODOT connection` 然后超时 | 60 秒内没在 Godot 里 Play；或 `Sync.control_mode` 不是 `TRAINING`；或端口 `11008` 被占用 |
| `You must provide the path to a exported game executable if n_parallel > 1` | 编辑器模式只能 `--n_parallel 1`，多开请用 `--env_path` |
| `... folder already exists. Use a different --experiment_dir ...` | 开了 checkpoint 且同名目录已存在，换个 `--experiment_name` 或删掉旧 checkpoint 目录 |
| ONNX 推理报模型路径不存在 | `onnx_model_path` 写错，或模型没复制进 Godot 项目（要 `res://` 路径） |
| `No loader found for resource: .../onnx/csharp/ONNXInference.cs` | 用的是普通版 Godot，不支持 C#。安装 Godot 4.6 .NET（`_mono`）版本打开项目，并构建 C# 程序集 |
| ONNX 推理报 C#/ONNXRuntime 相关错误 | 用的不是 Godot .NET 版本，或 C# 程序集没编译成功（`dotnet build` 检查） |
| `Gym has been unmaintained ...` 警告 | 只是警告，可忽略；本项目实际使用 `gymnasium` |
