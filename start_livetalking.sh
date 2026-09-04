#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON="${ROOT_DIR}/.venv/bin/python"
PORT="${LIVETALKING_PORT:-8010}"
MODEL="${LIVETALKING_MODEL:-wav2lip}"
AVATAR_ID="${LIVETALKING_AVATAR_ID:-wav2lip256_avatar1}"

cd "$ROOT_DIR"
die() { printf '[LiveTalking] ERROR: %s\n' "$*" >&2; exit 1; }
[[ -x "$PYTHON" ]] || die "Python environment not found: $PYTHON"
[[ -f models/wav2lip.pth ]] || die "Missing model: models/wav2lip.pth"
[[ -f "data/avatars/${AVATAR_ID}/coords.pkl" ]] || die "Missing avatar: data/avatars/${AVATAR_ID}/coords.pkl"
[[ -d "data/avatars/${AVATAR_ID}/full_imgs" ]] || die "Missing avatar frames"
[[ -d "data/avatars/${AVATAR_ID}/face_imgs" ]] || die "Missing avatar face frames"

find "$ROOT_DIR" -type d \( -name __pycache__ -o -name .pytest_cache \) -prune -exec rm -rf {} + 2>/dev/null || true
export PYTHONUNBUFFERED=1
export OMP_NUM_THREADS="${OMP_NUM_THREADS:-$(nproc)}"
export MKL_NUM_THREADS="${MKL_NUM_THREADS:-$OMP_NUM_THREADS}"

DEVICE="$($PYTHON - <<'PY'
import torch
try:
    if torch.cuda.is_available():
        torch.ones(1, device='cuda'); torch.cuda.synchronize(); print('cuda')
    else: print('cpu')
except Exception: print('cpu')
PY
)"
if [[ "$DEVICE" == cuda ]]; then
    printf '[LiveTalking] device: GPU/CUDA (%s)\n' "$($PYTHON -c 'import torch; print(torch.cuda.get_device_name(0))')"
else
    export CUDA_VISIBLE_DEVICES=""
    printf '[LiveTalking] device: CPU\n'
fi

printf '[LiveTalking] starting on port %s...\n' "$PORT"
"$PYTHON" app.py --transport webrtc --model "$MODEL" --avatar_id "$AVATAR_ID" --listenport "$PORT" "$@" &
SERVER_PID=$!
trap 'kill "$SERVER_PID" 2>/dev/null || true' EXIT INT TERM

READY=0
for _ in $(seq 1 60); do
    if curl -fsS -o /dev/null "http://127.0.0.1:${PORT}/index.html" 2>/dev/null; then READY=1; break; fi
    kill -0 "$SERVER_PID" 2>/dev/null || break
    sleep 1
done
[[ "$READY" == 1 ]] || { wait "$SERVER_PID"; die "service failed to become ready"; }

LAN_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
printf '\n[LiveTalking] READY\n  local:   http://127.0.0.1:%s/index.html\n' "$PORT"
[[ -n "$LAN_IP" ]] && printf '  network: http://%s:%s/index.html\n' "$LAN_IP" "$PORT"
printf '  press Ctrl+C to stop\n\n'
wait "$SERVER_PID"
