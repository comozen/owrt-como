# owrt-como

个人自定义文件包（OpenWrt / ImmortalWrt）。把 `files/` 下的内容原样安装进固件
rootfs，不编译任何源码。

## 目录结构

```
owrt-como/
├── Makefile
└── files/                    # 这里的路径 = 固件里的绝对路径
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

## 构建集成

两种方式，任选其一：

### A. 独立仓库 + `Scripts/Packages.sh`

在 `Scripts/Packages.sh` 里加一行：

```bash
UPDATE_PACKAGE "owrt-como" "comozen/owrt-como" "main"
```

然后在 `Config/PRIVATE.txt` 里：

```
CONFIG_PACKAGE_owrt-como=y
```

### B. 放进源码 fork

把 `owrt-como/` 整个目录放到源码 fork 的 `package/owrt-como/`，
`BE10000.yml` 的 `WRT_REPO` 指向该 fork，`PRIVATE.txt` 里同样加
`CONFIG_PACKAGE_owrt-como=y`。这种方式 CI 仓库零冲突。

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
