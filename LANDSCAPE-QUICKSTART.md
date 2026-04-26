# Landscape 集成 - 快速开始

## 🚀 5 分钟快速开始

### 前提条件

- Docker 已安装
- Git 已安装
- 至少 20GB 磁盘空间

### 步骤 1: 克隆项目

```bash
git clone https://github.com/KawaiiNetworks/vyos-unofficial
cd vyos-unofficial
git checkout 6.18-main
```

### 步骤 2: 启动构建

```bash
# 启动构建容器
docker run -it --privileged --sysctl net.ipv6.conf.lo.disable_ipv6=0 \
    -v $(pwd):/vyos -w /vyos vyos/vyos-build:current bash

# 在容器中执行
export PROJECT_ROOT=$(pwd)
bash scripts/build-all.sh
```

### 步骤 3: 获取 ISO

构建完成后：
```bash
ls -lh build/vyos-*.iso
```

### 步骤 4: 安装 VyOS

使用标准方法安装 VyOS（U盘、虚拟机等）。

### 步骤 5: 启用 Landscape

```bash
# SSH 登录到 VyOS
ssh vyos@<vyos-ip>

# 配置
configure
set service landscape enable
commit
save

# 检查状态
sudo systemctl status landscape-router
```

### 步骤 6: 访问 Web UI

打开浏览器访问：
```
https://<vyos-ip>:6443
```

默认用户名/密码: `root/root`

---

## 📦 已集成的功能

### ✅ 已完成

- [x] BPF/BTF 内核支持
- [x] Landscape 软件包 (v0.18.3)
- [x] systemd 服务集成
- [x] VyOS 配置命令
- [x] 自动化构建脚本
- [x] 完整文档

### 📋 文件清单

```
vyos-unofficial/
├── patches/
│   ├── main/
│   │   └── linux-kernel-defconfig.patch      # BPF/BTF 配置
│   ├── vyos-1x/
│   │   └── vyos-1x-007-landscape-integration.patch  # VyOS 配置集成
│   └── vyos-build/
│       └── 0016-add-landscape-package.patch   # 软件包补丁
├── scripts/
│   ├── build-landscape-package.sh             # Landscape 包构建
│   ├── build-all.sh                           # 主构建脚本（已更新）
│   └── patch-and-build-vyos-image.sh          # 镜像构建（已更新）
├── LANDSCAPE-INTEGRATION.md                   # 完整文档
└── LANDSCAPE-QUICKSTART.md                    # 本文件
```

---

## 🧪 测试验证

### 本地测试

```bash
# 在虚拟机中测试
qemu-system-x86_64 -cdrom build/vyos-*.iso -m 4096 -smp 2
```

### GitHub Actions 测试

项目已配置自动构建，推送 tag 即可触发：

```bash
git tag v2024.04.26-landscape
git push origin v2024.04.26-landscape
```

查看构建状态：
https://github.com/KawaiiNetworks/vyos-unofficial/actions

---

## 🔍 验证清单

安装后验证以下项目：

### 1. 内核支持
```bash
uname -r  # 应显示 6.18.x
zgrep CONFIG_BPF /proc/config.gz  # 应显示 =y
ls /sys/kernel/btf/vmlinux  # 应存在
```

### 2. Landscape 服务
```bash
systemctl status landscape-router  # 应为 active (running)
ps aux | grep landscape  # 应看到进程
```

### 3. 端口监听
```bash
sudo ss -tlnp | grep 6443  # 应看到 landscape-webserver
```

### 4. BPF 程序
```bash
sudo bpftool prog list  # 应看到 Landscape 的 BPF 程序
```

### 5. Web UI
```bash
curl -k https://localhost:6443  # 应返回 HTML
```

---

## 📊 构建时间估算

| 阶段 | 时间 | 说明 |
|------|------|------|
| vyos-1x | 5-10 分钟 | Python 包 |
| 内核 | 30-60 分钟 | 最耗时 |
| 内核相关包 | 10-20 分钟 | 驱动、固件 |
| Landscape 包 | 2-5 分钟 | 下载二进制 |
| VyOS 镜像 | 15-30 分钟 | 打包 ISO |
| **总计** | **1-2 小时** | 取决于硬件 |

---

## 🐛 常见问题

### 构建失败

**问题**: 内核构建失败
```bash
# 解决: 清理后重试
rm -rf vyos-build/scripts/package-build/linux-kernel
bash scripts/patch-and-build-kernel.sh
```

**问题**: Landscape 下载失败
```bash
# 解决: 手动下载后放置
mkdir -p packages
# 下载 landscape-router_0.18.3_amd64.deb 到 packages/
```

### 运行时问题

**问题**: 服务无法启动
```bash
# 检查日志
sudo journalctl -u landscape-router -n 50

# 检查配置目录
ls -la /config/landscape
```

**问题**: Web UI 无法访问
```bash
# 检查防火墙
sudo nft list ruleset | grep 6443

# 临时测试
curl -k https://localhost:6443
```

---

## 📚 下一步

1. **阅读完整文档**: [LANDSCAPE-INTEGRATION.md](LANDSCAPE-INTEGRATION.md)
2. **配置流量分流**: 访问 Web UI 配置规则
3. **集成 Docker**: 如需容器导流功能
4. **性能调优**: 根据实际负载优化

---

## 🤝 获取帮助

- **Landscape 文档**: https://landscape.whileaway.dev/
- **提交 Issue**: https://github.com/KawaiiNetworks/vyos-unofficial/issues
- **测试仓库**: https://github.com/kos991/vyos-add-l

---

## ⚡ 使用 GitHub Actions 自动构建

### 方法 1: Fork 后自动构建

1. Fork 本项目到你的 GitHub
2. 创建并推送 tag:
   ```bash
   git tag v2024.04.26-test
   git push origin v2024.04.26-test
   ```
3. 在 Actions 页面查看构建进度
4. 构建完成后从 Releases 下载 ISO

### 方法 2: 手动触发构建

1. 进入 Actions 页面
2. 选择 "Build and Release VyOS" workflow
3. 点击 "Run workflow"
4. 选择分支或 tag
5. 点击 "Run workflow" 开始构建

---

## 🎯 测试验证仓库

使用专门的测试仓库进行验证：

```bash
git clone https://github.com/kos991/vyos-add-l.git
cd vyos-add-l

# 查看集成状态
git log --oneline | head -10

# 触发构建测试
git tag test-$(date +%Y%m%d-%H%M)
git push origin --tags
```

---

## ✨ 特性亮点

### 🔥 eBPF 高性能
- 内核空间处理，零拷贝
- 直连流量几乎无性能损失
- 支持 XDP 极速数据路径

### 🎨 友好的 Web UI
- 现代化界面设计
- 实时流量监控
- 可视化规则配置

### 🔧 灵活的配置
- 支持 VyOS 命令行配置
- 支持 Web UI 配置
- 支持 REST API 自动化

### 🐳 容器化扩展
- 流量导入 Docker 容器
- 支持 TProxy 透明代理
- 灵活的扩展能力

---

**开始你的 Landscape 之旅吧！** 🚀
