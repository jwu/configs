#!/usr/bin/env bash
# 两块 NVMe 取更热的那块，输出 waybar 的 json 格式。
# 用设备级路径（/sys/devices/pci…/nvme/nvmeN）+ 通配 hwmon*，
# 这样重启后 hwmon 序号变化也不影响。

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
  printf '{"text":"SSD --°C","class":"off","tooltip":"读不到 NVMe 温度"}\n'
  exit 0
fi

cls=""
[ "$max" -ge 60 ] && cls=warning
[ "$max" -ge 75 ] && cls=critical

printf '{"text":"SSD %s°C","class":"%s","tooltip":"NVMe 最高 %s°C\\n%s"}\n' \
  "$max" "$cls" "$max" "$detail"
