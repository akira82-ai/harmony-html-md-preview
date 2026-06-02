# harmony-html-md-preview

一个 HarmonyOS 文件预览应用，用于预览 HTML 和 Markdown 文件。支持从其他应用通过系统分享接收文件，也可使用内置测试文件进行本地预览。

## 功能特性

- **HTML 预览**：通过 Web 组件渲染 HTML 内容，支持复杂页面（表格、表单、动画等）
- **Markdown 预览**：内置 JS 解析器，支持标题、粗体/斜体、代码块、表格、引用、列表等常用语法
- **分享接收**：注册为系统分享目标，可直接从其他应用接收并预览 HTML/Markdown 文件
- **内置测试文件**：包含 7 个示例文件（4 个 HTML + 3 个 Markdown），可本地测试

## 项目结构

```
harmony-html-md-preview/
├── AppScope/                          # 应用级配置
├── entry/                             # 主模块（HAP）
│   ├── src/main/
│   │   ├── module.json5               # 模块配置（权限、Ability、Share 技能）
│   │   ├── ets/
│   │   │   ├── entryability/          # UIAbility - 接收分享数据
│   │   │   │   └── EntryAbility.ets
│   │   │   ├── pages/
│   │   │   │   ├── Index.ets          # 主页（路由分发 + 测试文件入口）
│   │   │   │   ├── HtmlViewer.ets     # HTML 预览页
│   │   │   │   └── MarkdownViewer.ets # Markdown 预览页
│   │   │   └── utils/
│   │   │       └── FileUtils.ets      # 文件读取 & 类型判断工具
│   │   └── resources/rawfile/
│   │       ├── markdown.html          # 自定义 JS Markdown 解析器
│   │       ├── *.html (4个)           # 测试用 HTML 文件
│   │       └── *.md (3个)             # 测试用 Markdown 文件
│   └── build-profile.json5
└── hvigor/                            # 构建系统配置
```

## 核心数据流

```
其他应用分享文件
       ↓
EntryAbility (systemShare.getSharedData)
       ↓
AppStorage (setOrCreate: URI, UTD, hasSharedData)
       ↓
Index 页面 (@StorageLink + @Watch 感知变化)
       ↓
FileUtils (读取文件内容 + 判断类型)
       ↓
  ┌────────────────┬──────────────────┐
  ↓                ↓
HtmlViewer       MarkdownViewer
(base64 Data URL   (加载 markdown.html
 渲染 Web 组件)    + runJavaScript 注入)
```

## 技术实现

| 特性 | 实现方式 |
|------|---------|
| 接收分享 | `module.json5` 声明 `entity.system.share`，支持 `file://` URI 和 `general.text` / `general.html` UTD |
| HTML 渲染 | 内容 base64 编码 → `data:text/html;base64,...` → Web 组件加载 |
| Markdown 渲染 | 加载 `markdown.html` 模板 → `runJavaScript()` 注入内容调用 `renderMarkdown()` |
| 状态管理 | `AppStorage` + `@StorageLink` 桥接 Ability 层与 UI 层 |
| 文件 I/O | `@kit.CoreFileKit` 同步读取，支持扩展名 + UTD 双重类型判断 |
| 外部依赖 | 零依赖，Markdown 解析器为纯 JS 手写实现 |

## 内置测试文件

### HTML 测试文件
| 文件              | 说明 |
|-----------------|------|
| `simple.html`   | 基础 HTML 格式，包含列表、链接、图片 |
| `rich.html`     | 复杂内容，包含表格、嵌套列表、表单、代码块、多媒体 |
| `chinese.html`  | 中文编码测试，繁简混排、多语言、Emoji |
| `html-ppt.html` | 桌面宠物动画页面，测试复杂 CSS/WebGL 渲染 |

### Markdown 测试文件
| 文件 | 说明 |
|------|------|
| `basic.md` | 基础语法：各级标题、文本格式、链接、列表、引用、图片 |
| `advanced.md` | 进阶语法：代码块、表格、数学公式、脚注 |
| `mixed.md` | 中英混排项目文档，含代码示例和任务列表 |

## 使用方式

1. **本地测试**：启动应用后，主页展示内置测试文件列表，点击即可预览对应内容
2. **分享预览**：在其他应用中选择 HTML 或 Markdown 文件 → 分享 → 选择本应用，即可自动识别并渲染

## 环境要求

- HarmonyOS SDK（API 12+）
- DevEco Studio

## License

MIT
