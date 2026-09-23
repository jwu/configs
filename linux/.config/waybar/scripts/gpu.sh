#!/usr/bin/env bash
# GPU metrics for both custom modules:
#   gpu.sh util  -> 󰬎󰬗󰬜 11%      (class: "" | warning>=70 | critical>=90)
#   gpu.sh temp  -> 40°C       (class: "" | warning>=75 | critical>=85)
# Output is waybar JSON: {"text":..., "class":..., "tooltip":...}.
# One nvidia-smi call is ~22ms, negligible at 2s intervals.

# Labels are MDI box letters (md-alpha_*_box), "GPU" = 󰬎󰬗󰬜
label_gpu="<span size='15pt' rise='-1536'>󰬎󰬗󰬜</span>"   # 15pt = 20px (Pango size has no px); see docs/waybar.md
# Zero-width struts keep this module's line box the same height as its
# neighbours (see docs/waybar.md).
zwsp=$'\u200b'
strut="<span size='15pt'>${zwsp}</span><span size='15pt' rise='-1536'>${zwsp}</span>"

mode="${1:-util}"

read -r util temp <<<"$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu \
  --format=csv,noheader,nounits 2>/dev/null | tr -d ',')"

if [ -z "${util:-}" ] || [ -z "${temp:-}" ]; then
  printf '{"text":"","class":"off","tooltip":"nvidia-smi 不可用"}\n'
  exit 0
fi

cls=""
if [ "$mode" = temp ]; then
  text="${strut}${temp}°C"
  [ "$temp" -ge 75 ] && cls=warning
  [ "$temp" -ge 85 ] && cls=critical
else
  text="${strut}${label_gpu} ${util}%"
  [ "$util" -ge 70 ] && cls=warning
  [ "$util" -ge 90 ] && cls=critical
fi

printf '{"text":"%s","class":"%s","tooltip":"GPU: %s%%  %s°C"}\n' "$text" "$cls" "$util" "$temp"
