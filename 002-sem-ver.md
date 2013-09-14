# 語義版本簡介

此文粗淺介紹，完整介紹請移步 &rarr; [SemVer 2.0.0 正體中文](https://github.com/wmh/semver.org/blob/d48bd903bde4fb5f202db00a156d98e445db2088/lang/zh-TW/index.md)

## X . Y . Z . [rc | alpha | beta]

Rails 3.2.14

Rails 第 3 個發行版，第 2 個次要版本，第 14 次 小版本更新。

### X 主要版本

Rails 3 升級到 Rails 4，會需要很多心血。

API 不一定向下兼容，較多新功能。

### Y 次要版本

API 兼容，通常是稍微嚴重的 bugfix，或是亮眼的新特色。

從 3.1 升級到 3.2 就有些東西需要注意了。

### Z 補丁更新

修補 bug，一般修補到某個程度才會從 3.2.1 更新到 3.2.2。

## alpha

通常在 1.0.0 之前會出一個 alpha 版本，讓人測試。

## beta

alpha 版本的下個階段便是 beta，繼續測試。

### release candidate

release candidate 即將發行的版本，在下次主要版本釋出前，通常會有個 rc1, rc2, rc3, bata 1, alpha1...etc。

## Gemfile

### `~>`

    gem 'rails', '~> 4.0.0'

當有 4.0.1, 4.0.2 時會升級，不會升級至 4.1.x。

    gem 'rails', '~> 4.0'

當有 4.1, 4.2 時會升級，不會升級至 5.0.x。

### `>=`

    gem 'rails', '>= 4.0'

當有 4.0.1, 4.1.0, 5.0 時都會升級。

## 延伸閱讀

[Railscasts 245, 用 bundler 製作新的 gem](http://railscasts.com/episodes/245-new-gem-with-bundler)

[用 Bundler 做 Gem](http://bundler.io/)

[RubyGems 官方導覽](http://guides.rubygems.org/)

[關於 Semantic Version 的全部知識](http://semver.org/)

[Gem 開發教學 by Ryan Bigg](https://github.com/radar/guides/blob/master/gem-development.md)