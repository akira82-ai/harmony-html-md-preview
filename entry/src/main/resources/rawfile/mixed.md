# 中英文混合实际场景测试

## 项目介绍

这是一个基于 **HarmonyOS** 开发的文件查看器应用，支持 HTML 和 Markdown 文件的渲染和显示。

### 主要功能

1. **文件类型识别** - 自动识别 HTML 和 Markdown 文件
2. **内容渲染** - 使用原生组件渲染文件内容
3. **分享支持** - 支持从其他应用分享文件打开
4. **错误处理** - 完善的错误提示和处理机制

## 技术栈

### 前端技术

- **ArkTS** - HarmonyOS 的声明式 UI 开发语言
- **ArkUI** - HarmonyOS 的 UI 组件库
- **TypeScript** - 类型安全的 JavaScript 超集

### 系统能力

- **FileIO** - 文件读写能力
- **Want** - 应用间数据分享
- **Web** - HTML 内容渲染
- **RichText** - Markdown 内容渲染

## 代码示例

### 文件读取示例

```typescript
import { fileIo as fs } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';

async function readFile(uri: string): Promise<string> {
    // 打开文件
    const file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
    
    // 读取内容
    const stat = fs.statSync(file.fd);
    const buffer = new ArrayBuffer(stat.size);
    fs.readSync(file.fd, buffer);
    
    // 关闭文件
    fs.closeSync(file);
    
    // 转换为字符串
    const decoder = util.TextDecoder.create('utf-8');
    return decoder.decodeToString(new Uint8Array(buffer));
}
```

### 文件类型判断示例

```typescript
export enum FileType {
    HTML = 'html',
    MARKDOWN = 'markdown',
    UNKNOWN = 'unknown'
}

function getFileType(fileName: string): FileType {
    const ext = fileName.split('.').pop()?.toLowerCase();
    
    if (ext === 'html' || ext === 'htm') {
        return FileType.HTML;
    }
    
    if (ext === 'md' || ext === 'markdown') {
        return FileType.MARKDOWN;
    }
    
    return FileType.UNKNOWN;
}
```

## 使用说明

### 如何打开文件

1. 从文件管理器选择文件
2. 选择"分享"功能
3. 选择本应用打开
4. 自动识别并渲染文件内容

### 支持的文件格式

| 格式 | 扩展名 | 渲染方式 |
|------|--------|----------|
| HTML | .html, .htm | Web 组件 |
| Markdown | .md, .markdown | RichText 组件 |

## 开发笔记

### 遇到的问题和解决方案

**问题 1：中文乱码**

解决方案：使用 UTF-8 编码读取文件

```typescript
const decoder = util.TextDecoder.create('utf-8');
const content = decoder.decodeToString(new Uint8Array(buffer));
```

**问题 2：文件路径处理**

解决方案：正确处理 URI 和文件路径

```typescript
// 移除查询参数
let cleanUri = uri;
const queryIndex = uri.indexOf('?');
if (queryIndex > 0) {
    cleanUri = uri.substring(0, queryIndex);
}
```

**问题 3：类型识别不准确**

解决方案：结合文件扩展名和 UTD 类型双重判断

```typescript
function determineFileType(uri: string, utd: string): FileType {
    // 先尝试扩展名
    let fileType = getFileType(uri);
    if (fileType !== FileType.UNKNOWN) {
        return fileType;
    }
    
    // 再尝试 UTD
    if (utd.includes('html')) {
        return FileType.HTML;
    }
    
    return FileType.UNKNOWN;
}
```

## 性能优化建议

1. **懒加载** - 大文件分块加载
2. **缓存** - 缓存已读取的文件内容
3. **预加载** - 预加载常用资源
4. **内存管理** - 及时释放不用的资源

## 测试建议

### 单元测试

- 测试文件类型识别功能
- 测试文件扩展名提取
- 测试文件名处理逻辑

### 集成测试

- 测试文件打开流程
- 测试分享功能
- 测试错误处理

### UI 测试

- 测试页面渲染效果
- 测试用户交互
- 测试边界情况

## 未来规划

- [ ] 支持更多文件格式（PDF、Word 等）
- [ ] 添加文件编辑功能
- [ ] 支持文件收藏和历史记录
- [ ] 添加主题切换功能
- [ ] 支持多语言

---

**注意：** 这是一个测试文档，用于验证 Markdown 渲染功能。

*最后更新：2026-06-01*
