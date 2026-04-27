# VyOS Build Issues Summary

## 编译失败问题汇总

### 问题 #1: Jool 内核模块补丁过时
**时间**: 2026-04-27 13:16  
**Tag**: 6.18-main-20260427-1316  
**错误**: 
```
patching file src/mod/common/nl/core.c
Hunk #1 FAILED at 1.
```

**原因**: 
- Jool 补丁针对旧版本代码
- 上游 Jool 已更新到 4.1.15
- 补丁文件 `patches/kernel/0006-jool-nat64-4.1.12.patch` 与当前代码不兼容

**解决方案**: 
- 跳过过时的 Jool 补丁
- 修改 `build-kernel.sh` 直接使用上游 Jool 4.1.15
- Commit: eed7190

**状态**: ✅ 已解决

---

### 问题 #2: BPF 配置冲突
**时间**: 2026-04-27 14:00  
**Tag**: 6.18-main-20260427-1500  
**错误**:
```
patching file arch/x86/configs/vyos_defconfig
Hunk #1 FAILED at 8831.
```

**原因**:
- BPF 相关配置在补丁和 defconfig 中重复定义
- 补丁尝试添加已存在的配置项

**解决方案**:
- 从补丁中移除 BPF 配置
- 在构建脚本中直接复制 BPF 配置到 defconfig
- Commit: c8bbe6b

**状态**: ✅ 已解决

---

### 问题 #3: Landscape 包补丁行号错误（第一次）
**时间**: 2026-04-27 15:00  
**Tag**: 6.18-main-20260427-1500  
**错误**:
```
patching file data/architectures/amd64.toml
Hunk #1 FAILED at 12.
```

**原因**:
- 补丁文件 `patches/vyos-build/0016-add-landscape-package.patch` 行号不匹配
- 补丁期望在第 12 行后插入，但文件结构已变化
- 补丁上下文使用 `serial_interface`，但实际文件使用 `[boot_settings]`

**尝试的解决方案**:
- 更新补丁上下文从 `serial_interface` 改为 `[boot_settings]`
- Commit: 3afbd30

**状态**: ❌ 未完全解决

---

### 问题 #4: Landscape 包补丁行号错误（第二次）
**时间**: 2026-04-27 16:32  
**Tag**: 6.18-main-20260427-1632  
**错误**: 同问题 #3

**原因**:
- amd64.toml 文件实际只有 15 行
- 补丁仍然尝试在第 12 行后修改
- 实际应该在第 14 行后插入（`amd64-microcode` 之后）

**解决方案**:
- 重新生成补丁，使用正确的行号范围 `@@ -11,3 +11,7 @@`
- 确保上下文匹配实际文件内容：
  ```
    "intel-microcode",
    "amd64-microcode"
  ]
  ```
- Commit: 6e6d0f7

**状态**: ❌ 仍然失败

---

### 问题 #5: 补丁顺序冲突 - 多个补丁修改同一文件
**时间**: 2026-04-27 19:48  
**Tag**: 6.18-main-20260427-1633  
**错误**: 同问题 #3/#4

**根本原因**:
两个补丁都修改 `data/architectures/amd64.toml`：
1. `0015-add-nexttrace-repo-amd64.patch` - 期望旧格式（`serial_interface`）
2. `0016-add-landscape-package.patch` - 期望新格式（`[boot_settings]`）

**问题分析**:
- vyos-build 上游已从旧格式改为新格式
- 0015 补丁基于旧格式，会失败或导致文件状态不一致
- 即使 0015 成功应用，0016 的行号也会错位
- 补丁按顺序应用，前一个补丁的修改会影响后续补丁的上下文

**解决方案**:
需要同时更新两个补丁：
1. 更新 0015 补丁以匹配新的文件格式
2. 更新 0016 补丁的行号，考虑 0015 补丁应用后的文件状态
3. 或者：合并两个补丁为一个，一次性添加所有修改

**状态**: 🔄 待修复

---

## 当前构建状态

