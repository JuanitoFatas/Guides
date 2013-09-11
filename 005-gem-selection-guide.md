# Gem 挑選指南

## 三個指標

### 活躍程度

### 可靠性

### 人氣

## 活躍程度

* 最後 Commit 的日期

看看這個專案是不是死掉了。

* Release 時間間隔

看這個專案是不是有固定的 release 週期。

可至

## 可靠性

* 上 [Ruby Toolbox][rt] 網站看綜合分析。

* 看看有多少行測試代碼。

測試代碼越多越可靠。

* 看看 Open / Closed 的 Issue

Closed 多，Open 少，代表維護者很積極的在解決使用上的問題。（你碰到 bug 他們會不會理你。）

* 總 commit 數量

commit 數量已經到達數百次？如果這個專案有使用 .travis，那 Commit 次數便更可靠。

.travis 檢查每次 commit 是否通過，間接提高了每次 commit 的質量。

* 直接問用過的朋友

通常他們會告訴你，關於這個問題，採用哪個 Gem，通常他們也會把類似的 Gem 都調查過一遍。

## 人氣

* GitHub Stars 與 Forks 數量

Stars，多少人認為這個專案很棒並加了個星。

Forks，多少人實際貢獻到這個專案？

* Google 搜尋看看條目多不多、文章多不多。

記得加上輔助的關鍵字如：rails, ruby：

HTTParty ruby

* 貢獻者

看看貢獻者有幾人？

* 下載次數

上 [RubyGems.org](https://rubygems.org/) 看看總下載量有多少。

[rt]: https://www.ruby-toolbox.com/