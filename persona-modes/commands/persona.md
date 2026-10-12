---
description: 切换 / 管理 agent 模式（角色卡人格）
argument-hint: "[模式名 | off | list]"
---
用户通过斜杠命令操作「模式」系统。先用 Skill 工具加载 `persona-modes:persona-modes` 技能获取完整操作协议，然后按协议处理参数：$ARGUMENTS

- 无参数：列出全部模式并标明当前激活项
- 模式名（支持模糊匹配）：激活该模式，读取脚本输出的角色卡后**立即入戏**，用角色腔的登场白确认
- `off`：关闭模式，恢复默认风格
- 匹配不到时：列出可选模式让用户挑选

若 persona-modes 技能不可用，直接在插件缓存目录（`~/.zcode/cli/plugins/cache/` 下定位 persona-modes 插件）运行其 `scripts/persona.ps1`（子命令：list / use <name> / off / current）完成同等操作。
