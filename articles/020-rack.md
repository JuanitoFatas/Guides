# [Rack](http://rack.github.io)

```
 －－－－－
｜Browser｜ <= User, Request goes in the form of HTTP protocol.
 －－－－－
｜Server ｜ <= Web Server，Give you the Response back.
 －－－－－
｜Rack   ｜ <= Your middle man between server and app, so called Middleware.
 －－－－－
｜Rails  ｜ <= Rails application stack.
 －－－－－
```

# Simplest Rack application

__Response ＝ [Status, Header, Body]__

> Status: Integer <br>
> Header: Hash <br>
> Body:   Array <br>

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

* [Rack Wiki](https://github.com/rack/rack/wiki)

* [Exploring Rack | Nettuts+](http://net.tutsplus.com/tutorials/exploring-rack/)

* [Creating Static Sites in Ruby with Rack | Heroku Dev Center](https://devcenter.heroku.com/articles/static-sites-ruby)

* [Creating Static Sites in Ruby with Rack](http://kmikael.com/2013/05/28/creating-static-sites-in-ruby-with-rack/)
