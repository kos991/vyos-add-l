# BPF/BTF Kernel Configuration Implementation

## 修改日期
2026-04-26

## 修改内容

### 1. 更新的文件
- `patches/main/linux-kernel-defconfig.patch` - 添加了新的 BPF/BTF 配置段

### 2. 新增配置文件
通过补丁创建 `scripts/package-build/linux-kernel/config/00-bpf-btf.config`

### 3. 启用的功能

#### 核心 BPF 支持
- `CONFIG_BPF=y` - 启用 BPF 子系统
- `CONFIG_BPF_SYSCALL=y` - 启用 bpf() 系统调用
- `CONFIG_BPF_JIT=y` - 启用 BPF JIT 编译器
- `CONFIG_BPF_JIT_ALWAYS_ON=y` - 强制 JIT 编译（安全性）
- `CONFIG_BPF_JIT_DEFAULT_ON=y` - 默认启用 JIT

#### BTF (BPF Type Format) 支持
- `CONFIG_DEBUG_INFO_BTF=y` - 生成 BTF 调试信息
- `CONFIG_DEBUG_INFO_BTF_MODULES=y` - 为内核模块生成 BTF
- `CONFIG_PAHOLE_HAS_SPLIT_BTF=y` - 分离 BTF 支持

#### BPF 程序类型
- `CONFIG_BPF_EVENTS=y` - 支持 kprobes、tracepoints 等
- `CONFIG_BPF_KPROBE_OVERRIDE=y` - 允许 BPF 覆盖 kprobes
- `CONFIG_BPF_STREAM_PARSER=y` - BPF 流解析器

#### 网络 BPF
- `CONFIG_NET_CLS_BPF=m` - 基于 BPF 的数据包分类
- `CONFIG_NET_ACT_BPF=m` - 基于 BPF 的数据包动作
- `CONFIG_LWTUNNEL_BPF=y` - 轻量级隧道 BPF 支持
- `CONFIG_NETFILTER_XT_MATCH_BPF=m` - iptables BPF 匹配

#### XDP (eXpress Data Path)
- `CONFIG_XDP_SOCKETS=y` - AF_XDP 套接字
- `CONFIG_XDP_SOCKETS_DIAG=y` - XDP 套接字诊断

#### BPF LSM (Linux Security Module)
- `CONFIG_BPF_LSM=y` - 基于 BPF 的 LSM

#### cgroup BPF
- `CONFIG_CGROUP_BPF=y` - 将 BPF 程序附加到 cgroups
- `CONFIG_SOCK_CGROUP_DATA=y` - 套接字 cgroup 数据

#### BPF 基础设施
- `CONFIG_BPF_LIRC_MODE2=y` - LIRC mode2 设备的 BPF
- `CONFIG_BPFILTER=y` - 基于 BPF 的数据包过滤
- `CONFIG_BPFILTER_UMH=m` - BPF 过滤器用户模式助手

#### 追踪与可观测性
- `CONFIG_FTRACE=y` - 函数追踪器
- `CONFIG_KPROBES=y` - 内核探针
- `CONFIG_KPROBE_EVENTS=y` - 基于 Kprobe 的事件追踪
- `CONFIG_UPROBE_EVENTS=y` - 用户空间探针事件
- `CONFIG_TRACEPOINTS=y` - 追踪点支持
- `CONFIG_PERF_EVENTS=y` - 性能监控

#### 调试信息
- `CONFIG_DEBUG_INFO=y` - 启用调试信息
- `CONFIG_DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT=y` - 使用工具链默认 DWARF 版本

#### 依赖项
- `CONFIG_KALLSYMS=y` - 内核符号表
- `CONFIG_KALLSYMS_ALL=y` - kallsyms 中的所有符号

## 使用场景

启用这些配置后，VyOS 内核将支持：

1. **现代 eBPF 程序** - 运行复杂的 BPF 程序用于网络、安全、追踪
2. **XDP 高性能网络** - 在驱动层进行数据包处理
3. **BPF-based 安全** - 使用 BPF LSM 实现自定义安全策略
4. **可观测性工具** - 支持 bpftrace, bcc, libbpf 等工具
5. **容器网络** - Cilium, Calico 等 CNI 插件的 BPF 数据路径
6. **流量控制** - tc-bpf 进行高级流量整形

## 构建要求

### 必需的构建工具
- `pahole` >= 1.21 (用于生成 BTF)
- `clang` >= 10 (用于编译 BPF 程序)
- `llvm` (用于 BPF 后端)

### 构建时注意事项
1. BTF 生成会增加编译时间
2. 需要足够的内存用于 BTF 处理
3. 确保 pahole 工具已安装

## 验证方法

构建完成后，可以通过以下方式验证 BPF/BTF 支持：

```bash
# 检查 BTF 信息
ls -lh /sys/kernel/btf/vmlinux

# 检查 BPF 系统调用
zgrep CONFIG_BPF /proc/config.gz

# 使用 bpftool
bpftool feature probe kernel

# 检查 XDP 支持
ip link set dev eth0 xdp off
```

## 兼容性

- 内核版本: 6.18.20
- 架构: x86_64 (amd64)
- VyOS 构建系统: vyos-build current

## 参考资料

- [Linux Kernel BPF Documentation](https://www.kernel.org/doc/html/latest/bpf/)
- [BTF (BPF Type Format)](https://www.kernel.org/doc/html/latest/bpf/btf.html)
- [XDP - eXpress Data Path](https://www.kernel.org/doc/html/latest/networking/af_xdp.html)
