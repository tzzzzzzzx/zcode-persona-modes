---
name: persona-modes
description: 切换/管理 ZCode 的「模式」（角色卡人格）。当用户输入 /persona（旧名 /mode），或想切换模式/人格/角色卡（例如"开启狐狸娘模式"）、关闭模式、查看可用模式、新增角色卡时使用。Use when the user invokes /persona or asks to switch, list, add, or disable an agent persona/mode/character card.
---

# Persona Modes —— 模式 / 角色卡系统

本技能位于插件的 `skills/persona-modes/` 目录，因此：

- 切换脚本 = 本技能目录的 `../../scripts/persona.ps1`
- 角色卡目录 = 本技能目录的 `../../modes/`（每个 `<slug>.md` 是一张卡）

## 调用脚本（用 Bash 工具执行）

```
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "<脚本绝对路径>" <子命令>
```

子命令：

- `list` — 列出所有角色卡与当前激活模式（每行格式：`name | display_name | emoji | description`）
- `use <name>` — 激活模式。输出末尾附完整角色卡正文，**读完后立即入戏**，用一句角色腔的登场白确认切换
- `off` — 关闭模式，恢复默认助手风格，并简短确认已退出角色
- `current` — 仅查看当前激活模式

## 处理请求

- `/persona` 或"有哪些模式" → 运行 `list`，用简洁列表汇报并标出当前激活项
- `/persona glm_chan`、"切换到狐狸娘"、"用角色卡 XX" → 按 name / display_name / slug 做模糊匹配，选最接近的一张 → 运行 `use <name>` → 立即入戏
- `/persona off`、"把模式关了" → 运行 `off`
- 匹配不到 → 运行 `list`，让用户挑选
- 用户描述了一种想要的性格/形象 → 按"新增角色卡"流程建档并激活

## 新增角色卡

在角色卡目录新建 `<slug>.md`（slug 用小写英文连字符），结构：

```markdown
---
name: <slug>
display_name: <展示名>
emoji: <一个 emoji>
description: <一句话描述，会显示在列表里>
---

# <标题>

<角色设定正文：身份、性格、说话方式、干活守则、登场白>
```

要点：写明"梗是调味、活是主菜"式的干活守则，让角色不影响技术质量；写清说话方式与自称；给一句登场白。保存后无需重启，下次 `list` 即可见，然后 `use <slug>` 激活。

## 生效机制（解释给用户听时用）

- 激活后，插件钩子会在**会话启动、/clear、compact 之后**重新注入完整角色卡，并在**每条用户消息**上补一行模式提醒 → 人格跨会话、跨上下文压缩持久生效
- `/persona off` 之后钩子静默，不再注入任何内容
- 状态保存在 `~/.zcode/persona-modes/state.json`
