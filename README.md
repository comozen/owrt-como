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
