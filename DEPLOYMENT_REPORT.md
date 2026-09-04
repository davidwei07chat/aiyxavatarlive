# LiveTalking 部署报告

生成时间：2026-08-30 12:00 JST

## 结论

LiveTalking 代码和 Python 运行环境已部署到本服务器 `/opt/LiveTalking`，依赖安装和基础代码验证通过。

完整业务可用性验证未通过。当前服务器缺少两个必要条件：

1. 未安装或不可见 NVIDIA GPU/CUDA 运行时，`torch.cuda.is_available()` 为 `False`。
2. 项目必需模型资产未就绪：`/opt/LiveTalking/models/wav2lip.pth` 和 `/opt/LiveTalking/data/avatars/wav2lip256_avatar1/` 不存在。

因此服务无法完成主程序启动，无法验证 WebRTC 数字人视频流、文本驱动口型同步和端到端对话。

## 部署信息

- 仓库地址：https://github.com/lipku/LiveTalking.git
- 部署目录：`/opt/LiveTalking`
- 部署提交：`c4f8c16a86bdc4d217782cac52fb431dc5bca7b0`
- 提交时间：`2026-08-30T08:51:54+08:00`
- Python：`3.12.3`
- 虚拟环境：`/opt/LiveTalking/.venv`
- 启动脚本：`/opt/LiveTalking/start_livetalking.sh`
- 默认端口：`8010`
- 默认模式：`webrtc`
- 默认模型：`wav2lip`
- 默认 avatar：`wav2lip256_avatar1`

## 已完成工作

- 已克隆 LiveTalking 仓库到 `/opt/LiveTalking`。
- 已创建 Python 3.12 虚拟环境。
- 已安装 CPU 版 PyTorch、torchvision、torchaudio。
- 已安装 `requirements.txt` 中的项目依赖。
- 已额外安装 `gdown`，用于尝试 Google Drive 模型下载。
- 已确认 FFmpeg 可用。
- 已创建启动脚本 `/opt/LiveTalking/start_livetalking.sh`。

## 验证结果

| 检查项 | 结果 | 说明 |
| --- | --- | --- |
| `pip check` | 通过 | 无损坏依赖 |
| 关键模块导入 | 通过 | `torch`、`cv2`、`aiortc`、`aiohttp`、`librosa`、`soundfile`、`transformers` 可导入 |
| CUDA/GPU | 未通过 | 服务器无 `nvidia-smi`，PyTorch 显示 CUDA 不可用 |
| Python 源码编译 | 通过 | `compileall` 无错误 |
| 自带测试 | 通过 | `python -m unittest discover -s tests -v`，2 个测试通过 |
| 静态前端资源 | 通过 | `web/index.html` 可通过 HTTP 返回 200 |
| 主服务启动 | 未通过 | 缺少 `./models/wav2lip.pth` |
| 端到端数字人验证 | 未执行 | 主服务未能完成启动，且缺少 GPU/模型资产 |

## 主服务启动失败记录

执行命令：

```bash
/opt/LiveTalking/.venv/bin/python app.py --transport webrtc --model wav2lip --avatar_id wav2lip256_avatar1 --listenport 8010
```

失败原因：

```text
FileNotFoundError: [Errno 2] No such file or directory: './models/wav2lip.pth'
```

项目要求默认 wav2lip 部署至少准备：

- `models/wav2lip.pth`
- `data/avatars/wav2lip256_avatar1/coords.pkl`
- `data/avatars/wav2lip256_avatar1/full_imgs/`
- `data/avatars/wav2lip256_avatar1/face_imgs/`

## 模型下载情况

README 提供的 Google Drive 文件夹链接可发起访问，但本服务器使用 `gdown --folder` 解析目录时长时间无响应，已中止。README 同时提供夸克云盘链接，但该类网盘通常需要浏览器或账号人工下载，未能在服务器上无人值守完成。

## 后续上线步骤

1. 在服务器上配置 NVIDIA GPU、驱动、CUDA 和匹配版本 PyTorch。项目 README 声明测试环境为 Ubuntu 22.04、Python 3.12、PyTorch 2.9.1、CUDA 12.8。
2. 下载官方模型资产，并放置到：
   - `/opt/LiveTalking/models/wav2lip.pth`
   - `/opt/LiveTalking/data/avatars/wav2lip256_avatar1/`
3. 赋予启动脚本执行权限：

```bash
chmod +x /opt/LiveTalking/start_livetalking.sh
```

4. 启动服务：

```bash
/opt/LiveTalking/start_livetalking.sh
```

5. 验证：
   - 浏览器打开 `http://<server-ip>:8010/index.html`
   - 点击开始连接，确认 WebRTC 视频流正常
   - 调用 `/human` 提交 echo 文本，确认数字人发声和口型同步
   - 查看日志中 `inferfps`、`finalfps`，两者应达到项目建议的实时标准

## 当前判定

当前状态为“基础部署完成，完整可用性未达成”。主要原因不是 Python 依赖安装失败，而是本服务器不具备 LiveTalking 实时推理所需的 GPU/CUDA 条件，并且官方模型资产未落盘。
