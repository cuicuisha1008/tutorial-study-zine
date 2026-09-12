# 图像生成的边界

正式成品以确定性排版、真实文本层和原图直贴完成。图像生成仅用于用户需要的概念探索、空白纸张装饰或独立插画。不要把包含真实截图、照片、手写字或菜单的整页发去重绘。

## 空白装饰或骨架

提示词示例（按当前请求选择元素，不强制生成整套）：

```text
Create one clean warm-cream paper backdrop for a 3:4 Chinese tutorial zine.
Very faint pale-blue dot grid; restrained dusty-coral accents.
At most one or two small stationery motifs.
If cards are requested, use subtle inset shading across each entire card,
not thick drop shadows. Keep generous empty content areas.
No text, letters, numbers, logos, UI, screenshots, food, notebooks or fake photos.
No distressed dirty borders or heavy grain.
This is a decorative layer only; exact typography and original assets will be composited later.
```

尺寸若生成工具不能精确指定，生成装饰后在确定性阶段放到固定 1086×1448 画布。最终成品为 4344×5792 PNG。

## 独立装饰

```text
One isolated small pale dusty-pink hand-drawn bow, transparent background,
thin but legible line, restrained paper-print feeling.
No text, no additional objects.
```

已有纽扣 01–04 直接用资产，不重复生成编号。

## 局部修订

用户提出“只换这张图”“只改字体”时，改源文件中的相应图层。字体用 approved-style.css：细宋体页眉、宋体标题、楷体提示、无衬线正文。位置与范围遵循用户指定，冻结其他图层。

若已有生成稿把竖图变成横向双页或制造了假文字，停止用生成式修补反复猜测。清除错误区域，直接合成用户原始素材。源文件不可访问时请求补充原图，不补画。
