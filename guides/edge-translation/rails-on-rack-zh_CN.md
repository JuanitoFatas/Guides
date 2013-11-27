# Rails on Rack

讲解 Rails 与 Rack 的关系。

读完可能会学到...

* 在 Rails 里如何使用 Rack Middleware。
* ActionPack 内部的 Middleware 介绍。
* 如何自定一个 Middleware。

## 目录

- [1. 简介 Rack](#1-简介-rack)
- [2. Rails on Rack](#2-rails-on-rack)
  - [2.1 Rails 应用程序的 Rack 对象](#21-rails-应用程序的-rack-对象)
  - [2.2 `rails server`](#22-rails-server)
  - [2.3 `rack up`](#23-rack-up)
- [3. Action Dispatcher Middleware Stack](#3-action-dispatcher-middleware-stack)
  - [3.1 查看 Middleware Stack](#31-查看-middleware-stack)
  - [3.2 配置 Middleware Stack](#32-配置-middleware-stack)
    - [3.2.1 新增 Middleware](#321-新增-middleware)
    - [3.2.2 Swapping a Middleware](#322-swapping-a-middleware)
    - [3.2.3 Middleware Stack is an Enumerable](#323-middleware-stack-is-an-enumerable)
  - [3.3 内部 Middleware Stack](#33-内部-middleware-stack)
  - [3.4 使用 Rack Builder](#34-使用-rack-builder)
- [4. 学习资源](#4-学习资源)
  - [4.1 学习 Rack](#41-学习-rack)
  - [4.2 理解 Middlewares](#42-理解-middlewares)

# 1. 简介 Rack

Rack 提供了简单、精简、模组化的介面，在 Ruby 里开发 web 应用程序的介面。Rack 将 HTTP request 与 response 包装成最简单的形式，统整了 web 服务器、web 框架、使用者与服务器之间所需的软件、API（这也是为什么会称为 middleware），全包装成一个简单的方法，`call`。

更多内容请参考：[4.1 学习 Rack](#41-学习-rack)、[Rack API Documentation](http://rack.rubyforge.org/doc/)、[Rack Wiki](https://github.com/rack/rack/wiki/Tutorials)。

# 2. Rails on Rack

## 2.1 Rails 应用程序的 Rack 对象

假设我们的 Rails 应用程序叫做 `myapp`

`MyApp::Application` 便是 Rails 应用程序的 Rack 对象，可以用 `Rails.application` 来存取。

## 2.2 `rails server`

执行 `rails server` 的时候，会新建一个 Rack 对象，并启动服务器：

```ruby
Rails::Server.new.tap do |server|
  require APP_PATH
  Dir.chdir(Rails.application.root)
  server.start
end
```

`Rails::Server` 从 `::Rack::Server` 继承而来，用 `start` 来调用 `call`：


```ruby
class Server < ::Rack::Server
  def start
    ...
    super
  end
end
```

Rails 如何加载 Middlewares?

```ruby
def middleware
  middlewares = []
  middlewares << [Rails::Rack::Debugger] if options[:debugger]
  middlewares << [::Rack::ContentLength]
  Hash.new(middlewares)
end
```

开发模式下，多 2 个 Middleware：

| Middleware | 用途 |
| :--------- | :------ |
| Rails::Rack::Debugger | 启动 Debugger
| Rack::ContentLength   | 计算 response 有几个 byte，并配置 HTTP Content-Length header|

## 2.3 `rack up`

可以不用 `rails server` 来启动 Rails，修改 Rails 项目的 `config.ru` 即可：

```ruby
# Rails.root/config.ru
require ::File.expand_path('../config/environment', __FILE__)

use Rack::Debugger
use Rack::ContentLength
run Rails.application
```

启动服务器：

```bash
$ rackup config.ru
```

`rackup` 更多选项：

```bash
$ rackup --help
```

# 3. Action Dispatcher Middleware Stack

许多 Action Dispatcher 内部的组件（Component）都是以 Rack Middleware 的方式实现。

`Rails::Application` 使用了 `ActionDispatch::MiddlewareStack` 将内部与外部的 Middleware 结合起来。

一句话总结：

Rack 有 `Rack::Builder`；Rails 有 `ActionDispatch::MiddlewareStack`。

## 3.1 查看 Middleware Stack

新建一个 Rails app：

```bash
$ rails new MyApp
```

查看 Middleware stack：

```bash
$ rake middleware
```

输出：

```ruby
use Rack::Sendfile
use ActionDispatch::Static
use Rack::Lock
use #<ActiveSupport::Cache::Strategy::LocalCache::Middleware:0x000000029a0838>
use Rack::Runtime
use Rack::MethodOverride
use ActionDispatch::RequestId
use Rails::Rack::Logger
use ActionDispatch::ShowExceptions
use ActionDispatch::DebugExceptions
use ActionDispatch::RemoteIp
use ActionDispatch::Reloader
use ActionDispatch::Callbacks
use ActiveRecord::Migration::CheckPending
use ActiveRecord::ConnectionAdapters::ConnectionManagement
use ActiveRecord::QueryCache
use ActionDispatch::Cookies
use ActionDispatch::Session::CookieStore
use ActionDispatch::Flash
use ActionDispatch::ParamsParser
use Rack::Head
use Rack::ConditionalGet
use Rack::ETag
run MyApp::Application.routes
```

每个 middleware 的用途在 [3.3 内部 Middleware Stack](#33-内部-middleware-stack) 小节讲解。

## 3.2 配置 Middleware Stack

Rails 提供了 `config.middleware` 介面，让你新增、移除、修改 middleware stack。

整个应用程序的配置，在 `config/application.rb`；针对不同环境，在 `config/environments/<environment>.rb` 配置。

### 3.2.1 新增 Middleware

|语法|用途|
|:--|:--|
|`config.middleware.use(new_middleware, args)`|新增 middleware 到 Middleware stack 的底部|
|`config.middleware.insert_before(existing_middleware, new_middleware, args)`|新增 middleware 在某个 middleware 之前。|
|`config.middleware.insert_after(existing_middleware, new_middleware, args)`|新增 middleware 在某个 middleware 之后。|

示例：

```ruby
# Push Rack::BounceFavicon at the bottom
config.middleware.use Rack::BounceFavicon

# Add Lifo::Cache after ActiveRecord::QueryCache.
# Pass { page_cache: false } argument to Lifo::Cache.
config.middleware.insert_after ActiveRecord::QueryCache, Lifo::Cache, page_cache: false
```

### 3.2.2 Swapping a Middleware

将 Middleware stack 的 middleware 交换加载顺序：

```ruby
# config/application.rb

# Replace ActionDispatch::ShowExceptions with Lifo::ShowExceptions
config.middleware.swap ActionDispatch::ShowExceptions, Lifo::ShowExceptions
```

### 3.2.3 Middleware Stack is an Enumerable

Middleware Stack 其实就是 Ruby 的 Enumerable。任何 Enumerable 可用的方法都有提供。Middleware Stack 也实现了 3 个数组的方法：`[]`、`unshift`、`delete`。

__删掉某个 middleware__

```ruby
# config/application.rb
config.middleware.delete "Rack::Lock"
```

__移除与 session 有关的 middlewares__

```ruby
# config/application.rb
config.middleware.delete "ActionDispatch::Cookies"
config.middleware.delete "ActionDispatch::Session::CookieStore"
config.middleware.delete "ActionDispatch::Flash"
```

__移除浏览器相关的 middleware__

```ruby
# config/application.rb
config.middleware.delete "Rack::MethodOverride"
```

## 3.3 内部 Middleware Stack

Action Controller 多数的功能皆以 middleware 的方式实现，下面这个清单介绍每个 middleware 的用途：

| Middleware | Purpose |
| :-- | :-- |
| **`ActionDispatch::Static`** | 让 Rails 提供静态 assets。可透过 `config.serve_static_assets` 选项来开启或关闭。 |
| **`Rack::Lock`** | 将 `env["rack.multithread"]` 设为 `false` 可将应用程序包在 Mutex 里。|
| **`ActiveSupport::Cache::Strategy::LocalCache::Middleware`** | 用来做 memory cache。注意，此 cache 不是线程安全的。|
| **`Rack::Runtime`** | 配置 X-Runtime header，并记录这个 Request 跑多久（秒为单位）。|
| **`Rack::MethodOverride`** | 透过 `params[:_method]` 允许重写方法。这也是用来处理 HTTP PUT 与 DELETE 方法的 middleware。|
| **`ActionDispatch::RequestId`** | 给 response 产生独立的 `X-Request-Id` Header，并启用 `ActionDispatch::Request#uuid` 方法。|
| **`Rails::Rack::Logger`** | 告诉 log 有 Request 进来了，Request 结束时，清空 log。|
| **`ActionDispatch::ShowExceptions`** | Rescue 任何由应用程序抛出的 exception，并调用 exceptions app，将 expception 包装成适合显示给使用者的格式。|
| **`ActionDispatch::DebugExceptions`** | 负责记录 exceptions 并在 request 为本机的情况下，显示 debugging 页面。|
| **`ActionDispatch::RemoteIp`** | 检查 IP spoofing 攻击。|
| **`ActionDispatch::Reloader`** | 准备及清除 callbacks。在开发模式下用来重新加载程式码的 middleware。|
| **`ActionDispatch::Callbacks`** | 处理请求前，先执行预备好的 callback。|
| **`ActiveRecord::Migration::CheckPending`** | 检查是否有未执行的 migrations，若有，抛出 `PendingMigrationError` 错误。|
| **`ActiveRecord::ConnectionAdapters::ConnectionManagement`** | 每个请求结束后，若 `rack.test` 不为真，则将作用中的连结（active connection）结束。|
| **`ActiveRecord::QueryCache`** | 启用 Active Record 的 query cache。|
| **`ActionDispatch::Cookies`** | 帮 Request 配置 cookie。|
| **`ActionDispatch::Session::CookieStore`** | 负责把 session 存到 cookie。|
| **`ActionDispatch::Flash`** | `config.action_controller.session_store` 配置为真时，配置 [flash][theflash] keys。|
| **`ActionDispatch::ParamsParser`** | 将参数解析成 `params` hash。|
| **`ActionDispatch::Head`** | 将 HTTP HEAD 请求转换成 GET 请求处理。|
| **`Rack::ConditionalGet`** | 让 Server 支持 HTTP 的 Conditional GET。|
| **`Rack::ETag`** | 为所有字串 body 加上 ETag header，用来验证 cache 之用。|

以上的 middleware 都可以在自己的 Rack stack 里使用。

# 4. 学习资源

## 4.1 学习 Rack

* [Official Rack Website](http://rack.github.io)
* [Introducing Rack](http://chneukirchen.org/blog/archive/2007/02/introducing-rack.html)
* [Ruby on Rack #1 - Hello Rack!](http://m.onkey.org/ruby-on-rack-1-hello-rack)
* [Ruby on Rack #2 - The Builder](http://m.onkey.org/ruby-on-rack-2-the-builder)
* [#317 Rack App from Scratch (pro) - RailsCasts](http://railscasts.com/episodes/317-rack-app-from-scratch)
* [#222 Rack in Rails 3 - RailsCasts](http://railscasts.com/episodes/222-rack-in-rails-3)

## 4.2 理解 Middlewares

* [List of Rack Middlewares](https://github.com/rack/rack/wiki/List-of-Middleware)

* [#151 Rack Middleware - RailsCasts](http://railscasts.com/episodes/151-rack-middleware)

[theflash]: http://edgeguides.rubyonrails.org/action_controller_overview.html#the-flash
