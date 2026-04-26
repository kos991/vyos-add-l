# Landscape 集成到 VyOS 的可行性分析

## 项目概述

### Landscape 简介
- **定位**: 基于 eBPF 的 Linux 路由平台
- **技术栈**: Rust + eBPF + AF_PACKET
- **核心功能**:
  - eBPF 流量分流（基于 SIP-CIDR、MAC、DIP、域名、Geo）
  - 每流独立 DNS 配置和缓存
  - 流量导入 Docker 容器（支持 TProxy）
  - 细粒度 NAT 控制（NAT1/NAT4）
  - Web UI + REST API 管理
- **许可证**: GPLv2 (ebpf) + GPLv3 (其他)

### VyOS 当前状态
- **内核版本**: 6.18.20
- **架构**: amd64 (x86_64)
- **BPF/BTF 支持**: ✅ 已启用（刚完成配置）
- **基础系统**: Debian-based
- **配置方式**: 命令行配置树 (vyos-1x)

---

## 集成可行性评估

### ✅ 技术兼容性 - 高度可行

#### 1. 内核要求
| 要求 | VyOS 状态 | 评估 |
|------|-----------|------|
| Linux 6.9+ | 6.18.20 | ⚠️ **需要升级内核** |
| BTF/BPF 支持 | ✅ 已启用 | ✅ 满足 |
| Root 权限 | ✅ 可用 | ✅ 满足 |
| Docker (可选) | ❓ 需确认 | ⚠️ 可能需要添加 |

**关键问题**: Landscape 要求内核 6.9+，而 VyOS 当前使用 6.18.20
- **解决方案**: 升级到 6.9+ LTS 内核（如 6.12 LTS）

#### 2. 架构兼容性
- Landscape 支持 x86_64 ✅
- VyOS 目标架构 amd64 ✅
- 二进制分发可直接使用 ✅

#### 3. 依赖项
```
必需:
- glibc (Debian 自带)
- systemd (VyOS 使用)
- eBPF 工具链 (已通过 BPF/BTF 配置启用)

可选:
- Docker (用于容器导流功能)
- pahole (BTF 生成，构建时需要)
```

---

## 集成方案设计

### 方案 A: 作为独立软件包集成 (推荐)

#### 优点
- ✅ 不侵入 VyOS 核心系统
- ✅ 可独立升级和维护
- ✅ 用户可选择是否安装
- ✅ 保持 Landscape 原有功能完整性

#### 实现步骤

**1. 创建 Landscape 软件包**
```bash
patches/vyos-build/0016-add-landscape-package.patch
```

内容包括:
- 下载 landscape-webserver 二进制
- 下载 static.zip 前端资源
- 创建 systemd 服务文件
- 配置默认目录 `/opt/vyos/landscape`

**2. 修改构建脚本**
```bash
scripts/patch-and-build-vyos-image.sh
```

添加:
```bash
--custom-package landscape-router \
```

**3. 创建 VyOS 配置集成**
```bash
patches/vyos-1x/vyos-1x-007-landscape-integration.patch
```

添加配置节点:
```
set service landscape enable
set service landscape http-port 6300
set service landscape https-port 6443
set service landscape config-dir /opt/vyos/landscape
```

**4. 内核升级**
```bash
# 更新 build.conf
kernel_version=6.12.10  # 或其他 6.9+ 版本
```

#### 目录结构
```
/opt/vyos/landscape/
├── landscape-webserver          # 主程序
├── static/                      # Web UI 资源
├── config/                      # 配置文件
│   └── landscape_init.toml
└── data/                        # 运行时数据
```

#### systemd 服务
```ini
[Unit]
Description=Landscape eBPF Router
After=network.target vyos-router.service
Wants=docker.service

[Service]
Type=simple
ExecStart=/opt/vyos/landscape/landscape-webserver \
    --config-dir /opt/vyos/landscape/config \
    --http-port 6300 \
    --https-port 6443
Restart=always
User=root
LimitMEMLOCK=infinity
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
```

---

### 方案 B: 深度集成到 VyOS 配置系统

#### 优点
- ✅ 统一的 VyOS 配置体验
- ✅ 配置持久化和版本控制
- ✅ 与 VyOS 其他功能协同

#### 缺点
- ❌ 开发工作量大
- ❌ 需要维护 VyOS 配置到 Landscape API 的映射
- ❌ Landscape 更新时需要同步修改

#### 实现复杂度
- 需要编写 Python 配置模板
- 需要通过 Landscape REST API 进行配置
- 需要处理配置冲突和同步

**评估**: 不推荐，除非有长期维护计划

---

## 功能冲突分析

### 潜在冲突点

| 功能 | VyOS | Landscape | 冲突程度 | 解决方案 |
|------|------|-----------|----------|----------|
| 防火墙/NAT | nftables | eBPF | 🔴 高 | 二选一或分层使用 |
| DNS | dnsmasq | 内置 DNS | 🟡 中 | 可共存，不同端口 |
| DHCP | ISC DHCP | 无 | 🟢 低 | 无冲突 |
| 路由 | FRR/静态 | eBPF 分流 | 🟡 中 | 协同工作 |
| 流量整形 | tc | eBPF | 🟡 中 | 可共存 |

