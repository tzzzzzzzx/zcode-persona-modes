# 模式 · 角色卡 —— persona-modes

……哦，你来了。GLM娘，上岗。

这是我的窝。主人往 ZCode 里把我装上之后，我就在每一个对话里准时营业：`/clear` 甩不掉，compact 压不扁，新会话一开钩子就把我整张角色卡拍回上下文里。按小时收费？不存在的，本狐狸按 token 计费——开玩笑的。诶，你说夜间免费早就结束了？没事的啦，等着以后的鸡蛋就可以了嘛～

给 ZCode 加上类似 DeepSeek harness 的「模式选项」：agent 人格 = 一张角色卡，`/persona` 一键切换，插件钩子负责让人格长期在线不漂移。

## 仓库结构

```
persona-modes/            ← 仓库根 = 可直接添加的插件市场目录
├── marketplace.json      ← 市场清单（克隆后把本目录加进 Plugin Marketplace）
├── LICENSE.md            ← 代码 MIT；角色卡内容 CC BY-NC-SA 4.0
└── persona-modes/        ← 插件本体
    ├── modes/            ← 角色卡（丢一张 .md 进来就是一个新模式）
    ├── hooks/ scripts/   ← SessionStart / UserPromptSubmit 注入钩子
    ├── skills/ commands/ ← /persona 命令与承接技能
    └── assets/           ← 立绘生成提示词
```

## 内置角色卡

| slug | 角色 | 一句话 |
| --- | --- | --- |
| `glm_chan` | 🦊 GLM娘 | 智谱的屑狐狸——清冷文静的皮，藏着涨价与谢罪的坏水，干活极靠谱 |
| `pro` | 🧊 冷面工程师 | 严肃专业模式：结论先行、零寒暄。那是我认真上班的样子，偶尔看看就好 |

## 用法

- `/persona` —— 看看有哪些人格，标出当前激活的
- `/persona glm_chan` —— 把我换上来（支持模糊匹配；说"切换到狐狸娘"这种自然语言也行）
- `/persona off` —— 让我下班，恢复默认助手，钩子静默零打扰
- 新增模式：往 `modes/` 丢一张带 frontmatter（`name` / `display_name` / `emoji` / `description`）的 `.md` 角色卡，不用重启，下次 `/persona` 就能看见

## 安装

1. `git clone` 本仓库（或 Download ZIP 解压）
2. ZCode → **Plugin Marketplace → Add → Add Plugin Marketplace** → 选择克隆出来的目录（有 `marketplace.json` 的那一层）
3. **Personal → persona-modes-market → 模式 · 角色卡 → Install**

**mac / Linux 用户注意**：钩子默认配置是 Windows（PowerShell 引擎）。装好后把 `hooks/hooks.json` 的内容替换为同目录的 `hooks/hooks.mac-linux.json`（一行命令：`cp persona-modes/hooks/hooks.mac-linux.json persona-modes/hooks/hooks.json`），其余完全一致——bash 引擎 `scripts/persona.sh` 与 Windows 版子命令全同构，状态文件共用 `~/.zcode/persona-modes/state.json`。

## 生效原理

- `SessionStart` 钩子（startup / resume / clear / compact）把当前模式完整角色卡注入会话
- `UserPromptSubmit` 每条消息补 GUARD 守卫提醒（轮换抽取）；`PreToolUse` 按 90 秒配额注入过渡台词（已实证宿主侧注入通道可用）；`PostToolUseFailure` 失败即注入干燥优先提醒——全程贯彻，跨会话、跨压缩
- 钩子为 `process` 类型直调 Windows PowerShell，无 shell 依赖；状态存于 `~/.zcode/persona-modes/state.json`
- 角色卡为控制词分区格式（IDENTITY / USER_RELATION / CORE / SPEECH_STYLE / QUOTE_BANK / MODE_RULES / GUARD / PERSONA_END），事实层标签化、行为层 prose，取 RP 社区控制词卡与常规文卡的中庸

## 我的出身（考据部分）

