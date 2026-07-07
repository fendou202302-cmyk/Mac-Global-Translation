# Input Translator Mac

一个 Mac 菜单栏翻译工具。把光标放在任意输入框里，按你设置的全局快捷键，App 会复制当前输入内容，调用 DeepSeek 翻译，然后把结果粘贴回原位置。

## 构建

```bash
cd /Users/apple/Documents/翻译插件/macos/InputTranslatorMac
./build.sh
```

构建后生成：

```text
/Users/apple/Documents/翻译插件/macos/InputTranslatorMac/build/Input Translator.app
```

## 使用

1. 双击打开 `Input Translator.app`
2. 菜单栏会出现“译”
3. 点“译” -> “设置...”
4. 选择大模型服务商
5. 填写对应服务商的 API Key
6. 从下拉框选择目标语言
7. 选择模型
8. 设置全局快捷键，默认是 `Control + Option + T`
9. 在任意 App 的输入框里输入文字
10. 按你设置的快捷键

第一次使用时，macOS 会要求开启辅助功能权限。路径通常是：

系统设置 -> 隐私与安全性 -> 辅助功能 -> 允许 Input Translator

如果已经允许了但仍然提示权限：

1. 打开系统设置 -> 隐私与安全性 -> 辅助功能
2. 删除列表里的旧 `Input Translator`
3. 重新添加当前这个 App：
   `/Users/apple/Documents/翻译插件/macos/InputTranslatorMac/build/Input Translator.app`
4. 退出并重新打开 App

原因是 macOS 会按 App 路径和签名记权限；重新构建后的本地 App 可能会被当成新应用。

## 注意

- 每个服务商的 API Key 会分别存在 macOS Keychain。
- 目前支持 DeepSeek、OpenAI、Anthropic Claude、Google Gemini、通义千问 Qwen、Kimi/Moonshot、OpenRouter、硅基流动。
- 目标语言使用下拉框，内置英文、中文、日文、韩文、法文、德文、西班牙文等主流语言。
- 默认快捷键是 `Control + Option + T`，可以在设置里修改。
- 如果某个快捷键没有反应，可能是被系统或当前 App 占用了，换一个组合即可。
- 这个工具会模拟 `Command + A`、`Command + C`、`Command + V`，更适合在输入框内使用。
