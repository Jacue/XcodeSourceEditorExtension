# XcodeSourceEditorExtension文本编辑插件

标签（空格分隔）： Xcode、插件

---

XcodeSourceEditorExtension是Xcode 8之后推出的一款用以扩展现有的源代码的编辑功能，extensions只能和源代码交互，没有UI交互。这意味着它的功能有很大的局限性，但用好文本编辑功能，还是能给我么你的开发带来不少的便利。以下是我在Demo中用到的几个编辑功能（逻辑并不十分严谨，这意味着使用者在使用这个插件的时候，得保证代码一定的清洁，不过这不是重点，本文权当抛砖引玉）。

>* 字符串Base64加密
>* 将Unicode字符串转变为中文
>* 文本对齐（如按照“//”、“=”、“@”、“*”等字符对齐，也可以多个组合）
>* 根据属性生成对应的懒加载getter方法

值得一提的是，在使用文本对齐的多个条件组合使，Demo中使用了链式语法，更加方便扩展和控制对齐逻辑的优先顺序。

```
self.alignedByAt().alignedByStar().alignedByEqual().alignedByAnnotations();
```

当然，在文本编辑的使用上，我们可以根据自己的需要给插件添加不少的小功能，有兴趣的可以参考这个Demo中的内容。


