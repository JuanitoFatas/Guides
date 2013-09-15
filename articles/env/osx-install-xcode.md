# Mac OSX 安裝 XCode Command Line Tools

## 10.7 / 10.8

### 已安裝 XCode?

打開 XCode，Preference > Downloads > Install Command Line Tools

### 未安裝 XCode?

去申請 Apple ID，到 [Apple 開發者網站][appdev]，找到適合你作業系統版本的 command line tools，下載並安裝。

## 10.6

到 [Apple 開發者網站][appdev]，找到 XCode 並安裝（注意作業系統版本），接著裝這個 [GCC 工具包](https://github.com/downloads/kennethreitz/osx-gcc-installer/GCC-10.6.pkg)。

也可以只裝 GCC 工具包，但有很多軟體都需要安裝 XCode 才能編譯。

以上裝不起來可試試這個 Repo 裡的方法:

[kennethreitz/osx-gcc-installer](https://github.com/kennethreitz/osx-gcc-installer)

[108]: https://github.com/downloads/kennethreitz/osx-gcc-installer/GCC-10.7-v2.pkg
[107]: https://github.com/downloads/kennethreitz/osx-gcc-installer/GCC-10.7-v2.pkg
[appdev]: https://developer.apple.com/downloads/