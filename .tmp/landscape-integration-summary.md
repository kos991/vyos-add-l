# Landscape 集成 VyOS - 快速评估

## 📊 可行性评分: ⭐⭐⭐⭐☆ (4/5)

---

## ✅ 优势

1. **技术栈完美匹配**
   - Landscape 基于 eBPF/Rust
   - VyOS 已启用 BPF/BTF 支持 ✅
   - 架构兼容 (x86_64) ✅

2. **功能互补**
   - VyOS: 传统路由器功能 (BGP/OSPF/防火墙)
   - Landscape: 现代流量分流 + Web UI
   - 可以协同工作，各司其职

3. **用户价值**
   - 降低配置复杂度
   - 提供可视化管理
   - 细粒度流量控制

---

## ⚠️ 主要障碍

### 🔴 关键问题: 内核版本不匹配

| 项目 | 要求 | 当前 | 状态 |
|------|------|------|------|
| Landscape | Linux 6.9+ | - | 要求 |
| VyOS | - | 6.18.20 | 当前 |

**必须升级内核到 6.9+ (建议 6.12 LTS)**

### 🟡 次要问题

1. **Docker 依赖** (可选功能)
   - 容器导流需要 Docker
   - 解决: 作为可选包

2. **功能冲突**
   - VyOS nftables vs Landscape eBPF
   - 解决: 明确使用模式

---

## 🎯 推荐方案: 独立软件包集成

### 实现方式
```
VyOS 镜像
├── 核心系统 (vyos-1x, FRR, nftables)
└── 可选包: landscape-router
    ├── /opt/vyos/landscape/landscape-webserver
    ├── /opt/vyos/landscape/static/
    └── systemd service
```

### 使用模式
```bash
# 安装后通过 VyOS 命令启用
set service landscape enable
set service landscape https-port 6443
commit
save

# 访问 Web UI
https://router-ip:6443
```

---

## 📋 实施清单

### 阶段 1: 内核升级 (必需)
- [ ] 更新 `build.conf`: `kernel_version=6.12.10`
- [ ] 测试内核构建
- [ ] 验证驱动兼容性
- [ ] 确认 BPF/BTF 功能正常

### 阶段 2: 软件包集成
- [ ] 创建 `patches/vyos-build/0016-add-landscape-package.patch`
- [ ] 下载 landscape-webserver 二进制
- [ ] 打包前端静态资源
- [ ] 创建 systemd 服务文件

### 阶段 3: VyOS 配置集成 (可选)
- [ ] 添加配置节点: `service landscape`
- [ ] 创建启动/停止脚本
- [ ] 集成到 VyOS 配置树

### 阶段 4: 文档和测试
- [ ] 编写安装指南
- [ ] 创建配置示例
- [ ] 性能测试
- [ ] 发布测试版本

---

## ⏱️ 时间估算

| 阶段 | 工作量 | 风险 |
|------|--------|------|
| 内核升级 | 3-5 天 | 🔴 高 |
| 软件包集成 | 5-7 天 | 🟡 中 |
| 配置集成 | 3-5 天 | 🟢 低 |
| 测试文档 | 2-3 天 | 🟢 低 |
| **总计** | **2-3 周** | - |

---

## 💡 关键决策点

### 决策 1: 是否升级内核？
- **YES** → 可以集成 Landscape
- **NO** → 无法集成（硬性要求）

### 决策 2: 集成深度？
- **浅集成** (推荐): 独立软件包，Web UI 管理
  - 优点: 简单、可维护
  - 缺点: 需要单独配置
  
- **深集成**: 完全融入 VyOS 配置系统
  - 优点: 统一体验
  - 缺点: 开发和维护成本高

### 决策 3: Docker 支持？
- **包含**: 支持容器导流功能
  - 成本: +100MB 镜像大小
  
- **不包含**: 仅基础路由功能
  - 成本: 功能受限

---

## 🚀 快速开始 (如果决定集成)

### Step 1: 升级内核
```bash
# 编辑 build.conf
echo "kernel_version=6.12.10" > build.conf

# 重新构建内核
bash scripts/patch-and-build-kernel.sh
```

### Step 2: 添加 Landscape 包
```bash
# 创建补丁文件
cat > patches/vyos-build/0016-add-landscape-package.patch << 'EOF'
# 补丁内容...
EOF

# 更新构建脚本
# 在 scripts/patch-and-build-vyos-image.sh 中添加:
# --custom-package landscape-router \
```

### Step 3: 构建测试
```bash
bash scripts/build-all.sh
```

---

## 📚 参考资源

- Landscape 项目: https://github.com/ThisSeanZhang/landscape
- Landscape 文档: https://landscape.whileaway.dev/
- VyOS 构建文档: https://docs.vyos.io/en/latest/contributing/build-vyos.html
- Linux 6.12 LTS: https://kernel.org/

---

## 🎓 结论

**Landscape 集成到 VyOS 在技术上完全可行**，主要工作是：

1. ✅ 内核升级 (6.18 → 6.12+) - **必需**
2. ✅ 创建软件包 - **简单**
3. ✅ 编写文档 - **必需**

**建议**: 先升级内核并验证，然后再决定是否继续集成 Landscape。

**风险**: 内核升级可能影响现有驱动和功能，需要充分测试。

**收益**: 获得现代化的 eBPF 路由能力和友好的 Web 管理界面。
