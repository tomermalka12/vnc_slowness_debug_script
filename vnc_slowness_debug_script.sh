#!/bin/bash
###### Start Safe Header ######
# Developed by: Tomer Malka Pinto
# Purpose: This script is used to debug VNC slowness issues on a Linux system.
# Date: 26/10/2026
# Version: 1.0.0
###### End Safe Header ########

CPU_USAGE_THRESHOLD=80
MEMORY_USAGE_THRESHOLD=80
PING_THRESHOLD=100
DISK_USAGE_THRESHOLD=85

# Function to check CPU usage
check_cpu_usage() {
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
    if (( $(echo "$CPU_USAGE > $CPU_USAGE_THRESHOLD" | bc -l) )); then
        echo "High CPU usage detected: $CPU_USAGE%"
    else
        echo "CPU usage is normal: $CPU_USAGE%"
    fi
}

# Function to check memory usage
check_memory_usage() {
    MEMORY_USAGE=$(free | grep Mem | awk '{print $3/$2 * 100}')
    if (( $(echo "$MEMORY_USAGE > $MEMORY_USAGE_THRESHOLD" | bc -l) )); then
        echo "High memory usage detected: $MEMORY_USAGE%"
    else
        echo "Memory usage is normal: $MEMORY_USAGE%"
    fi
}  

# Function for terminating unused processes
terminate_unused_processes() {
    UNUSED_PROCESSES=$(ps -eo pid,etime,cmd --sort=etime | awk '$2 ~ /[0-9]+-[0-9]+:[0-9]+/ {print $1}')
    for PID in $UNUSED_PROCESSES; do
        kill -9 $PID
        echo "Terminated unused process with PID: $PID"
    done
}

# Function to check VNC server status
check_vnc_status() {
    VNC_STATUS=$(systemctl is-active vncserver)
    if [ "$VNC_STATUS" != "active" ]; then
        echo "VNC server is not running. Current status: $VNC_STATUS"
    else
        echo "VNC server is running."
    fi
}   

# Function to check network latency
check_network_latency() {
    PING_RESULT=$(ping -c 4 google.com | tail -1 | awk '{print $4}' | cut -d '/' -f 2)
    if (( $(echo "$PING_RESULT > $PING_THRESHOLD" | bc -l) )); then
        echo "High network latency detected: $PING_RESULT ms"
    else
        echo "Network latency is normal: $PING_RESULT ms"
    fi
}

# Function to check disk I/O
check_disk_io() {
    DISK_IO=$(iostat -dx | awk 'NR>3 {print $1, $14}' | sort -k2 -nr | head -n 1)
    echo "Disk I/O status: $DISK_IO"
} 

# Function to check for disk space issues
check_disk_space() {
    DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    if (( DISK_USAGE > $DISK_USAGE_THRESHOLD )); then
        echo "High disk usage detected: $DISK_USAGE%"
    else
        echo "Disk usage is normal: $DISK_USAGE%"
    fi
}

# Function to delete old VNC log files
delete_old_vnc_logs() {
    LOG_DIR="/var/log/vnc"
    echo "are you sure you want to delete VNC log files older than 100 days? (y/n)"
    read -r CONFIRMATION
    if [ "$CONFIRMATION" != "y" ]; then
        echo "Aborting deletion of old VNC log files."
        return
    fi
    if [ -d "$LOG_DIR" ]; then
        find "$LOG_DIR" -type f -name "*.log" -mtime +100 -delete
        echo "Deleted old VNC log files older than 100 days."
    fi
}

# Function to delete logs that are more then 1GB
delete_large_logs() {
    LOG_DIR="/var/log"
    echo "are you sure you want to delete log files larger than 1GB? (y/n)"
    read -r CONFIRMATION
    if [ "$CONFIRMATION" != "y" ]; then
        echo "Aborting deletion of large log files."
        return
    fi
    find "$LOG_DIR" -type f -size +1G -delete
    echo "Deleted log files larger than 1GB."
}   

# Function to check for any other potential issues
check_other_issues() {
    # Placeholder for additional checks (e.g., logs, processes)
    echo "Checking for other potential issues..."
    # Example: Check for high load average
    LOAD_AVERAGE=$(uptime | awk -F'load average:' '{ print $2 }' | cut -d, -f1)
    if (( $(echo "$LOAD_AVERAGE > 2.0" | bc -l) )); then
        echo "High load average detected: $LOAD_AVERAGE"
    else
        echo "Load average is normal: $LOAD_AVERAGE"
    fi
}

# Function to show the status of VNC server recources after the checks
check_vnc_resources() {
    VNC_CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
    echo "VNC server cpu resource usage:"
    echo "$VNC_CPU_USAGE"
    VNC_MEMORY_USAGE=$(free | grep Mem | awk '{print $3/$2 * 100}')
    echo "VNC server memory resource usage:"
    echo "$VNC_MEMORY_USAGE"
    VNC_DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    echo "VNC server disk resource usage:"
    echo "$VNC_DISK_USAGE"
    VNC_DISK_IO=$(iostat -dx | awk 'NR>3 {print $1, $14}' | sort -k2 -nr | head -n 1)
    echo "VNC server disk I/O status:"
    echo "$VNC_DISK_IO"
}

# Main script execution
echo "Starting VNC slowness debug script..."
check_cpu_usage
check_memory_usage
check_other_issues
check_vnc_status
check_network_latency
check_disk_io
check_disk_space
delete_old_vnc_logs
delete_large_logs

echo "VNC server resource usage after checks:"
check_vnc_resources
echo "VNC slowness debug script completed."
echo "Please review the above output, if the issue persists, please try to reboot the VM and check if the issue still exists. If the issue persists, please try to teminate the VM and create a new one. If the issue still persists, please contact support for further assistance."

