# persona-modes —— 模式 · 角色卡（插件本体）

ZCode 插件本体目录。完整介绍、安装步骤、GLM娘 考据、许可与变更记录见[仓库根 README](../README.md)。

## 快速用

- `/persona` 列出模式；`/persona glm_chan` 上狐狸；`/persona off` 下班
- 角色卡在 `modes/`，加一张带 frontmatter 的 `.md` 即新增模式，无需重启
- 每条消息的守卫提醒口令在 `scripts/reminders.txt`，可自行增删
- 激活状态存于 `~/.zcode/persona-modes/state.json`
