#!/usr/bin/env bash
# GPU 指标，供 waybar 两个 custom 模块共用：
#   gpu.sh util  -> 󰬎󰬗󰬜 11%      （class: "" | warning>=70 | critical>=90）
#   gpu.sh temp  -> 40°C       （class: "" | warning>=75 | critical>=85）
# 输出 waybar 的 json 格式：{"text":..., "class":..., "tooltip":...}
# 一次 nvidia-smi 调用约 22ms，2 秒一次可忽略。

# 标签用 MDI 带框字母（md-alpha_*_box）拼出来：“GPU” = 󰬎󰬗󰬜
label_gpu="<span size='15pt' rise='-1536'>󰬎󰬗󰬜</span>"   # 15pt = 20px（Pango 的 size 只认 pt/%/关键字，不认 px）
# 单独的温度模块里没有 20px 字形，行高会比邻居矮 → 文字整体高 1px。
# 用零宽空格（U+200B）拼一个 20px 高的“撑高”span：只影响行高，不占宽度。
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
