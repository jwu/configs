#!/usr/bin/env bash
# Hottest of the two NVMe drives, as waybar JSON.
# Uses device paths (/sys/devices/pci.../nvme/nvmeN) with a hwmon* glob,
# so a changed hwmon index after reboot is harmless.

# Labels are MDI box letters (md-alpha_*_box), "SSD" = 󰬚󰬚󰬋
label_ssd="<span size='15pt' rise='-1536'>󰬚󰬚󰬋</span>"   # 15pt = 20px (Pango size has no px); see docs/waybar.md
# Zero-width struts keep this module's line box aligned with the others
# (see docs/waybar.md).
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
