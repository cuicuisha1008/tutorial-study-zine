# AI 干中学 · Tutorial Study Zine

**把 AI 学会，把日常做美。**

一套适用于 Codex 的中文教程排版 Skill。把教程文案、原始截图与照片，制作成统一的 3:4 高清纸感 Zine 系列。

## 视觉与制作规则

- 奶油纸底、浅蓝点阵、珊瑚色强调，保持干净、克制。
- 宋体标题＋楷体引导与提示＋无衬线操作正文，沿用已确认定稿。
- Part 卡片使用整体内嵌阴影，图片保持原比例、轻圆角和柔和阴影。
- 步骤编号按每页顺序左右交替：两步左右、三步左右左、四步左右左右。
- 截图、帖子、菜单与照片原图直贴，禁止生成式重绘真实素材与界面文字。
- 局部修改只改变指定区域，保留其余内容，交付前检查残影、重叠与出框。
- 平台名称、图标和网址按本期内容或商单要求决定。
- 逻辑画布 1086×1448；2× 预览 2172×2896；默认 PNG 4344×5792。

## 使用

将本仓库中的整个 `tutorial-study-zine` 文件夹放入个人 Codex skills 目录，保留 `assets`、`references` 和 `scripts`。默认目录为 `~/.codex/skills/`；已有同名版本时先备份再更新。

在 Codex 中调用：

```text
$tutorial-study-zine
把下面的教程文案和我上传的原始截图，排成 AI 干中学系列。
需要封面、步骤页和收尾页，输出 3:4 高清 PNG 与可编辑源文件。
```

局部修改示例：

```text
$tutorial-study-zine
只将第 2 页 Part 03 的图片换成这张原图。
保持原比例，其他标题、文案、卡片和装饰不变。
```

## 文件结构

```text
tutorial-study-zine/
├── SKILL.md                   入口与执行 SOP
├── agents/openai.yaml         调用信息
├── references/                视觉系统、页型、素材处理及验收规则
├── assets/approved-style.css  可复用字体和组件样式
├── assets/approved-*-reference.png  已确认的视觉参考
├── assets/step-number-*.png    固定编号纽扣
└── scripts/                   可选的本地辅助工具
```

[阅读完整 Skill](tutorial-study-zine/SKILL.md) · [视觉系统](tutorial-study-zine/references/v1-visual-system.md) · [验收清单](tutorial-study-zine/references/acceptance-checklist.md)

## 定稿参考

以下是历史定稿的视觉依据，保留原始尺寸与内容。它们不是新的 3:4 输出模板：后续页面需使用 V2 规则重新排版，不能整页拉伸。具体菜品、截图、平台与文案属于示例，不会自动带入新一期。

<img src="tutorial-study-zine/assets/approved-step1-reference.png" alt="四步页定稿：干净纸感、混合字体、左右交替编号" width="420">
<img src="tutorial-study-zine/assets/approved-step2-reference.png" alt="两步页定稿：上下图文交错布局" width="420">

## 运行说明

Skill 由支持本地文件和排版工具的 Codex 执行；它不是单独运行的网站或一键生图程序。正式输出优先 HTML/CSS/SVG 等可精确控制的排版方式。

字体优先采用 macOS 的宋体、楷体、苹方。其他系统需提供同类别字体并目检字形与换行。仓库不分发字体文件。

`scripts/` 中 Python 图片合成工具依赖 Pillow 和 NumPy；Swift 抠图工具使用 macOS 框架，仅在对应处理需要时使用。历史 `render_master.py` 只生成坐标参考，不作为 V2 最终视觉母版。

4× 导出会提高文本与布局的渲染分辨率；照片和截图的真实细节仍取决于原文件。源图缺失时需补充原图，不能生成假界面或补画文字。
