<div align="center">

<img src="icon.png" alt="RLLM 图标" width="200"/>

# RLLM

🌟 由 LLM 驱动的 RSS 阅读器

[English](README.md) | [中文](README_CN.md)

[![GitHub stars](https://img.shields.io/github/stars/DanielZhangyc/RLLM.svg?style=social)](https://github.com/DanielZhangyc/RLLM/stargazers)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS-lightgrey.svg)](https://www.apple.com/ios/)

</div>

# 📖 RLLM - LLM 驱动的 RSS 阅读器

RLLM 是一个由大语言模型驱动的创新型 RSS 阅读器，提供智能内容分析和摘要功能。

- [功能特性](#功能特性)
- [应用截图](#应用截图)
- [安装方式](#安装方式)
- [开发](#开发)
- [参与贡献](#参与贡献)
- [FAQ](#FAQ)
- [开源协议](#开源协议)

<a id="功能特性"></a>
## ✨ 功能特性

### RSS 阅读
- ✅ 支持 RSS 1.0、2.0 和 Atom 订阅源
- ✅ 文章/语段阅读与收藏

### AI 功能
- ✅ AI 文章摘要生成
- ✅ AI 文章洞察分析
- ✅ 每日阅读 AI 总结
- ✅ 集成 Anthropic、Deepseek 和 OpenAI

### TODO
- 📝 完善收藏管理
- 📝 收藏 AI 总结
- 📝 近期阅读分析
- 📝 近期阅读趋势/标签
- 📝 添加英语支持

<a id="应用截图"></a>
## 📱 应用截图

<div align="center">
<img src="https://github.com/DanielZhangyc/RLLM/blob/main/Screenshots/1.PNG?raw=true" alt="AI 洞察" width="250"/>
<img src="https://github.com/DanielZhangyc/RLLM/blob/main/Screenshots/2.PNG?raw=true" alt="语段收藏" width="250"/>
<img src="https://github.com/DanielZhangyc/RLLM/blob/main/Screenshots/3.PNG?raw=true" alt="每日总结" width="250"/>
</div>

<a id="安装方式"></a>
## 📥 安装方式

自行编译安装

<a id="开发"></a>
## 👨‍💻 开发

### 环境要求

- Xcode 15.0+
- iOS 17.0+
- Swift 5.0+

### 依赖库

- [FeedKit](https://github.com/nmdias/FeedKit) - RSS 和 Atom 订阅源解析器
- [Alamofire](https://github.com/Alamofire/Alamofire) - HTTP 网络请求库

### 开始开发

1. 克隆仓库
```bash
git clone https://github.com/DanielZhangyc/RLLM.git
cd RLLM
```

2. 在 Xcode 中打开项目
```bash
open RLLM.xcodeproj
```

3. 在 Xcode 中构建和运行项目

<a id="参与贡献"></a>
## 🤝 参与贡献

欢迎你的PR :) 

1. Fork 本仓库
2. 创建新分支 (`git checkout -b feature/amazing-feature`)
3. 提交修改
4. 提交代码 (`git commit -m 'Write something here'`)
5. 推送到分支 (`git push origin feature/amazing-feature`)
6. 提交 Pull Request

需要帮助？欢迎：
- 提交 Issue
- 发起讨论

<a id="FAQ"></a>
## ❓ FAQ

### RLLM 这个名字怎么来的？

RLLM = RSS + LLM，代表软件希望使用 LLM 的能力来增强 RSS 阅读体验。

### 需要自己提供 API 密钥吗？

是的，您需要为想要使用的 LLM 服务提供自己的 API 密钥。这些可以在应用的设置中配置。

<a id="开源协议"></a>
## 📄 开源协议

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件 