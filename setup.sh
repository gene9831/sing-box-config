#!/bin/sh
set -e # 脚本遇到错误时立即退出

# 定义变量
REPO_FILE="/etc/apk/repositories"
SSHD_CONFIG="/etc/ssh/sshd_config"
SYSCTL_CONF="/etc/sysctl.d/99-ip-forward.conf"

# 软件源替换清华源
echo "Backing up and updating repositories..."
cp $REPO_FILE $REPO_FILE.bak
sed -i 's#https\?://dl-cdn.alpinelinux.org/alpine#https://mirrors.tuna.tsinghua.edu.cn/alpine#g' $REPO_FILE
apk update && apk upgrade

# 安装并配置 SSH
echo "Installing and configuring SSH..."
apk add openssh-server nano
if ! grep -q "^PermitRootLogin" $SSHD_CONFIG; then
    echo "PermitRootLogin yes" >>$SSHD_CONFIG
fi
if ! rc-service sshd status >/dev/null 2>&1; then
    rc-service sshd start
    rc-update add sshd
fi

# 安装 sing-box
echo "Installing sing-box..."
apk add sing-box -X https://mirrors.tuna.tsinghua.edu.cn/alpine/edge/testing
rc-update add sing-box

# 启用 IP 转发
echo "Enabling IP forwarding..."
echo "net.ipv4.ip_forward=1" >$SYSCTL_CONF
sysctl -p $SYSCTL_CONF
rc-service sysctl start
rc-update add sysctl

# 配置 iptables
echo "Configuring iptables..."
apk add iptables
if ! iptables -t nat -C POSTROUTING -o eth0 -j MASQUERADE 2>/dev/null; then
    iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
fi
if ! iptables -C FORWARD -i eth0 -o tun0 -j ACCEPT 2>/dev/null; then
    iptables -A FORWARD -i eth0 -o tun0 -j ACCEPT
fi
if ! iptables -C FORWARD -i tun0 -o eth0 -j ACCEPT 2>/dev/null; then
    iptables -A FORWARD -i tun0 -o eth0 -j ACCEPT
fi
rc-service iptables save
rc-service iptables start
rc-update add iptables

# 输出提示信息
echo "Configuration completed successfully!"
echo "Run 'nano /etc/sing-box/config.json' to change sing-box config."
echo "Run 'rc-service sing-box start' after sing-box config is changed."
