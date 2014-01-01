# Engine

2005.10.31， Rails 0.14.2，James Adam 開始開發 "engines" plugin，從 Rails 3.1 正式引入 (2009)。最開始 Engine 屬於 Rails 核心的一部分，後來拆出來以解決相容性問題。Engines 以 RubyGems 的形式發佈。這麼一來，Rails 升級、或是單升級 Engine 本身，便不會有不相容的問題，只要改 Engine 部分的代碼即可。

## Rails < 2.3?

用 https://github.com/lazyatom/engines

## Rails 3 之後

用 `rails plugin new` 產生器。

# Engine 學習資源

Rails conf 2013

http://www.youtube.com/watch?v=s3NJ15Svq8U
https://speakerdeck.com/peakpg/creating-mountable-engines
https://speakerdeck.com/peakpg/mountable-engines-lonestar-ruby-2012
https://speakerdeck.com/peakpg/plays-well-with-others-building-mountable-apps

[Rails Engines (May 2013)](https://speakerdeck.com/christopherhein/rails-engines)

!!!! [Rails Engines - Lessons Learned (by Ryan Bigg in March 2012)](https://speakerdeck.com/radar/rails-engines-lessons-learned)

[Integration Testing Engines // Speaker Deck](https://speakerdeck.com/radar/integration-testing-engines)