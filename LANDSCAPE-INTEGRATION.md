# Landscape 集成到 VyOS - 安装和使用指南

## 概述

本项目已将 Landscape eBPF 路由平台集成到 VyOS 中，作为可选软件包提供。

### 什么是 Landscape？

Landscape 是一个基于 eBPF 的 Linux 路由平台，提供：
- eBPF 流量分流（基于 IP、MAC、域名、Geo）
- 每流独立 DNS 配置和缓存
- 流量导入 Docker 容器（支持 TProxy）
- 细粒度 NAT 控制（NAT1/NAT4）
- Web UI + REST API 管理

### 系统要求

- ✅ Linux 内核 6.9+ (当前 VyOS 使用 6.18.20)
- ✅ BTF/BPF 支持已启用
- ✅ Root 权限
- ⚠️ Docker (可选，用于容器导流功能)

---

## 构建集成了 Landscape 的 VyOS

### 方法 1: 本地构建

```bash
# 1. 克隆项目
git clone https://github.com/KawaiiNetworks/vyos-unofficial
cd vyos-unofficial
git checkout 6.18-main

# 2. 启动构建容器
docker run -it --privileged --sysctl net.ipv6.conf.lo.disable_ipv6=0 \
    -v $(pwd):/vyos -w /vyos vyos/vyos-build:current bash

# 3. 在容器中构建
export PROJECT_ROOT=$(pwd)
bash scripts/build-all.sh
```

构建完成后，ISO 文件位于 `build/vyos-*.iso`

### 方法 2: GitHub Actions 自动构建

项目已配置 GitHub Actions，推送 tag 时自动构建：

```bash
git tag v2024.04.26-landscape
git push origin v2024.04.26-landscape
```

构建完成后，从 Releases 页面下载 ISO。

---

## 安装 Landscape

### 在已有 VyOS 系统上安装

如果你已经有运行中的 VyOS 系统，可以手动安装 Landscape：

```bash
# 1. 下载 Landscape 包（从构建产物或手动构建）
# landscape-router_0.18.3_amd64.deb

# 2. 安装包
sudo dpkg -i landscape-router_0.18.3_amd64.deb

# 3. 启用服务
sudo systemctl enable --now landscape-router

# 4. 检查状态
sudo systemctl status landscape-router
```

### 使用集成了 Landscape 的 ISO

直接使用构建的 ISO 安装 VyOS，Landscape 已预装。

---

## 配置 Landscape

### 方法 1: 使用 VyOS 配置命令（推荐）

```bash
# 进入配置模式
configure

# 启用 Landscape
set service landscape enable

# 配置端口（可选，使用默认值）
set service landscape http-port 6300
set service landscape https-port 6443

# 配置目录（可选）
set service landscape config-dir /config/landscape

# 提交并保存
commit
save
```

### 方法 2: 直接使用 systemd

```bash
# 启用服务
sudo systemctl enable landscape-router

# 启动服务
sudo systemctl start landscape-router

# 查看状态
sudo systemctl status landscape-router

# 查看日志
sudo journalctl -u landscape-router -f
```

---

## 访问 Web UI

### 默认访问地址

- HTTP (自动跳转): `http://<vyos-ip>:6300`
- HTTPS: `https://<vyos-ip>:6443`

### 默认凭据

- 用户名: `root`
- 密码: `root`

**⚠️ 首次登录后请立即修改密码！**

### 通过主机名访问

如果配置了 mDNS/Avahi：
```
https://vyos.local:6443
```

---

## 配置示例

### 基础配置

```bash
configure

# 启用 Landscape
set service landscape enable

# 配置网络接口（如果还没配置）
set interfaces ethernet eth0 address dhcp
set interfaces ethernet eth1 address 192.168.1.1/24

commit
save
```

### 与 VyOS 防火墙协同

Landscape 使用 eBPF 进行流量处理，可以与 VyOS 的 nftables 防火墙协同工作：

**推荐模式**: 
- VyOS 处理基础防火墙规则
- Landscape 处理流量分流和 NAT

```bash
# VyOS 防火墙配置
set firewall name WAN_LOCAL default-action drop
set firewall name WAN_LOCAL rule 10 action accept
set firewall name WAN_LOCAL rule 10 state established enable
set firewall name WAN_LOCAL rule 10 state related enable

# 允许访问 Landscape Web UI（从 LAN）
set firewall name LAN_LOCAL rule 100 action accept
set firewall name LAN_LOCAL rule 100 destination port 6443
set firewall name LAN_LOCAL rule 100 protocol tcp
```

### 启用 Docker 支持（可选）

如果需要使用 Landscape 的容器导流功能：

```bash
# 安装 Docker
sudo apt update
sudo apt install docker.io

# 启动 Docker
sudo systemctl enable --now docker

# 重启 Landscape
sudo systemctl restart landscape-router
```

---

## 验证安装

### 检查服务状态

```bash
# 检查 Landscape 服务
sudo systemctl status landscape-router

# 检查进程
ps aux | grep landscape

# 检查端口监听
sudo ss -tlnp | grep -E '6300|6443'
```

### 检查 BPF 程序

```bash
# 查看加载的 BPF 程序
sudo bpftool prog list

# 查看 BPF maps
sudo bpftool map list

# 检查 BTF 信息
ls -lh /sys/kernel/btf/vmlinux
```

### 测试 Web UI 访问

```bash
# 测试 HTTP 跳转
curl -I http://localhost:6300

# 测试 HTTPS（忽略证书）
curl -k https://localhost:6443
```