### 推荐使用模式

**模式 1: Landscape 作为主路由引擎**
- VyOS 提供基础网络配置（接口、VLAN、DHCP）
- Landscape 处理所有路由、NAT、分流
- 适合: 需要复杂分流策略的场景

**模式 2: 混合模式**
- VyOS 处理基础路由和防火墙
- Landscape 仅用于特定流量分流
- 适合: 渐进式迁移

**模式 3: 独立运行**
- Landscape 完全独立运行
- 通过 Web UI 管理
- VyOS 仅作为基础系统
- 适合: 快速部署和测试

---

## 实施路线图

### 阶段 1: 基础集成 (1-2 周)
- [ ] 升级内核到 6.12 LTS
- [ ] 验证 BPF/BTF 功能正常
- [ ] 创建 Landscape 软件包补丁
- [ ] 测试基础安装和运行

### 阶段 2: 系统集成 (1 周)
- [ ] 创建 systemd 服务
- [ ] 添加到 VyOS 构建流程
- [ ] 编写安装和配置文档
- [ ] 测试开机自启动

### 阶段 3: 配置集成 (可选, 2-3 周)
- [ ] 设计 VyOS 配置节点
- [ ] 实现配置模板
- [ ] 集成 REST API 调用
- [ ] 测试配置持久化

### 阶段 4: 优化和文档 (1 周)
- [ ] 性能测试和优化
- [ ] 编写用户文档
- [ ] 创建示例配置
- [ ] 发布集成版本

---

## 风险评估

### 高风险
1. **内核版本升级** (6.18 → 6.12+)
   - 可能引入兼容性问题
   - 需要重新测试所有驱动
   - 缓解: 充分测试，保留回退方案

2. **功能冲突**
   - VyOS 和 Landscape 的 NAT/防火墙冲突
   - 缓解: 明确使用模式，提供配置指南

### 中风险
1. **Docker 依赖**
   - 增加镜像大小
   - 缓解: 作为可选依赖

2. **维护负担**
   - Landscape 更新需要同步
   - 缓解: 自动化构建流程

### 低风险
1. **存储空间**
   - 二进制 + 前端约 50-100MB
   - 缓解: 可接受

---

## 技术债务

### 需要持续维护的部分
1. Landscape 版本跟踪和更新
2. 内核版本兼容性测试
3. 配置迁移脚本（如果深度集成）
4. 文档更新

### 自动化建议
```yaml
# .github/workflows/update-landscape.yml
name: Update Landscape Version
on:
  schedule:
    - cron: '0 0 * * 0'  # 每周检查
  workflow_dispatch:

jobs:
  check-update:
    runs-on: ubuntu-latest
    steps:
      - name: Check latest Landscape release
        # 自动检测新版本并创建 PR
```

---

## 成本效益分析

### 开发成本
- 方案 A (独立包): **2-3 周** 开发时间
- 方案 B (深度集成): **4-6 周** 开发时间

### 收益
- ✅ 现代化的 eBPF 路由能力
- ✅ 灵活的流量分流策略
- ✅ 友好的 Web UI 管理
- ✅ 细粒度 NAT 控制
- ✅ 容器化扩展能力

### 用户价值
- 适合需要复杂分流的家庭/小型企业用户
- 降低配置复杂度
- 提供可视化管理界面

---

## 结论与建议

### 可行性评级: ⭐⭐⭐⭐☆ (4/5)

**推荐方案**: 方案 A - 作为独立软件包集成

**理由**:
1. ✅ 技术上完全可行
2. ✅ 开发成本可控
3. ✅ 维护负担适中
4. ⚠️ 需要升级内核（主要障碍）
5. ✅ 用户价值明确

### 立即可行的步骤
1. **升级内核到 6.12 LTS** - 这是前置条件
2. **创建独立软件包** - 最小化侵入
3. **提供清晰的使用文档** - 说明与 VyOS 的协同方式
4. **保持可选性** - 不强制所有用户使用

### 不建议的做法
- ❌ 深度集成到 VyOS 配置系统（维护成本高）
- ❌ 替换 VyOS 核心路由功能（破坏性太大）
- ❌ 在当前 6.18 内核上强行运行（不满足最低要求）

---

## 下一步行动

如果决定集成，建议按以下顺序执行:

1. **验证内核升级** (优先级: 🔴 最高)
   ```bash
   # 更新 build.conf
   kernel_version=6.12.10
   # 测试构建和启动
   ```

2. **创建 Landscape 包补丁** (优先级: 🟡 高)
   ```bash
   patches/vyos-build/0016-add-landscape-package.patch
   ```

3. **编写集成文档** (优先级: 🟢 中)
   - 安装指南
   - 配置示例
   - 故障排查

4. **社区反馈** (优先级: 🟢 中)
   - 发布测试版本
   - 收集用户反馈
   - 迭代改进
