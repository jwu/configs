#!/usr/bin/env bash
# GPU 指标，供 waybar 两个 custom 模块共用：
#   gpu.sh util  -> 󰚗 11%      （class: "" | warning>=70 | critical>=90）
#   gpu.sh temp  -> 40°C       （class: "" | warning>=75 | critical>=85）
# 输出 waybar 的 json 格式：{"text":..., "class":..., "tooltip":...}
# 一次 nvidia-smi 调用约 22ms，2 秒一次可忽略。

mode="${1:-util}"

read -r util temp <<<"$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu \
  --format=csv,noheader,nounits 2>/dev/null | tr -d ',')"

if [ -z "${util:-}" ] || [ -z "${temp:-}" ]; then
  printf '{"text":"","class":"off","tooltip":"nvidia-smi 不可用"}\n'
  exit 0
fi

cls=""
if [ "$mode" = temp ]; then
  text="${temp}°C"
  [ "$temp" -ge 75 ] && cls=warning
  [ "$temp" -ge 85 ] && cls=critical
else
  text="GPU ${util}%"
  [ "$util" -ge 70 ] && cls=warning
  [ "$util" -ge 90 ] && cls=critical
fi

printf '{"text":"%s","class":"%s","tooltip":"GPU: %s%%  %s°C"}\n' "$text" "$cls" "$util" "$temp"
