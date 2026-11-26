# owrt-como

个人自定义文件包（OpenWrt / ImmortalWrt）。把 `files/` 下的内容原样安装进固件
rootfs，不编译任何源码。

## 目录结构

```
owrt-como/                     # 仓库根 = 包目录（UPDATE_PACKAGE 克隆后直接可用）
├── Makefile
├── README.md
└── files/                     # 这里的路径 = 固件里的绝对路径
    └── etc/
        ├── apk/
        │   ├── keys/
        │   │   └── vantage-signing.pem
        │   └── repositories.d/
        │       └── vantage.list
        └── ...
```

- `files/etc/apk/keys/vantage-signing.pem`：vantage 主题的 apk 签名公钥
  （SHA256 `c8a6c83eeb49ca2407932fb5e95785776128cef87db75ebaea0fe4171eee2157`）
- `files/etc/apk/repositories.d/vantage.list`：vantage 的 apk 仓库地址
- `files/etc/apk/keys/daeuniverse.pem`：daeuniverse（dae / honk）的 apk 签名公钥
  （SHA256 `5aae30568b7e08f86ea3e72a19fa281d835ba4eff8ab38849abcd2b0884c6cd5`）
- `files/etc/apk/repositories.d/daeuniverse.list`：dae / honk 的 apk 仓库地址
  （`aarch64_cortex-a53` / 25.12，使用 `@daeuniverse` 标签）

## 加新文件

直接在 `files/` 下按固件里的路径建文件即可，例如：

```
files/etc/uci-defaults/99-owrt-como
files/etc/sysctl.d/99-owrt-como.conf
files/usr/libexec/owrt-como/xxx.sh
```

脚本记得 `chmod +x`，权限会随 `cp -pR` 保留。

## 构建集成（当前采用）

CI 仓库 `comozen/OpenWRT-CI` 的 `Scripts/Packages.sh` 里已有：

```bash
UPDATE_PACKAGE "owrt-como" "comozen/owrt-como" "main"
```

它会把本仓库 clone 到 `./package/owrt-como/`，包根目录的 Makefile 会被
buildroot 直接识别为 `owrt-como` 包。

`Config/PRIVATE.txt` 里已有：

```
CONFIG_PACKAGE_owrt-como=y
```

以后改包只需要 push 到本仓库，CI 每次构建都会重新 clone 最新提交。

## 备选：作为自定义 feed

`scripts/feeds` 扫描时使用 `find -mindepth 1`，**不会识别仓库根目录的 Makefile**。
如果以后想改成 feed 方式（源码 fork 的 `feeds.conf.default` 加一行 `src-git`），
需要把 `Makefile` 和 `files/` 放进一层子目录（例如 `owrt-como/`），再调整 feed 配置。

## dae / honk

仓库同时做了两件事：

1. 带上 daeuniverse 的签名公钥和 apk 仓库地址：
   - `files/etc/apk/keys/daeuniverse.pem`
   - `files/etc/apk/repositories.d/daeuniverse.list`
2. 把 honk 相关 apk 离线打包进固件：
   - `files/usr/share/owrt-como/apk/honk-*.apk`
   - `files/usr/share/owrt-como/apk/luci-app-honk-*.apk`
   - `files/usr/share/owrt-como/apk/luci-lib-daeuniverse-*.apk`
   - `files/usr/share/owrt-como/apk/luci-i18n-daeuniverse-zh-cn-*.apk`
   - `files/usr/share/owrt-como/apk/vmlinux-btf-builtin-*.apk`

首次开机时 `/etc/uci-defaults/99-honk` 会自动离线安装这些包
（`apk add --no-network`，不访问网络），安装后 LuCI 出现「服务 → daehonk」。
安装失败时日志在 `/tmp/honk-install.log`，可手动重试：

```sh
apk add --no-network --allow-untrusted /usr/share/owrt-como/apk/*.apk
```

注意：

- honk 需要内核 BTF（`/sys/kernel/btf/vmlinux`）。构建时 `PRIVATE.txt` 必须包含：

  ```
  CONFIG_KERNEL_DEBUG_INFO_REDUCED=n
  CONFIG_KERNEL_DEBUG_INFO_BTF=y
  CONFIG_PACKAGE_kmod-sched-bpf=y
  CONFIG_PACKAGE_v2ray-geoip=y
  CONFIG_PACKAGE_v2ray-geosite=y
  ```

  （`kmod-veth`、`kmod-nft-queue`、`kmod-nfnetlink-queue`、`kmod-sched-core`、
  `kmod-nf-conntrack` 默认已是 `=y`。）

- honk 安装在 overlay 上，约占用几十 MB；普通 sysupgrade 会保留，`-n` 清空或
  重新刷机后由上面的 uci-defaults 自动装回。
- honk 与 dae 不能同时运行。
## honk 版本维护

- **构建时**：CI 的 `Scripts/Packages.sh` 会从 daeuniverse 仓库拉取这 5 个 apk 的最新版本，
  覆盖本仓库里的 `files/usr/share/owrt-como/apk/`（下载失败则保留仓库里的版本，不影响构建）。
- **刷机后**：首次开机由 `/etc/uci-defaults/99-honk` 离线安装这些 apk，
  所以固件里是**构建时**的最新版本。
- **手动更新**（不自动开机升级）：

  ```sh
  honk-update
  ```

  它等价于：

  ```sh
  apk update
  apk add -u honk@daeuniverse luci-app-honk@daeuniverse \
      luci-lib-daeuniverse@daeuniverse \
      luci-i18n-daeuniverse-zh-cn@daeuniverse \
      vmlinux-btf-builtin@daeuniverse
  ```

  本地 apk 安装会把包锁定在 `/etc/apk/world`（`honk><Q1…`），
  `@daeuniverse` 重新声明会解除锁定，之后 LuCI 的更新功能也能正常使用。

## 验证

固件里应存在：

```sh
ls -l /etc/apk/keys/vantage-signing.pem
cat /etc/apk/repositories.d/vantage.list
apk update
```

## 注意

- 这个包里的文件会随固件分发；sysupgrade 后仍然存在，无需手动添加。
- 密钥只信任 anothaDev 签名的包，升级主题请定向执行：
  `apk add -u luci-theme-vantage`，不要全量 `apk upgrade`。
- 仓库路径里的 `25.12` 对应 apk 3.x 固件；将来主干升级记得同步修改。
