# `alias_method` v.s. `alias`

`alias_method` __可重定義__。

`alias` 根據 scope 的不同，會產生不同行為， __難以預期__。

__結論：用 `alias_method` 即可。__

```ruby
def foo
  'foo'
end

alias_method :bar, :foo
# alias :bar :foo
```

## 了解更多

https://gist.github.com/ddl1st/6104625

[alias alias_method - Google 搜索 on Ruby China](https://www.google.com.hk/#hl=zh-CN&q=site:ruby-china.org+alias%20alias_method)