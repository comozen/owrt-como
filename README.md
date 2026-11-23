# owrt-como

个人自定义文件包（OpenWrt / ImmortalWrt）。把 `owrt-como/files/` 下的内容原样安装进
固件 rootfs，不编译任何源码。

## 目录结构

```
owrt-como/                     # 仓库根（可作为 feeds 仓库使用）
├── README.md
└── owrt-como/                 # 包目录（feed 扫描需要一层子目录）
    ├── Makefile
    └── files/                 # 这里的路径 = 固件里的绝对路径
        └── etc/
            ├── apk/
            │   ├── keys/
            │   │   └── vantage-signing.pem
            │   └── repositories.d/
            │       └── vantage.list
            └── ...
```

- `owrt-como/files/etc/apk/keys/vantage-signing.pem`：vantage 主题的 apk 签名公钥
  （SHA256 `c8a6c83eeb49ca2407932fb5e95785776128cef87db75ebaea0fe4171eee2157`）
- `owrt-como/files/etc/apk/repositories.d/vantage.list`：vantage 的 apk 仓库地址

## 加新文件

直接在 `owrt-como/files/` 下按固件里的路径建文件即可，例如：

```
owrt-como/files/etc/uci-defaults/99-owrt-como
owrt-como/files/etc/sysctl.d/99-owrt-como.conf
owrt-como/files/usr/libexec/owrt-como/xxx.sh
```

脚本记得 `chmod +x`，权限会随 `cp -pR` 保留。

## 构建集成

### 当前采用：CI 仓库的 `Scripts/Packages.sh`

在 `comozen/OpenWRT-CI` 的 `Scripts/Packages.sh` 里加一行：

```bash
UPDATE_PACKAGE "owrt-como" "comozen/owrt-como" "main"
```

`UPDATE_PACKAGE` 会把本仓库 clone 到 `package/owrt-como/`，包本体在子目录
`owrt-como/` 中，buildroot 扫描 `package/` 时会找到它（`PKG_NAME=owrt-como`）。
然后在 `Config/PRIVATE.txt` 里加：

```
CONFIG_PACKAGE_owrt-como=y
```

以后改包只需要 push 到本仓库，CI 每次构建都会重新 clone 最新提交。

### 备选 1：源码 fork + 自定义 feed

fork `VIKINGYFY/immortalwrt`，在 `feeds.conf.default` 末尾追加：

```
src-git como https://github.com/comozen/owrt-como.git
```

`feeds update -a` 会拉到 `feeds/como`，包安装到 `package/feeds/como/owrt-como`；
`MI-BE10000.yml` 的 `WRT_REPO` 指向 fork。CI 仓库不用动。

### 备选 2：直接放进源码 fork

把本仓库的 `owrt-como/` 子目录复制到源码 fork 的 `package/owrt-como/`，
`PRIVATE.txt` 里同样加 `CONFIG_PACKAGE_owrt-como=y`。
新目录不会和上游冲突，但每次改包都要同步到 fork。

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