**最新 Tag**: 6.18-main-20260427-1633  
**构建状态**: ❌ 失败（194 分钟后）  
**失败次数**: 5 次  
**总耗时**: ~450 分钟（7.5 小时）

---

## 已修复的文件

1. `build-kernel.sh` - 跳过 Jool 补丁，直接使用上游版本
2. `patches/kernel/0006-jool-nat64-4.1.12.patch` - 移除 BPF 配置部分
3. `patches/vyos-build/0016-add-landscape-package.patch` - 修正行号和上下文

---

## 技术细节

### amd64.toml 文件结构
```toml
packages = [
  "grub-pc",
  "grub-efi-amd64",
  "grub-efi-amd64-signed",
  "shim-signed",
  "linux-image-amd64",
  "linux-headers-amd64",
  "vyos-1x-smoketest",
  "intel-microcode",
  "amd64-microcode"
]

[packages.landscape-router]  # ← 在这里插入
  scm = "local"
  architecture = "amd64"

[boot_settings]
  console = "ttyS0,115200"
```

### 补丁应用顺序
1. 内核补丁（patches/kernel/*.patch）
2. vyos-build 补丁（patches/vyos-build/*.patch）
3. vyos-1x 补丁（patches/vyos-1x/*.patch）

---

## 经验教训

1. **补丁文件必须与目标代码库精确匹配**
   - 行号、上下文、缩进都必须完全一致
   - 上游代码变化会导致补丁失效

2. **使用 Git 标签触发自动构建**
   - 格式：`6.18-main-YYYYMMDD-HHMM`
   - 每次推送新标签会触发完整构建

3. **构建时间较长**
   - 平均 60-90 分钟
   - 主要时间消耗在内核编译

4. **监控构建进度**
   - 使用 GitHub API 实时监控
   - 每 30 秒检查一次状态
   - 每 5 分钟输出进度

---

## 失败原因总结

### 核心问题
所有 5 次构建失败都源于**补丁文件与目标代码库不匹配**：

1. **上游代码变化** - vyos-build 仓库的文件结构已更新，但补丁仍基于旧版本
2. **补丁冲突** - 多个补丁修改同一文件，导致上下文不一致
3. **行号错位** - 补丁的行号和上下文与实际文件不匹配

### 具体失败模式

| 构建 | Tag | 失败阶段 | 失败原因 | 耗时 |
|------|-----|---------|---------|------|
| #1 | 6.18-main-20260427-1316 | Jool 补丁 | 补丁过时 | 78m |
| #2 | 6.18-main-20260427-1500 | Landscape 补丁 | 缺少 amd64.toml 修改 | 47m |
| #3 | 6.18-main-20260427-1500 | Landscape 补丁 | 行号/上下文错误 | 80m |
| #4 | 6.18-main-20260427-1632 | Landscape 补丁 | 行号/上下文错误 | 87m |
| #5 | 6.18-main-20260427-1633 | Landscape 补丁 | 补丁顺序冲突 | 194m |

### 下一步行动

**方案 A: 修复所有补丁（推荐）**
1. 检查 vyos-build 当前版本的所有目标文件
2. 更新 0015 补丁以匹配新格式
3. 更新 0016 补丁考虑 0015 的修改
4. 测试补丁应用顺序

**方案 B: 合并补丁**
1. 将 0015 和 0016 合并为单个补丁
2. 一次性添加所有 amd64.toml 修改
3. 避免补丁顺序问题

**方案 C: 简化集成**
1. 暂时移除 nexttrace 集成（0015）
2. 只保留 landscape 集成（0016）
3. 减少补丁复杂度

---

## 后续代码检查

需要检查的文件：
1. `patches/vyos-build/0015-add-nexttrace-repo-amd64.patch` - 更新以匹配新格式
2. `patches/vyos-build/0016-add-landscape-package.patch` - 调整行号
3. `scripts/patch-and-build-vyos-image.sh` - 补丁应用逻辑

需要验证的内容：
- vyos-build 仓库当前的 amd64.toml 完整内容
- 补丁应用的顺序和依赖关系
- 是否有其他补丁也修改相同文件

---

*最后更新: 2026-04-27 19:50*
