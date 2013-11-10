# Warden 介紹

## Warden 作者

Daniel Neighman

## Warden 是什麼？

> General Rack session management (authentication) Framework

## Warden 如何工作？

Insert a middleware which sets up a Warden proxy object to manage a user's

session. You can then call methods on this proxy object to authenticate a user.

怎麼處理“使用者認證”在 Warden 裡叫做 “strategies” （策略）。

可用的策略有： `:password`、...


## Example app

```bash
$ rails new app
```

加入 warden gem:

```ruby
# Gemfile
gem 'warden', '~> 1.2.3'
```

安裝：

```bash
$ bundle install
```

加入到 Rails 的 Middleware Stack，指定驗證策略：

```ruby
# config/application.rb
config.middleware.use Warden::Manager do |manager|
  manager.default_strategies :password
end
```

### `Warden::Manager` 做了什麼？

新增 `warden` key 至 `env` 物件，在每個 HTTP 請求裡，可以用 `env['warden']` 來存取 Warden 物件。

> `request.env['warden']` 可簡寫為 `env['warden']`

## `set_user`

```ruby
env['warden'].set_user(@account.id, scope: :account)
```

取出

```ruby
User.find(env['warden'].user(scope: :account))
```

## `authenticated?`

接受 scope 物件，物件存在時返回 `true` ，反之 `false`。

# 延伸閱讀

[Warden Wiki – GitHub](https://github.com/hassox/warden/wiki)

[#305 Authentication with Warden (pro) - RailsCasts](http://railscasts.com/episodes/305-authentication-with-warden)