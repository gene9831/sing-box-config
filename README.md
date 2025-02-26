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

> 如果你不想一步一步操作，可以直接复制 setup.sh 内容。然后执行
>
> ```shell
> vi setup.sh
> # 按下 i 键进入编辑模式
> i
> # 然后粘贴 setup.sh 内容
> # 保存
> :wq
> chomod +x ./setup.sh
> ./setup.sh
> ```

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

启动 ssh 服务

```shell

# 启动服务
rc-service sshd start
# 设置开机启动
rc-update add sshd
```

### sing-box

现在可以通过 ssh 客户端来配置了。通过 edge/testing 源安装 sing-box

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

编辑 `/etc/sysctl.d/99-ip-forward.conf` 文件，添加下面配置

```shell
net.ipv4.ip_forward=1
```

然后应用更改

```shell
# 应用更改
sysctl -p /etc/sysctl.d/99-ip-forward.conf
# 检查是否生效
sysctl net.ipv4.ip_forward
```

sysctl 服务开机自启动

```shell
rc-service sysctl start
rc-update add sysctl
```

iptables 配置

运行命令添加配置

```shell
apk add iptables
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i eth0 -o tun0 -j ACCEPT
iptables -A FORWARD -i tun0 -o eth0 -j ACCEPT
# 保存
rc-service iptables save
# 查看已保存的 iptables
cat /etc/iptables/rules-save
# 启动服务并添加开机启动项
rc-service iptables start
rc-update add iptables
```

### 终端设备配置

终端设备配置网关和 dns 为 alpine 的 ip 地址即可
