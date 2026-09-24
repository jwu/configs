#!/usr/bin/env bash
# Hottest disk in this machine, as waybar JSON.
#
# Disks are discovered from /sys/block and matched to their temperature sensor
# through the hwmon device symlink, so nothing is tied to a PCI address or a
# drive count: a machine with only a SATA disk reports HDD, one with NVMe
# reports SSD, and a mixed machine reports the kind of whichever disk it picks.
#
# Warning/critical are the drive's own limits, not ours: temp1_max and
# temp1_crit come from the drive (NVMe: the standard WCTEMP/CCTEMP fields,
# SATA: whatever drivetemp reports), so an HDD and an NVMe get thresholds that
# actually fit them. A drive exposing neither falls back to DEFAULT_* below.
# Because the limits differ per drive, the reading shown is from the disk in
# the worst state - not simply the hottest one.
#
# SATA/HDD temperatures need the drivetemp kernel module (loaded at boot by
# /etc/modules-load.d/drivetemp.conf, see linux/config.sh); without it those
# disks are listed as --°C. See docs/waybar.md.
#
# Everything below is a bash builtin. waybar re-runs this on a timer, and the
# fork/exec of cat/sed/readlink cost several times the logic itself: measured
# ~19ms per run with them, ~10ms without.

# Fallback limits for a drive that reports none of its own.
DEFAULT_WARN=60
DEFAULT_CRIT=75

# Labels are MDI box letters (md-alpha_*_box) spelling SSD / HDD. Pango sizes
# are pt, not px (15pt = 20px); see docs/waybar.md.
box_s=$(printf '\U000F0B1A')
box_d=$(printf '\U000F0B0B')
box_h=$(printf '\U000F0B0F')

# Zero-width struts keep this module's line box aligned with the others
# (see docs/waybar.md).
zwsp=$'\u200b'
strut="<span size='15pt'>${zwsp}</span><span size='15pt' rise='-1536'>${zwsp}</span>"
box() { printf "<span size='15pt' rise='-1536'>%s</span>" "$1"; }

# Resolve a sysfs symlink to its physical path. A subshell running the pwd
# builtin is cheaper than readlink(1), and unlike a plain glob it also covers
# both hwmon layouts in the wild (device/hwmonN and device/hwmon/hwmonN).
phys() { CDPATH= cd -- "$1" 2>/dev/null && pwd -P; }

# Millidegrees to whole degrees, or $2 when the value is missing or nonsense:
# a drive reporting temp1_max = 0 would otherwise mark every reading as hot.
degrees() {
  case "${1:-}" in
    ''|*[!0-9]*) printf '%s' "$2" ;;
    *)
      local value=$(( $1 / 1000 ))
      if [ "$value" -gt 0 ]; then printf '%s' "$value"; else printf '%s' "$2"; fi
      ;;
  esac
}

# Physical device path -> its sensor, so each disk finds its own hwmon node
# regardless of the index it happened to get. temp1 is the composite reading.
declare -A TEMP=() TEMP_MAX=() TEMP_CRIT=()
for hw in /sys/class/hwmon/hwmon*; do
  [ -r "$hw/temp1_input" ] || continue
  hw_device=$(phys "$hw/device") || continue
  [ -n "$hw_device" ] || continue
  TEMP["$hw_device"]=$(<"$hw/temp1_input")
  [ -r "$hw/temp1_max" ]  && TEMP_MAX["$hw_device"]=$(<"$hw/temp1_max")
  [ -r "$hw/temp1_crit" ] && TEMP_CRIT["$hw_device"]=$(<"$hw/temp1_crit")
done

# Worst state wins (2 critical > 1 warning > 0 ok); ties go to the hotter disk.
# -1 means "no reading", which is the empty tooltip case.
best_severity=-1
best_temp=0
best_kind=""
detail=""

for blk in /sys/block/*; do
  disk=${blk##*/}
  # Skip virtual and non-disk block devices: zram (swap), loop, dm/md (RAID,
  # LUKS), sr (optical), ram, fd.
  case "$disk" in
    zram*|loop*|ram*|dm-*|md*|sr*|fd*) continue ;;
  esac

  device=$(phys "$blk/device") || continue
  [ -n "$device" ] || continue

  # Rotational media are HDDs; everything else (NVMe, SATA SSD) is an SSD.
  rotational=""
  [ -r "$blk/queue/rotational" ] && rotational=$(<"$blk/queue/rotational")
  if [ "$rotational" = 1 ]; then
    kind=HDD
  else
    kind=SSD
  fi

  # /sys pads both fields with spaces, and the SCSI "model" is truncated to 16
  # characters, so vendor + model carries the most of the real name we get.
  vendor=""; [ -r "$blk/device/vendor" ] && vendor=$(<"$blk/device/vendor")
  model="";  [ -r "$blk/device/model" ]  && model=$(<"$blk/device/model")
  name="$vendor $model"
  name="${name#"${name%%[![:space:]]*}"}"    # strip leading spaces
  name="${name%"${name##*[![:space:]]}"}"    # strip trailing spaces
  while [[ $name == *"  "* ]]; do            # collapse runs of spaces
    name=${name//  / }
  done

  raw=${TEMP["$device"]:-}
  case "$raw" in ''|*[!0-9]*) temp="" ;; *) temp=$((raw / 1000)) ;; esac
  warn=$(degrees "${TEMP_MAX["$device"]:-}" "$DEFAULT_WARN")
  crit=$(degrees "${TEMP_CRIT["$device"]:-}" "$DEFAULT_CRIT")

  [ -n "$detail" ] && detail="${detail}\\n"
  if [ -n "$temp" ]; then
    detail="${detail}${disk}: ${temp}°C   ${name} (${kind}, max ${warn} / crit ${crit})"

    if [ "$temp" -ge "$crit" ]; then
      severity=2
    elif [ "$temp" -ge "$warn" ]; then
      severity=1
    else
      severity=0
    fi

    if [ "$severity" -gt "$best_severity" ] \
      || { [ "$severity" -eq "$best_severity" ] && [ "$temp" -gt "$best_temp" ]; }; then
      best_severity=$severity
      best_temp=$temp
      best_kind=$kind
    fi
  else
    detail="${detail}${disk}: --°C   ${name} (${kind})"
  fi
done

case "$best_kind" in
  HDD) label=$(box "${box_h}${box_d}${box_d}") ;;
  *)   label=$(box "${box_s}${box_s}${box_d}") ;;
esac

if [ "$best_severity" -lt 0 ]; then
  printf '{"text":"%s %s --°C","class":"off","tooltip":"读不到磁盘温度\\n%s"}\n' \
    "$strut" "$label" "$detail"
  exit 0
fi

case "$best_severity" in
  2) cls=critical ;;
  1) cls=warning ;;
  *) cls="" ;;
esac

printf '{"text":"%s %s %s°C","class":"%s","tooltip":"%s 最高 %s°C\\n%s"}\n' \
  "$strut" "$label" "$best_temp" "$cls" "$best_kind" "$best_temp" "$detail"
