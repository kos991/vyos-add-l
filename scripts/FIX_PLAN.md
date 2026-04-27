# 补丁修复方案

## 当前状态

### vyos-build 实际的 amd64.toml（15行）
```toml
# Packages added to images for x86 by default
packages = [
  "grub2",
  "grub-pc",
  "vyos-drivers-realtek-r8152",
  "vyos-linux-firmware",
  "vyos-intel-qat",
  "vyos-intel-ixgbe",
  "vyos-intel-ixgbevf",
  "vyos-ipt-netflow",
  "intel-microcode",
  "amd64-microcode"
]

[boot_settings]
  console_type = "ttyS"
```

## 问题分析

### 0015 补丁问题
- 期望找到 `serial_interface = "ttyS0,115200"`（旧格式）
- 实际文件使用 `[boot_settings]`（新格式）
- 补丁会失败

### 0016 补丁问题
- 期望在第 12 行后插入
- 但实际文件只有 15 行
- 且 0015 补丁的修改会改变文件结构

## 修复方案

### 方案：合并两个补丁为一个

创建新的 `0015-add-nexttrace-and-landscape.patch`，一次性添加：
1. nexttrace 仓库配置
2. landscape-router 包配置

**修改后的 amd64.toml 应该是：**
```toml
# Packages added to images for x86 by default
packages = [
  "grub2",
  "grub-pc",
  "vyos-drivers-realtek-r8152",
  "vyos-linux-firmware",
  "vyos-intel-qat",
  "vyos-intel-ixgbe",
  "vyos-intel-ixgbevf",
  "vyos-ipt-netflow",
  "intel-microcode",
  "amd64-microcode"
]

[packages.landscape-router]
  scm = "local"
  architecture = "amd64"

[boot_settings]
  console_type = "ttyS"

[additional_repositories.nexttrace]
  architecture = "amd64"
  url = "https://github.com/nxtrace/nexttrace-debs/releases/latest/download"
  distribution = "./"
  components = ""
  no_source = true
  key = "mDMEaO7vHRYJKwYBBAHaRw8BAQdAXY+aVR+gfjDiaI1CQZXTiaOJI9ZOEziFVxQPheIyrDG0IW54dHJhY2Uub3JnIDxjb250YWN0QG54dHJhY2Uub3JnPoiTBBMWCgA7FiEEoqH7meOhHVsUbhcLNigaslezB/oFAmju7x0CGwMFCwkIBwICIgIGFQoJCAsCBBYCAwECHgcCF4AACgkQNigaslezB/rjdQD+JmXqnB3kmkKVQRfH7urC/zTkp2UkkLhUw+dykoCTggcBAK5qLKvUJN6Xu3TF0dEuBqVV9+14OkTbg4Ymaw7gUpEPuDgEaO7vHRIKKwYBBAGXVQEFAQEHQILPhsR2XsUYs7orwth28VQZRlXznHYsjCISbUb+UPgxAwEIB4h4BBgWCgAgFiEEoqH7meOhHVsUbhcLNigaslezB/oFAmju7x0CGwwACgkQNigaslezB/qHNwD/d3Yl/QhT/62Cghg575+XTEbnsrCIhazszdTd8NB4OFUA+wU421K4YjDrCAQy+C77YlRQ1pxFv3cYIMHn3H9qTEUM"
```

## 实施步骤

1. 删除旧的 0015 和 0016 补丁
2. 创建新的合并补丁
3. 更新 Git 提交
4. 创建新的构建标签
5. 触发构建

## 补丁内容

正确的补丁应该是：
- 在第 13 行（`]` 之后）插入 landscape 配置
- 在第 18 行（`[boot_settings]` 之后）插入 nexttrace 配置
- 使用正确的行号范围：`@@ -11,5 +11,14 @@`
