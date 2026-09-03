#!/system/bin/sh
#
# set_cpu_gpu_governors_8pro.sh  –  Pin every CPU & every devfreq node to the “performance” governor
#
# Run me as root on the PHONE:
# Step 1: adb push ./experiments/set_cpu_gpu_governors_8pro.sh /data/local/tmp
# Step 2: adb shell "chmod 755 /data/local/tmp/set_cpu_gpu_governors_8pro.sh"
# Step 3: adb shell "su -c sh /data/local/tmp/set_cpu_gpu_governors_8pro.sh"
# Step 4: configure CPUs' min_freq and max_freq using 3C All-in-One app
  ## cpu0-3:1.32GHz cpu4-7:1.57GHz cpu8:2.04GHz

# watch -n 0.5 'adb shell cat /sys/devices/system/cpu/cpu8/cpufreq/scaling_cur_freq'
# watch -n 0.5 'adb shell cat /sys/devices/system/cpu/cpu4/cpufreq/scaling_cur_freq'
# watch -n 0.5 'adb shell cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq'


# Example output:
# --- Result ---
# cpu0: 1704000 kHz
# cpu1: 1704000 kHz
# cpu2: 1704000 kHz
# cpu3: 1704000 kHz
# cpu4: 2367000 kHz
# cpu5: 2367000 kHz
# cpu6: 2367000 kHz
# cpu7: 2367000 kHz
# cpu8: 2914000 kHz
# 17000010.devfreq_mif: 3744000 kHz
# 17000020.devfreq_int: 1066000 kHz
# 17000030.devfreq_intcam: 664000 kHz
# 17000040.devfreq_disp: 664000 kHz
# 17000050.devfreq_cam: 711000 kHz
# 17000060.devfreq_tnr: 664000 kHz
# 17000070.devfreq_mfc: 711000 kHz
# 17000080.devfreq_bw: 711000 kHz
# 17000090.devfreq_dsu: 1800000 kHz
# 170000a0.devfreq_bci: 1401000 kHz
# gs_dsulat_devfreq:devfreq_dsulat@17000090: 1800000 kHz
# gs_memlat_devfreq:devfreq_mif_lat@17000010: 3744000 kHz

# --- CPUs --------------------------------------------------------------
# governor options: sched_pixel(default) conservative powersave performance scheduti
CPU_GOVERNOR=performance
for dir in /sys/devices/system/cpu/cpu[0-9]*; do
  gov="$dir/cpufreq/scaling_governor"
  [ -w "$gov" ] && echo "$CPU_GOVERNOR" > "$gov"
done

# --- devfreq domains ---------------------------------------------------
# governor options: gs_memlat gs_dsulat interactive(default) userspace powersave performance simple_ondemand
GPU_GOVERNOR=performance
for dev in /sys/class/devfreq/*; do
  GOV_FILE="$dev/governor"
  if [ -w "$GOV_FILE" ]; then
    # Run the entire redirect under root
    su -c "echo $GPU_GOVERNOR > $GOV_FILE"
  fi
done

for entry in \
  "17000010.devfreq_mif                   2288000" \
  "17000020.devfreq_int                   533000"  \
  "17000030.devfreq_intcam                533000"  \
  "17000040.devfreq_disp                  533000"  \
  "17000050.devfreq_cam                   533000"  \
  "17000060.devfreq_tnr                   533000"  \
  "17000070.devfreq_mfc                   664000"  \
  "17000080.devfreq_bw                    310000"  \
  "17000090.devfreq_dsu                   1444000" \
  "170000a0.devfreq_bci                   1050000" \
  "gs_dsulat_devfreq:devfreq_dsulat@17000090 1444000" \
  "gs_memlat_devfreq:devfreq_mif_lat@17000010  2288000" \
; do
  set -- $entry
  DEV_NAME="$1"
  TARGET_HZ="$2"
  DEV_DIR="/sys/class/devfreq/${DEV_NAME}"
  GOV_FILE="$DEV_DIR/governor"
  SCALE_MIN="$DEV_DIR/scaling_devfreq_min"
  MIN_F="$DEV_DIR/min_freq"
  MAX_F="$DEV_DIR/max_freq"

  if [ ! -d "$DEV_DIR" ]; then
    echo "WARNING: devfreq dir '$DEV_DIR' not found—skipping."
    continue
  fi

  if [ -w "$SCALE_MIN" ] && [ -w "$MAX_F" ]; then
    su -c "echo $TARGET_HZ > $SCALE_MIN"
    su -c "echo $TARGET_HZ > $MAX_F"
    su -c "echo $TARGET_HZ > $MIN_F"
  else
    echo "WARNING: Cannot write freq for $DEV_NAME."
  fi
done

# --- optional: show final state ---------------------------------------
echo "--- Result ---"
echo "---- Final CPU frequencies (kHz) ----"
for cpu_id in 0 1 2 3 4 5 6 7 8; do
  cur_file="/sys/devices/system/cpu/cpu${cpu_id}/cpufreq/scaling_cur_freq"
  if [ -r "$cur_file" ]; then
    echo "cpu${cpu_id}: $(cat "$cur_file") kHz"
  fi
done
echo "---- Final GPU frequencies (kHz) ----"
echo
echo "---- Final GPU devfreq frequencies (Hz) ----"
for entry in \
  "17000010.devfreq_mif" \
  "17000020.devfreq_int" \
  "17000030.devfreq_intcam" \
  "17000040.devfreq_disp" \
  "17000050.devfreq_cam" \
  "17000060.devfreq_tnr" \
  "17000070.devfreq_mfc" \
  "17000080.devfreq_bw" \
  "17000090.devfreq_dsu" \
  "170000a0.devfreq_bci" \
  "gs_dsulat_devfreq:devfreq_dsulat@17000090" \
  "gs_memlat_devfreq:devfreq_mif_lat@17000010" \
; do
  cur_file="/sys/class/devfreq/${entry}/cur_freq"
  if [ -r "$cur_file" ]; then
    printf "%s: %s Hz\n" "$entry" "$(cat "$cur_file")"
  fi
done