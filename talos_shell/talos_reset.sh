#!/bin/bash

if [ "$#" -lt 1 ]; then
    echo "使用方法: sh talos_reset ip1 [ip2] [ip3] ..."
    exit 1
fi

for ip_path in "$@"; do
    talosctl -n "${ip_path}" reset --graceful=false --reboot --system-labels-to-wipe=EPHEMERA
    echo "已处理IP地址: ${ip_path}"
done
