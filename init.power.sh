#!/system/bin/sh

################################################################################
# helper functions to allow Android init like script

function write() {
    echo -n $2 > $1
}

function copy() {
    cat $1 > $2
}

################################################################################

# disable thermal hotplug to switch governor
write /sys/module/msm_thermal/core_control/enabled 0

# bring back main cores CPU 0,2
write /sys/devices/system/cpu/cpu0/online 1
write /sys/devices/system/cpu/cpu2/online 1

write /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor cultivation
restorecon -R /sys/devices/system/cpu # must restore after interactive
write /sys/devices/system/cpu/cpu0/cpufreq/cultivation/above_hispeed_delay 20000
write /sys/devices/system/cpu/cpu0/cpufreq/cultivation/fastlane 0
write /sys/devices/system/cpu/cpu0/cpufreq/cultivation/go_hispeed_load 99
write /sys/devices/system/cpu/cpu0/cpufreq/cultivation/go_lowspeed_load 10
write /sys/devices/system/cpu/cpu0/cpufreq/cultivation/hispeed_freq 1593600
write /sys/devices/system/cpu/cpu0/cpufreq/cultivation/io_is_busy 0
write /sys/devices/system/cpu/cpu0/cpufreq/cultivation/max_freq_hysteresis 80000
write /sys/devices/system/cpu/cpu0/cpufreq/cultivation/min_sample_time 40000
write /sys/devices/system/cpu/cpu0/cpufreq/cultivation/powersave_bias 1
write /sys/devices/system/cpu/cpu0/cpufreq/cultivation/target_loads 90
write /sys/devices/system/cpu/cpu0/cpufreq/cultivation/timer_rate 20000
write /sys/devices/system/cpu/cpu0/cpufreq/cultivation/timer_rate_screenoff 50000
write /sys/devices/system/cpu/cpu0/cpufreq/cultivation/timer_slack 80000

# EAS: Capping the max frequency of silver core to 1.6GHz
write /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 1593600

write /sys/devices/system/cpu/cpu2/cpufreq/scaling_governor cultivation
restorecon -R /sys/devices/system/cpu
write /sys/devices/system/cpu/cpu2/cpufreq/cultivation/above_hispeed_delay 20000
write /sys/devices/system/cpu/cpu2/cpufreq/cultivation/fastlane 0
write /sys/devices/system/cpu/cpu2/cpufreq/cultivation/go_hispeed_load 99
write /sys/devices/system/cpu/cpu2/cpufreq/cultivation/go_lowspeed_load 10
write /sys/devices/system/cpu/cpu2/cpufreq/cultivation/hispeed_freq 2150000
write /sys/devices/system/cpu/cpu2/cpufreq/cultivation/io_is_busy 0
write /sys/devices/system/cpu/cpu2/cpufreq/cultivation/max_freq_hysteresis 80000
write /sys/devices/system/cpu/cpu2/cpufreq/cultivation/min_sample_time 40000
write /sys/devices/system/cpu/cpu2/cpufreq/cultivation/powersave_bias 1
write /sys/devices/system/cpu/cpu2/cpufreq/cultivation/target_loads 90
write /sys/devices/system/cpu/cpu2/cpufreq/cultivation/timer_rate 20000
write /sys/devices/system/cpu/cpu2/cpufreq/cultivation/timer_rate_screenoff 50000
write /sys/devices/system/cpu/cpu2/cpufreq/cultivation/timer_slack 800000

# if EAS is present, switch to sched governor (no effect if not EAS)
write /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor "sched"
write /sys/devices/system/cpu/cpu2/cpufreq/scaling_governor "sched"

# re-enable thermal hotplug
write /sys/module/msm_thermal/core_control/enabled 1

# input boost configuration
write /sys/module/cpu_boost/parameters/input_boost_freq "0:1324800 2:1324800"
write /sys/module/cpu_boost/parameters/input_boost_ms 40

# Setting b.L scheduler parameters
write /proc/sys/kernel/sched_boost 0
write /proc/sys/kernel/sched_migration_fixup 1
write /proc/sys/kernel/sched_upmigrate 95
write /proc/sys/kernel/sched_downmigrate 90
write /proc/sys/kernel/sched_freq_inc_notify 400000
write /proc/sys/kernel/sched_freq_dec_notify 400000
write /proc/sys/kernel/sched_spill_nr_run 3
write /proc/sys/kernel/sched_init_task_load 100

# Enable bus-dcvs
for cpubw in /sys/class/devfreq/*qcom,cpubw* ; do
    write $cpubw/governor "bw_hwmon"
    write $cpubw/polling_interval 50
    write $cpubw/min_freq 1525
    write $cpubw/bw_hwmon/mbps_zones "1525 5195 11863 13763"
    write $cpubw/bw_hwmon/sample_ms 4
    write $cpubw/bw_hwmon/io_percent 34
    write $cpubw/bw_hwmon/hist_memory 20
    write $cpubw/bw_hwmon/hyst_length 10
    write $cpubw/bw_hwmon/low_power_ceil_mbps 0
    write $cpubw/bw_hwmon/low_power_io_percent 34
    write $cpubw/bw_hwmon/low_power_delay 20
    write $cpubw/bw_hwmon/guard_band_mbps 0
    write $cpubw/bw_hwmon/up_scale 250
    write $cpubw/bw_hwmon/idle_mbps 1600
done

for memlat in /sys/class/devfreq/*qcom,memlat-cpu* ; do
    write $memlat/governor "mem_latency"
    write $memlat/polling_interval 10
done

# Enable all LPMs by default
# This will enable C4, D4, D3, E4 and M3 LPMs
write /sys/module/lpm_levels/parameters/sleep_disabled N

# On debuggable builds, enable console_suspend if uart is enabled to save power
# Otherwise, disable console_suspend to get better logging for kernel crashes
if [[ $(getprop ro.debuggable) == "1" && ! -e /sys/class/tty/ttyHSL0 ]]
then
    write /sys/module/printk/parameters/console_suspend N
fi

write /sys/class/kgsl/kgsl-3d0/default_pwrlevel 6