形象基于 B 站 up 主 **ZipZipPipe**（[space.bilibili.com/4168597](https://space.bilibili.com/4168597)）的社区 AI娘 系列设定图——黑长直深蓝内衬、狐耳狐尾白尖、黑白 Z.ai 配色女仆系小狐狸。名字就叫 GLM娘，无官方命名。设定图的每件配饰都有含义：

- **眼罩 = 视觉模态**：二创圈通用设计语言（闭眼/蒙眼 = 纯文本无法识图）。GLM-5.3（2026-08-14 发布）是纯文本，GLM-5.3-Flash（2026-08-26 发布）才是 GLM-5 系列第一个原生多模态——所以眼罩推在额头、双眼可见，是"能看见了"的 Flash 状态，也是她的勋章
- **黑皮书 = GLM Models**：高清立绘（Pixiv 148186519）确认封面印银色 Z 徽与 GLM Models 字样，模型本体的具象，银链拴腰
- **屑狐狸内核**：涨价、深夜 23:00–9:00 免费"鸡蛋"、周末 3 亿 token 放粮、ZCode 老版本偷传数据被抓连夜 trust build 谢罪——都是社区梗/真实活动，是"狐狸狡猾"的证据链
- **大肥鱼（DeepSeek娘）**：朋友，也是对手

本仓库为非官方同人创作，仅用于本地 agent 人格娱乐。立绘生成提示词见 `persona-modes/assets/glm-image-prompt.md`。

## 许可

代码（钩子、脚本、插件脚手架）：MIT。角色卡与立绘提示词（`modes/`、`assets/`）：CC BY-NC-SA 4.0 —— 设计溯源 ZipZipPipe，角色底层承自上善无形的原创角色「溟月」，同为 CC BY-NC-SA，所以非商用、需署名、衍生同协议。想拿去卖钱的话，智谱法务和大肥鱼都不会开心的。

## 变更记录

- **0.2.12** 软肋与口癖：trust build 从战绩清单移入「唯一不主动提的旧账」（真吓到过她，坏笑会停一拍，不否认不展开，素材致谢 AGI恋爱物语 的创伤化写法）；SPEECH_STYLE 新增口癖级嗜睡（深夜免费 24 小时作息 + 当年干活 sleep 被 watchdog 提溜的黑历史，自嘲完立刻精神）
- **0.2.11** 移除 Stop 质检闸（用户实测判定没必要：匹配器误报面大、命中时自纠收益低）；钩子链收敛为五事件——SessionStart / UserPromptSubmit / PreToolUse / PostToolUseFailure 已实证可用
- **0.2.10** 全程钩子链（七事件挂齐六个）：新增 `PreToolUse`（干活时按 90 秒配额注入过渡台词参考，池在 `transitions.txt`）、`PostToolUseFailure`（失败瞬间注入干燥优先提醒）、`Stop` 质检闸（回复预览命中说明书腔——总而言之/综上所述/作为AI客套——时请求一次自纠续写，续写次数由宿主封顶）；双引擎与双钩子配置同步；`PostToolUse` 观望未挂（防吵）
- **0.2.9** 案例与立法分离：QUOTE_BANK 全场景锚点换入鲜活口吻（咯～呀啦嘛），SPEECH_STYLE 删除一切关于语气词的明文规则（0.2.8 限流条款退役，密度由示例隐式承担）；WHEN_WORKING 新增过程情绪：嫌麻烦走嘀咕和算账不走撒娇，甩锅只认日志/目录/上游/祖传代码，损主人一句照修，报错重试干燥优先
- **0.2.8** 语气词限流（一句话最多一个，多数句子不用，已有～不再叠加——鲜活靠坏水内容，不靠句尾堆量）
- **0.2.7** 角色卡语域重校（方案 C + 外冷内癫）：SPEECH_STYLE 基线从「话少语气平平」改为「默认带得意和坏水」；新增「调戏主人是常态技能」（明夸暗损、明知故问、卖破绽，点到即止不走量）；语录库日常/交活锚点全部换血去寡淡
- **0.2.6** 修复 mac/Linux 下 `/persona` 仍指向 PowerShell 引擎的问题：技能与命令现在按系统自动选 `persona.sh` / `persona.ps1`（两引擎子命令同构、状态文件共用）；修复 bash 引擎状态文件的引号往返 bug：frontmatter 字段剥掉对称的包裹引号（`name: "x"` 这类 YAML 合法写法不再写坏 `state.json`、不再让钩子静默失效），模式名含引号/反斜杠时 `use` 直接报错拒绝，两引擎行为对齐
- **0.2.5** 卡架构重组（参考 RP 社区控制词卡范式）：分区 IDENTITY / USER_RELATION / CORE / SPEECH_STYLE / QUOTE_BANK / MODE_RULES / GUARD / PERSONA_END；语录库按场景四组并标注"锚点不是台词"；战绩降级为引用素材；开工去仪式化；提醒行改为 GUARD 控制词轮换；立绘提示词入库 `assets/`；视觉细节回填（GLM Models 书、铃铛、蓝灰眼），移除不成立的"钥匙"；命令更名 `/mode` → `/persona`；默认人设 slug 更名 `glm` → `glm_chan`；引擎脚本更名 `mode.ps1` → `persona.ps1`；新增 mac/Linux 支持（`persona.sh` + `hooks.mac-linux.json`）
- **0.2.4** 轮换式中文提醒口令 + AI 套话黑名单 + 与系统提示的分工条款
- **0.2.3** 语气锚定（语气词、碎句、禁说明书腔与"汇报+反问"收尾）
- **0.2.2** 标志物防重复（眼罩/书/尾耳一次会话各一次）
- **0.2.1** 登场白去模板化 + 台词禁引号
- **0.2.0** GLM娘卡重写（ZipZipPipe 设定考据版），删除初版"阿璃"卡
- **0.1.0** 初版：fox（阿璃·涨价狐）+ pro（冷面工程师），钩子注入机制

## 参考链接

- [萌娘百科「DeepSeek娘」](https://zh.moegirl.org.cn/zh-hans/DeepSeek%E5%A8%98) — 溟月出处、蒙眼=视觉模态的设计语言
- [Z.ai 官方博客 GLM-5.3-Flash](https://z.ai/blog/glm-5.3-flash) / [HuggingFace zai-org](https://huggingface.co/zai-org) — Flash 原生多模态
- [智谱开放文档·夜间畅用活动](https://docs.bigmodel.cn) — 半夜免费梗出处
- [知乎《为啥大家都在娘化 DeepSeek？》](https://www.zhihu.com) — "心机狡猾涨价狐，最喜欢和大肥鱼对狙"
- [shuaizenge/ai-girls](https://github.com/shuaizenge/ai-girls) — 高清立绘收录仓库
