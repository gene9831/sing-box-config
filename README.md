# PVE Alpine + sing-box 搭建 Linux 网关

## PVE 安装 Alpine LXC 容器

1. PVE CT 模板中搜索 Alpine，然后下载最新版 Alpine
   ![pve搜索alpine](https://github.com/user-attachments/assets/64f18980-9632-4640-bf2d-7509daca14a3)

2. 创建 LXC 容器时，参数按自己需求填写
3. LXC 容器开启 TUN/TAP，编辑 `/etc/pve/lxc/<container-id>.conf`，底部添加

   ```shell
   lxc.cgroup.devices.allow: c 10:200 rwm
   lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file
   ```

## 初次安装 Alpine 后配置

初次安装 Alpine 默认没有 ssh 服务，先通过 pve 控制台进入 Alpine

### 软件源

软件源替换清华源

```shell
# 备份
cp /etc/apk/repositories /etc/apk/repositories.bak
# 替换
sed -i 's#https\?://dl-cdn.alpinelinux.org/alpine#https://mirrors.tuna.tsinghua.edu.cn/alpine#g' /etc/apk/repositories
```

更新软件

```shell
apk update && apk upgrade
```

### ssh

安装 ssh 服务

```shell
apk add openssh-server
# 启动服务
rc-service sshd start
# 设置开机启动
rc-update add sshd
```

安装 nano 编辑器

```shell
apk add nano
```

ssh 服务开放 root 登录

```shell
nano /etc/ssh/sshd_config
```

添加下面配置，然后保存

```shell
PermitRootLogin yes
```

重启 sshd

```shell
rc-service sshd restart
```

### sing-box

通过 edge/testing 源安装 sing-box

```shell
apk add sing-box -X https://mirrors.tuna.tsinghua.edu.cn/alpine/edge/testing
```

编辑配置，具体配置请参考 [configs](./configs)

```shell
nano /etc/sing-box/config.json
```

```shell
# 启动服务
rc-service sing-box start
# 服务开机自启
rc-update add sing-box
```

通过服务启动的 sing-box，默认工作目录在 `/var/lib/sing-box`

检测是否生效，访问 google，返回 200 表示启动成功

```shell
apk add curl
curl -I https://www.google.com
```

### 网关配置

启用 IP 转发

编辑 `/etc/sysctl.conf` 文件，确保以下行已启用

```shell
net.ipv4.ip_forward=1
```

然后应用更改

```shell
sysctl -p
```

安装 iptables

```shell
apk add iptables
```

```shell
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i eth0 -o tun0 -j ACCEPT
iptables -A FORWARD -i tun0 -o eth0 -j ACCEPT
# 保存
rc-service iptables save
# 查看已保存的 iptables
cat /etc/iptables/rules-save
```

### 终端设备配置

配置网关和 dns 为 alpine 的地址即可
