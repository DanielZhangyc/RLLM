#!/bin/bash

# 检查BartyCrouch是否安装
if ! which bartycrouch > /dev/null; then
    echo "错误: BartyCrouch未安装"
    echo "请运行: brew install bartycrouch"
    exit 1
fi

# 检查SwiftGen是否安装
if ! which swiftgen > /dev/null; then
    echo "错误: SwiftGen未安装"
    echo "请运行: brew install swiftgen"
    exit 1
fi

echo "开始更新本地化文件..."

# 运行BartyCrouch
echo "运行BartyCrouch..."
if ! bartycrouch update -x; then
    echo "错误: BartyCrouch更新失败"
    exit 1
fi

if ! bartycrouch lint -x; then
    echo "警告: BartyCrouch检查发现问题"
    # 不退出,因为lint错误可能不影响功能
fi

# 运行SwiftGen
echo "运行SwiftGen..."
if ! swiftgen; then
    echo "错误: SwiftGen生成失败"
    exit 1
fi

echo "本地化处理完成!" 