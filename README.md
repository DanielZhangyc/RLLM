<div align="center">

<img src="icon.png" alt="RLLM Icon" width="200"/>

# RLLM

🌟 A LLM-Powered RSS Reader

<a href="https://rllm.xy0v0.top" target="_blank">🌐 Project Homepage</a>

[English](README.md) | [中文](README_CN.md)

[![GitHub stars](https://img.shields.io/github/stars/DanielZhangyc/RLLM.svg?style=social)](https://github.com/DanielZhangyc/RLLM/stargazers)
[![Build Status](https://github.com/DanielZhangyc/RLLM/actions/workflows/swift.yml/badge.svg)](https://github.com/DanielZhangyc/RLLM/actions/workflows/swift.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS-lightgrey.svg)](https://www.apple.com/ios/)

</div>

# 📖 RLLM - LLM-Powered RSS Reader

RLLM is an innovative RSS reader powered by Large Language Models (LLM), providing intelligent content analysis and summarization capabilities.

- [Features](#features)
- [Screenshots](#screenshots)
- [Installation](#installation)
- [Development](#development)
- [Contributing](#contributing)
- [FAQ](#faq)
- [License](#license)

<a id="features"></a>
## ✨ Features

### RSS Reading
- ✅ Support for RSS 1.0, 2.0 and Atom feeds
- ✅ Article/Quote Reading and Collection

### AI Features
- ✅ AI Article Summary Generation
- ✅ AI Article Insight Analysis
- ✅ Daily Reading AI Summary
- ✅ Integrated with Anthropic, Deepseek and OpenAI

### TODO
- 📝 Enhanced Collection Management
- 📝 Collection AI Summary
- 📝 Recent Reading Analysis
- 📝 Recent Reading Trends/Tags
- 📝 English Language Support

<a id="screenshots"></a>
## 📱 Screenshots

<div align="center">
<img src="https://github.com/DanielZhangyc/RLLM/blob/main/Screenshots/screenshot1.png?raw=true" alt="Home" width="180"/>
<img src="https://github.com/DanielZhangyc/RLLM/blob/main/Screenshots/screenshot2.png?raw=true" alt="AI Insights" width="180"/>
<img src="https://github.com/DanielZhangyc/RLLM/blob/main/Screenshots/screenshot3.png?raw=true" alt="Quote Collection" width="180"/>
<img src="https://github.com/DanielZhangyc/RLLM/blob/main/Screenshots/screenshot4.png?raw=true" alt="Daily Summary" width="180"/>
</div>

<a id="installation"></a>
## 📥 Installation

### Option 1: Build from Source Code

See [Development](#development) section for detailed instructions on building from source code.

### Option 2: Install from IPA File

1. Download the latest unsigned IPA file from [GitHub Actions](https://github.com/DanielZhangyc/RLLM/actions) (Latest successful build)
2. Sign and install the IPA file using one of these methods:

   #### Using Signing Tools
   - [AltStore](https://altstore.io) - Popular sideloading tool with automatic resigning
   - [Sideloadly](https://sideloadly.io) - Cross-platform sideloading tool
   - [ESign](https://esign.yyyue.xyz) - On-device signing tool
   
   #### Using TrollStore (No Signing Required)
   - [TrollStore](https://github.com/opa334/TrollStore) - Permanent app installation for iOS 14.0-15.4.1, 15.5beta4, and 16.0-16.6.1
   
   #### Using Other Methods
   - [Scarlet](https://usescarlet.com) - On-device app installer
   - Your Apple Developer account and Xcode
   - Enterprise certificate (if you have access)

Note: The IPA file is unsigned and requires signing before it can be installed on your device, except when using TrollStore on supported iOS versions.

<a id="development"></a>
## 👨‍💻 Development

### Prerequisites

- Xcode 15.0+
- iOS 17.0+
- Swift 5.0+

### Dependencies

- [FeedKit](https://github.com/nmdias/FeedKit) - RSS and Atom feed parser
- [Alamofire](https://github.com/Alamofire/Alamofire) - HTTP networking library

### Getting Started

1. Clone the repository
```bash
git clone https://github.com/DanielZhangyc/RLLM.git
cd RLLM
```

2. Open the project in Xcode
```bash
open RLLM.xcodeproj
```

3. Build and run the project in Xcode

<a id="contributing"></a>
## 🤝 Contributing

We welcome contributions! Here's how you can help:

1. Fork the repository
2. Create a new branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Commit your changes (`git commit -m 'Write something here'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

Need help? Feel free to:
- Open an issue
- Start a discussion

<a id="faq"></a>
## ❓ FAQ

### What's the origin of the name RLLM?
RLLM is a combination of "RSS" and "LLM", representing our goal of enhancing the RSS reading experience with AI capabilities.

### Do I need to provide my own API keys?
Yes, you need to provide your own API keys for the LLM services you want to use. These can be configured in the app settings.

<a id="license"></a>
## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
