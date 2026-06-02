# 高级 Markdown 测试

## 代码块测试

### 行内代码

使用 `console.log()` 进行调试。

### 代码块（无语法高亮）

```
function fibonacci(n) {
    if (n <= 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

console.log(fibonacci(10)); // 输出: 55
```

### 代码块（JavaScript）

```javascript
// 异步函数示例
async function fetchData(url) {
    try {
        const response = await fetch(url);
        const data = await response.json();
        return data;
    } catch (error) {
        console.error('Error:', error);
        throw error;
    }
}

// 使用示例
fetchData('https://api.example.com/data')
    .then(data => console.log(data))
    .catch(err => console.error(err));
```

### 代码块（Python）

```python
# 类定义示例
class Calculator:
    def __init__(self):
        self.result = 0
    
    def add(self, x, y):
        self.result = x + y
        return self.result
    
    def multiply(self, x, y):
        self.result = x * y
        return self.result

# 使用示例
calc = Calculator()
print(calc.add(5, 3))      # 输出: 8
print(calc.multiply(4, 6)) # 输出: 24
```

### 代码块（ArkTS）

```typescript
// HarmonyOS ArkTS 组件示例
@Component
struct MyComponent {
    @State count: number = 0;
    
    build() {
        Column() {
            Text(`Count: ${this.count}`)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
            
            Button('Increment')
                .onClick(() => {
                    this.count++;
                })
                .margin({ top: 10 })
        }
        .padding(20)
    }
}
```

## 表格测试

### 简单表格

| 姓名 | 年龄 | 城市 |
|------|------|------|
| 张三 | 28   | 北京 |
| 李四 | 32   | 上海 |
| 王五 | 25   | 深圳 |

### 对齐表格

| 左对齐 | 居中对齐 | 右对齐 |
|:--------|:----------:|---------:|
| 内容 1 | 内容 2   | 内容 3 |
| 数据 A | 数据 B   | 数据 C |
| 项目 X | 项目 Y   | 项目 Z |

### 复杂表格

| 功能 | 描述 | 状态 | 优先级 |
|------|------|:----:|:-------:|
| 用户登录 | 实现邮箱和密码登录 | ✅ | 高 |
| 数据同步 | 支持云端数据同步 | 🔄 | 中 |
| 主题切换 | 支持明暗主题切换 | ✅ | 低 |
| 多语言 | 支持中英文切换 | ⏳ | 中 |

## 数学公式测试（如果支持）

行内公式：$E = mc^2$

块级公式：

$$
\sum_{i=1}^{n} x_i = x_1 + x_2 + \cdots + x_n
$$

## 脚注测试

这是一个带有脚注的文本[^1]。

这是另一个脚注示例[^2]。

[^1]: 这是第一个脚注的内容。
[^2]: 这是第二个脚注的内容，可以包含多行文本。

## 定义列表测试（HTML 方式）

<dl>
    <dt>Markdown</dt>
    <dd>一种轻量级标记语言，用于格式化文本。</dd>
    
    <dt>HTML</dt>
    <dd>超文本标记语言，用于创建网页。</dd>
    
    <dt>CSS</dt>
    <dd>层叠样式表，用于描述文档的呈现。</dd>
</dl>

## 缩写测试

*[HTML]: Hyper Text Markup Language
*[CSS]: Cascading Style Sheets
*[API]: Application Programming Interface

HTML 和 CSS 是前端开发的基础。API 用于应用程序之间的通信。

## 高级引用

> **注意：** 这是一个重要的提示框。
> 
> - 第一点
> - 第二点
> - 第三点

> **警告：** ⚠️ 请谨慎操作！
> 
> 此操作不可撤销。

## 组合测试

**粗体中的*斜体*和`代码`**

*斜体中的**粗体**和~~删除线~~*

`代码中的**粗体**不生效`
