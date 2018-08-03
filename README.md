# VVTool

[![Gem](https://img.shields.io/gem/v/vvtool.svg)](https://rubygems.org/gems/vvtool)

这是一个加速开发 Virtual View 模版的小脚本，让你能脱离繁重的开发环境 Xcode 和 Android Studio，只需一个轻量级的文本编辑器如 VSCode/Atom/SublimeText 即可开始进入开发，并且提供热加载能力，大大加速提高开发调试效率。

![screen_record.gif](https://raw.githubusercontent.com/alibaba/virtualview_tools/master/compiler-tools/RealtimePreview/screenshot.gif) 

## 安装

本工具由 Ruby 所写，你可以通过 Ruby 的包管理工具 `gem` 来安装：

```ruby
gem install vvtool
```

> 因为 VV 模版的编译器需要 Java 环境，所以另外需要 java 环境支持。
>
> 如果安装很慢或者超时，可以尝试切换下 RubyGems 源：https://gems.ruby-china.org/

[![asciicast](https://asciinema.org/a/rtmYrXUexTG67RNpuGfGdvvGQ.png)](https://asciinema.org/a/rtmYrXUexTG67RNpuGfGdvvGQ)

## 运行

切换到你的模版列表目录，然后执行如下命令即可：

```ruby
vvtool run
```

## Playground

若需要脱离 iOS/Android 开发环境开发 VV，则需要安装对应客户端到真机或模拟器进行预览、调试、开发。

- [iOS Playground](https://github.com/alibaba/VirtualView-iOS)
- [Android Playground](https://github.com/alibaba/Virtualview-Android)

> 模拟器：通过 127.0.0.1 访问本机 vvtool 服务
> 
> 真机：通过扫描模版对应二维码来访问
>
> 需要运行 VVTool 的机器和对应 Playground 设备都在同一网段；

## 模版目录结构

```
.
└── helloworld
  ├── helloworld.json   (该模版所需参数)
  ├── helloworld.out    (该模版编译后的二进制)
  ├── helloworld.xml    (该模版源文件)
  └── helloworld_QR.png (该模版 URL 供于扫码加载)
└── helloworld1
...
```

你自己需要维持这样一份模版目录结构，才能让服务正确对接到客户端 Playground，其中有几点需要注意：

1. 每个模版必须按独立文件夹区分（可以含有子模版）
2. 模版中的 xml/json 文件名必须和目录名一致 （子模版除外）

## 二维码扫描

每个模版目录下会生成类似 `xx_QR.png` 的二维码图片，指向当前模版对应的本地HTTP 地址，如 *http://127.0.0.1:7788/helloworld/data.json* ，对应 iOS/Android Playground 应用可通过二维码扫描读取该路径中的模版和数据，然后在客户端加载。

## 原理

![source](https://i.loli.net/2018/08/02/5b630f232a97e.png)

> 编译工具依赖 [alibaba/virtualview_tools](https://github.com/alibaba/virtualview_tools)
