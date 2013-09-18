# 1. Rails Engine

__特別要強調的翻譯名詞__

> Web application ＝ Web 應用程式 ＝ 應用程式。

> host application ＝ 宿主。

--

本篇介紹 「Rails Engine」。怎麼優雅地把 Engine 掛到應用程式裡。

讀完本篇可能會學到：

  * 什麼是 Engine。

  * 如何產生 Engine。

  * 怎麼給 Engine 加功能。

  * 怎麼讓 Engine 與應用程式結合。

  * 在 application 裡覆寫 Engine 的功能。


# 1. What are engines?

Engine 可以想成小型的應用程式，可以給你的 web 應用程式（宿主）加新功能。`Rails::Application` 也是繼承自 `Rails::Engine`，Rails 其實只是個超強大的 Engine。

可以把 Engine 跟應用程式想成是一樣的東西，只不過有點微妙的差別。

Rails 還有 plugin，這跟 Engine 很像。兩者都有 `lib` 目錄結構，皆采用 `rails plugin new` 產生器。但還是不太一樣，Engine 可以想成是“完整的 plugin” （用產生器產生時要加上 `--full` 選項）。

接下來會用一個 “blorgh” 的 Engine 例子來講解。這個 “blorgh” 給宿主提供了新增 post、新增 comments 等功能。開始會先開發 Engine，接著再與應用程式結合。

假設路由裡有 `posts_path` 這個 routing helper，宿主會提供這個功能、Engine 也會提供，這兩者並不衝突。也就是說 Engine 可從宿主抽離出來。

__記住！宿主的優先權最高，Engine 不過給宿主提供新功能。__

有幾個 Rails Engine 的例子：

[Devise](https://github.com/plataformatec/devise) 提供使用者驗證功能。

[Forem](https://github.com/radar/forem) 提供論壇功能。

[Spree](https://github.com/spree/spree) 提供電子商務平台。

[RefineryCMS](https://github.com/refinery/refinerycms) 內容管理系統。

感謝 James Adam、Piotr Sarnacki、Rails 核心成員及無數人員的辛苦努力，沒有他們就沒有 Rails Engine！


# 2. 產生 Engine

用 plugin 產生器來產生 Engine（加上 `--mountable` 選項）：

```bash
$ rails plugin new blorgh --mountable
```

完整選項輸入 `--help` 查看：

```bash
$ rails plugin --help
```

# 延伸閱讀

* [Rails Engines by Ryan Bigg](https://github.com/radar/guides/blob/master/engines.md)

用很短的篇幅介紹了 Rails Engine，值得一讀。

* [#277 Mountable Engines - RailsCasts](http://railscasts.com/episodes/277-mountable-engines)

3.1.0.rc5 初次介紹 Engines 所做的影片教學。

* [Start Your Engines by Ryan Bigg at Ruby on Ales 2012 - YouTube](http://www.youtube.com/watch?v=bHKZfIeAbds)

* [Rails Conf 2013 Creating Mountable Engines by Patrick Peak](http://www.youtube.com/watch?v=s3NJ15Svq8U)

* Rails in Actions 4 | Chapter 17 Rails Engine
