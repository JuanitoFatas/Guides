# [Rack](http://rack.github.io)

```
 －－－－
｜     ｜ <= Web Server，Give you Response.
 －－－－
｜     ｜ <= Your middle man between server, we called it Middleware.
 －－－－
｜     ｜ <= User，Your Request goes in form of HTTP protocol.
 －－－－
```

Response ＝ [Status, Header, Body]

> Status: Integer
> Header: Hash
> Body:   Array

```ruby
# Typical Response
[ 200, {"Content-Type" => "text/plain"}, ["Hello world!"] ]
```

可以用一句話總結：

> Rack 是回應 `#call` 方法的 Ruby object，接受一個 hash 參數，將 status, header, body 以 Array 的形式返回。

## `rackup` and `config.ru`

`config.ru` 是 Rack 的設定檔。`rackup` 會讀取 `config.ru`，並啟動伺服器。

## Web Frameworks built on Rack?

Sinatra、Ruby on Rails、幾乎所有用 Ruby 寫成的 web framework，都采用 Rack 作為 Middleware。

# 延伸閱讀

https://github.com/rack/rack/wiki

* [Creating Static Sites in Ruby with Rack | Heroku Dev Center](https://devcenter.heroku.com/articles/static-sites-ruby)

* [Creating Static Sites in Ruby with Rack](http://kmikael.com/2013/05/28/creating-static-sites-in-ruby-with-rack/)

* [Exploring Rack | Nettuts+](http://net.tutsplus.com/tutorials/exploring-rack/)

[Build your own web framework with Rack and Ruby - Part 1 – Blog – isotope|eleven](http://isotope11.com/blog/build-your-own-web-framework-with-rack-and-ruby-part-1) No part 2.