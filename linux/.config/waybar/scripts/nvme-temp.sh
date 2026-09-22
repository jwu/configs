#!/usr/bin/env bash
# 两块 NVMe 取更热的那块，输出 waybar 的 json 格式。
# 用设备级路径（/sys/devices/pci…/nvme/nvmeN）+ 通配 hwmon*，
# 这样重启后 hwmon 序号变化也不影响。

# 标签用 MDI 带框字母（md-alpha_*_box）拼出来：“SSD” = 󰬚󰬚󰬋
label_ssd="<span size='15pt' rise='-1536'>󰬚󰬚󰬋</span>"   # 15pt = 20px（Pango 的 size 只认 pt/%/关键字，不认 px）
# 两段零宽撑高（U+200B，不占宽度）：让本模块的 line box 和其它模块一致（基线对齐），
# 第二段下移 2px 是为了把 descent 也撑到 7.3px——详见 style.css 顶部“基线与行高约定”。
zwsp=$'\u200b'
strut="<span size='15pt'>${zwsp}</span><span size='15pt' rise='-1536'>${zwsp}</span>"

paths=(
  /sys/devices/pci0000:00/0000:00:06.0/0000:02:00.0/nvme/nvme0/hwmon*/temp1_input
  /sys/devices/pci0000:00/0000:00:1a.0/0000:03:00.0/nvme/nvme1/hwmon*/temp1_input
)

max=0
detail=""
for p in "${paths[@]}"; do
  [ -r "$p" ] || continue
  t=$(( $(cat "$p") / 1000 ))
  dev=$(printf '%s' "$p" | sed 's|.*/\(nvme[0-9]\).*|\1|')
  case "$dev" in
    nvme0) model="WD_BLACK SN770 1TB  (/ /boot swap)" ;;
    nvme1) model="WD_BLACK SN770 500GB" ;;
    *)     model="$dev" ;;
  esac
  [ -n "$detail" ] && detail="${detail}\\n"
  detail="${detail}${dev}: ${t}°C   ${model}"
  [ "$t" -gt "$max" ] && max=$t
done

if [ "$max" -eq 0 ]; then
  printf '{"text":"%s --°C","class":"off","tooltip":"读不到 NVMe 温度"}\n' "$label_ssd"
  exit 0
fi

cls=""
[ "$max" -ge 60 ] && cls=warning
[ "$max" -ge 75 ] && cls=critical

printf '{"text":"%s %s°C","class":"%s","tooltip":"NVMe 最高 %s°C\\n%s"}\n' \
  "${strut}${label_ssd}" "$max" "$cls" "$max" "$detail"
