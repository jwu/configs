# 蓝牙

适配器由系统级 `bluetoothd` 提供，命令行是 `bluetoothctl`，交互式管理用 `bluetuith`（TUI）。
本机 `bluetuith` 是 `go install` 装到 `~/.local/bin/` 的，不走 pacman，所以 AUR 里那几个同名包
（`bluetuith` / `bluetuith-bin` / `bluetuith-git`）都别装，否则两份二进制会互相抢 OBEX agent。

## OBEX agent 只有一个槽位

BlueZ 的 `org.bluez.obex.AgentManager1`（会话总线上的 `org.bluez.obex`，即 obexd）**同时只接受
一个 agent**。谁先注册谁占着，后来者收到 `AlreadyExists`，错误文本就是 `Agent already exists`。

bluetuith 启动时会注册自己的 agent（随机路径 `/org/bluez/obex/agent/obexagent<id>`），用来接收
对方推送的文件（落到 `--receive-dir`）。槽位被占时它不会崩，只是把「OBEX Receive Files」标成
不可用，并在进 TUI 之前打印：

```
The following features are not available:
OBEX Receive Files: Capabilities 'OBEX Receive Files' cannot be activated: Agent already exists
```

只有**接收**需要注册 agent，`OBEX Send Files` 不受影响。

## 常见占用者：blueman-applet

`blueman-applet` 的 `TransferService` 插件会在 `/org/bluez/obex/agent/blueman` 注册 agent
（见 `blueman/plugins/applet/TransferService.py`）。它只要跑着，bluetuith 就永远拿不到槽位——
这就是上面那条报错的典型来源。

本仓库的 niri 配置**不启动 blueman-applet**（历史上一度启动过，才撞上这个问题）：

```
# 不要把下面这行加回 linux/.config/niri/config.kdl
spawn-at-startup "blueman-applet"
```

必须两个都用的话只能二选一：停掉 applet，或者给 bluetuith 加 `--disable-obex-services` 让它彻底
不管 OBEX（代价是收不到文件）。

顺带：`blueman-manager`（GUI 管理器）只加载 ManagerPlugin，不注册 OBEX agent，不会冲突。

## 诊断：谁占着槽位

`busctl` 直接发一次注册调用就能探到（obexd 只判断「是否已有 agent」，不校验路径对象是否存在）：

```
busctl --user call org.bluez.obex /org/bluez/obex \
  org.bluez.obex.AgentManager1 RegisterAgent o /test/probe
```

- `Call failed: Agent already exists` → 槽位被占
- 无输出、退出码 0 → 槽位是空的

路径里的元素只能用 `[A-Za-z0-9_]`，带 `-` 会被 `busctl` 拒掉（`Failed to create bus message:
Invalid argument`）。探测进程一断开，obexd 会按 sender 自动回收这条记录，不留残留。

## bluetuith 的几个坑

- **没有单实例锁**：可以同时开多个，但第二个抢不到槽位、会重现上面的报错。所以别名/按钮别连点，
  要复用得自己写「已有就聚焦」的包装。
- **退出键是大写 `Q`**：小写 `q` 没有任何绑定，`Esc` 是关闭当前视图，`Ctrl-C` 完全没处理。
  `Ctrl-Z` 是挂起，别和退出搞混。
- **退出不断开设备**：`quit()` 只对适配器 `StopDiscovery()`，已连接的耳机/键鼠仍然连着；要断开得
  在界面里按 `d`，或者 `bluetoothctl disconnect`。