---

## 故障排查

### 服务无法启动

```bash
# 查看详细日志
sudo journalctl -u landscape-router -n 100 --no-pager

# 检查配置目录权限
ls -la /config/landscape

# 手动运行测试
sudo /opt/vyos/landscape/landscape-webserver --help
```

### BPF 功能不可用

```bash
# 检查内核版本
uname -r  # 应该 >= 6.9

# 检查 BPF 配置
zgrep CONFIG_BPF /proc/config.gz

# 检查 BTF 支持
zgrep CONFIG_DEBUG_INFO_BTF /proc/config.gz
```

### Web UI 无法访问

```bash
# 检查防火墙规则
sudo nft list ruleset | grep -E '6300|6443'

# 检查端口占用
sudo ss -tlnp | grep -E '6300|6443'

# 临时禁用防火墙测试
sudo nft flush ruleset  # 谨慎使用！
```

### 与 VyOS 功能冲突

如果 Landscape 与 VyOS 的 NAT/防火墙冲突：

**选项 1**: 禁用 VyOS NAT，使用 Landscape
```bash
delete nat
commit
```

**选项 2**: 禁用 Landscape，使用 VyOS
```bash
delete service landscape
commit
```

**选项 3**: 分层使用（高级）
- VyOS 处理基础路由和防火墙
- Landscape 仅处理特定流量分流

---

## 升级 Landscape

### 升级到新版本

```bash
# 1. 下载新版本的 deb 包
# landscape-router_0.19.0_amd64.deb

# 2. 停止服务
sudo systemctl stop landscape-router

# 3. 安装新版本
sudo dpkg -i landscape-router_0.19.0_amd64.deb

# 4. 启动服务
sudo systemctl start landscape-router

# 5. 检查版本
/opt/vyos/landscape/landscape-webserver --version
```

### 配置迁移

Landscape 会自动迁移配置文件，无需手动操作。

---

## 卸载 Landscape

### 完全卸载

```bash
# 1. 停止并禁用服务
sudo systemctl stop landscape-router
sudo systemctl disable landscape-router

# 2. 卸载包
sudo apt remove landscape-router

# 3. 删除配置（可选）
sudo rm -rf /config/landscape

# 4. 删除 VyOS 配置
configure
delete service landscape
commit
save
```

### 保留配置卸载

```bash
# 仅卸载包，保留配置
sudo apt remove landscape-router

# 配置保留在 /config/landscape
```

---

## 性能优化

### 调整系统限制

```bash
# 增加文件描述符限制
echo "* soft nofile 1048576" >> /etc/security/limits.conf
echo "* hard nofile 1048576" >> /etc/security/limits.conf

# 增加内存锁定限制（BPF 需要）
echo "* soft memlock unlimited" >> /etc/security/limits.conf
echo "* hard memlock unlimited" >> /etc/security/limits.conf
```

### 优化 eBPF

```bash
# 增加 BPF JIT 编译器限制
sysctl -w net.core.bpf_jit_limit=1000000000

# 持久化
echo "net.core.bpf_jit_limit=1000000000" >> /etc/sysctl.conf
```

---

## 安全建议

### 1. 修改默认密码

首次登录后立即在 Web UI 中修改密码。

### 2. 限制 Web UI 访问

```bash
# 仅允许从 LAN 访问
set firewall name WAN_LOCAL rule 200 action drop
set firewall name WAN_LOCAL rule 200 destination port 6443
set firewall name WAN_LOCAL rule 200 protocol tcp
```

### 3. 使用 HTTPS

Landscape 默认使用自签名证书，建议配置有效证书：

```bash
# 将证书放置在配置目录
/config/landscape/cert.pem
/config/landscape/key.pem
```

### 4. 定期更新

定期检查并更新到最新版本以获取安全修复。

---

## 参考资源

- **Landscape 官方文档**: https://landscape.whileaway.dev/
- **Landscape GitHub**: https://github.com/ThisSeanZhang/landscape
- **VyOS 文档**: https://docs.vyos.io/
- **本项目 GitHub**: https://github.com/KawaiiNetworks/vyos-unofficial

---

## 常见问题 (FAQ)

### Q: Landscape 会替代 VyOS 的路由功能吗？

A: 不会。Landscape 作为可选组件，与 VyOS 协同工作。你可以选择使用 VyOS 的传统路由功能，或使用 Landscape 的 eBPF 分流功能，或两者结合。

### Q: 需要 Docker 吗？

A: Docker 是可选的。仅当你需要使用容器导流功能时才需要安装 Docker。

### Q: 性能影响如何？

A: Landscape 使用 eBPF 在内核空间处理流量，性能开销极小。直连流量几乎不受影响。

### Q: 可以在生产环境使用吗？

A: Landscape 和本集成都处于活跃开发中。建议先在测试环境充分验证后再用于生产。

### Q: 如何获取支持？

A: 
- Landscape 相关问题: https://github.com/ThisSeanZhang/landscape/issues
- VyOS 集成问题: https://github.com/KawaiiNetworks/vyos-unofficial/issues

---

## 更新日志

### v0.18.3 (2024-04-26)
- ✅ 首次集成 Landscape 到 VyOS
- ✅ 启用 BPF/BTF 内核支持
- ✅ 创建独立软件包
- ✅ VyOS 配置集成
- ✅ systemd 服务管理

---

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

- Landscape: GPLv2 (eBPF) + GPLv3 (其他)
- VyOS: GPLv3
- 本集成: GPLv3
