---
name: slide
description: 将Markdown大纲文档转换为HTML幻灯片演示系统。当用户要求制作幻灯片、PPT、演示文稿，或说"帮我做个PPT"、"生成幻灯片"时使用。
---

# 幻灯片制作技能

将Markdown大纲文档转换为精美的HTML幻灯片演示系统，支持16:9画幅、键盘翻页、全屏展示、动画效果。

## 参数说明

- `$0`: MD大纲文件路径（必需）
- `--theme <主题>`: 可选配色主题

## 支持的主题

| 主题ID | 适用场景 | 主色 | 辅色 | 强调色 |
|--------|---------|------|------|--------|
| sport | 体育/运动/赛事 | #17408B | #C9082A | #FDB927 |
| tech | 科技/互联网/AI | #0f172a | #06b6d4 | #ffffff |
| business | 商务/金融/报告 | #1e3a5f | #6b7280 | #d4af37 |
| edu | 教育/学术/培训 | #166534 | #fef3c7 | #ea580c |
| medical | 医疗/健康/生物 | #0d9488 | #ffffff | #22c55e |
| creative | 创意/设计/艺术 | #7c3aed | #ec4899 | #facc15 |
| nature | 环保/自然/公益 | #15803d | #78350f | #0ea5e9 |
| gov | 政府/党政/机关 | #dc2626 | #fbbf24 | #ffffff |

如未指定主题，根据内容自动选择合适配色。

---

## 执行流程

### Phase 0:设定执行计划

按照如下几步设定执行计划：

1.内容分析
2.创建目录结构
3.为每页生成规划文档
4.生成CSS样式
5.生成JS控制脚本
6.生成HTML文件

执行每一步时都要回到skill文档查看该步骤的要点，执行完毕后向主代理汇报执行结果，验收通过后再进行下一步。

### Phase 1: 内容分析

1. **读取大纲文件**
   ```
   Read $0
   ```
   如果文件为空，提示用户填充内容并停止。

2. **识别主题领域**
   - 分析标题和关键词
   - 确定行业/领域（体育、科技、商务等）
   - 选择对应配色方案

3. **规划页面数量**
   - 根据章节结构规划，建议10-20页
   - 分页原则：
     - 封面页: 1页
     - 目录/概览: 0-1页
     - 每个主要章节: 2-4页
     - 数据/图表页: 按需
     - 总结/结语: 1页

### Phase 2: 创建目录结构

在大纲文件所在目录创建：
```bash
mkdir -p ./slides ./css ./js
```

目录结构：
```
{项目目录}/
├── index.html          # 主入口（iframe模式）
├── css/style.css       # 统一样式
├── js/main.js          # 控制脚本
└── slides/
    ├── 01-cover.md     # 页面规划文档
    ├── 01-cover.html   # 页面HTML
    └── ...
```

### Phase 3: 为每页生成规划文档

为每页创建 `slides/NN-name.md`，包含：

```markdown
# {页面标题}页规划

## 展示内容
- **页面标题**: xxx
- **副标题**: xxx（可选）

### 主要内容
- 要点列表
- 数据/引用/金句

## 版面布局
- 布局方式描述
- 重点元素位置

## 字体规划
- 页面标题: {大小}px
- 正文: {大小}px

## 动效
- 进入动画类型
```

### Phase 4: 生成CSS样式

创建 `css/style.css`，必须包含：

**CSS变量（根据主题设置）**
```css
:root {
  --primary: {主色};
  --primary-dark: {主色深};
  --secondary: {辅色};
  --accent: {强调色};
  --accent-light: {强调色浅};
}
```

**核心样式要求**
- 16:9比例容器，`overflow: hidden`
- 响应式字体使用 `clamp(min, preferred, max)`
- 卡片/表格/列表通用样式
- 动画关键帧：fadeIn, slideInLeft, slideInRight, slideInUp, scaleIn
- 延迟类：.delay-1 到 .delay-8

### Phase 5: 生成JS控制脚本

创建 `js/main.js`，必须实现：

```javascript
class SlideController {
  constructor() {
    this.totalSlides = N; // 总页数
    this.currentSlide = 1;
    this.init();
  }

  init() {
    this.bindKeyboard();  // ←→翻页，F全屏，Home/End首末页
    this.bindNavigation(); // 按钮点击
    this.bindTouch();      // 触摸滑动
  }

  goToSlide(num) {
    // 更新iframe src + 过渡动画
  }

  toggleFullscreen() {
    // 全屏切换
  }
}
```

**翻页映射表**
```javascript
const slideNames = ['', '01-cover', '02-xxx', ...];
```

### Phase 6: 生成HTML文件

**index.html 主入口**
```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <title>{演示标题}</title>
  <style>/* 容器+导航样式 */</style>
</head>
<body>
  <div class="presentation-container">
    <iframe id="slideFrame" src="slides/01-cover.html"></iframe>
    <div class="page-info"><span id="pageIndicator">1 / N</span></div>
    <div class="nav-controls">
      <button id="prevBtn">◀</button>
      <button id="nextBtn">▶</button>
      <button id="fullscreenBtn">⛶</button>
    </div>
  </div>
  <script src="js/main.js"></script>
</body>
</html>
```

**子页面 slides/NN-name.html**
```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <title>{页面标题}</title>
  <link rel="stylesheet" href="../css/style.css">
  <style>/* 页面特定样式 */</style>
</head>
<body>
  <div class="slide">
    <!-- 页面内容 -->
    <div class="page-indicator">N / 总页数</div>
  </div>
</body>
</html>
```

---

## 设计规范

### 字体大小（基于1920x1080）

| 元素类型 | clamp()值 |
|---------|-----------|
| 主标题 | clamp(36px, 5vw, 72px) |
| 页面标题 | clamp(28px, 4vw, 48px) |
| 副标题 | clamp(18px, 2.5vw, 32px) |
| 正文 | clamp(14px, 1.5vw, 24px) |
| 备注 | clamp(10px, 1vw, 16px) |

### 内容密度

- 每页文字 ≤ 100字
- 每页要点 ≤ 5条
- 表格 ≤ 6行×5列
- 图表数据点 ≤ 8个

### 动画原则

- 入场动画: 0.3-0.8秒
- 延迟递增: 0.1-0.15秒/元素
- 避免过度动画

### 页面类型

1. **封面页**: 大标题居中 + 副标题 + 日期/地点
2. **内容页**: 左右分栏或网格布局
3. **数据页**: 表格(斑马纹) + 图表(进度条/柱状图)
4. **引言页**: 大字引言居中 + 作者
5. **列表页**: 2-4列网格卡片
6. **总结页**: 核心观点 + 数据来源

---

## 完成后输出

```markdown
## 幻灯片已创建完成

### 文件结构
{目录树}

### 操作说明
| 功能 | 操作 |
|------|------|
| 翻页 | ← → 或点击按钮 |
| 全屏 | F键 |
| 首末页 | Home / End |

### 使用方法
\`\`\`bash
open {index.html路径}
\`\`\`

### 设计说明
- 配色: {主题说明}
- 页数: {N}页
```

---

## 质量检查

- [ ] 所有页面16:9比例，无滚动条
- [ ] 字体不小于14px
- [ ] 配色一致，不超过4种主色
- [ ] 每页有页码指示
- [ ] 键盘翻页正常
- [ ] 全屏功能正常
- [ ] 动画流畅
- [ ] 内容无溢出

---

详细模板参考: [templates.md](templates.md)
