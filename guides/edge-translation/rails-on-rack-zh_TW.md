# Rails on Rack

講解 Rails 與 Rack 的關係。

讀完可能會學到...

* 在 Rails 裡如何使用 Rack Middleware。
* ActionPack 內部的 Middleware 介紹。
* 如何自定一個 Middleware。

## 目錄

- [1. 簡介 Rack](#1-簡介-rack)
- [2. Rails on Rack](#2-rails-on-rack)
  - [2.1 Rails 應用程式的 Rack Object](#21-rails-應用程式的-rack-object)
  - [2.2 `rails server`](#22-rails-server)
  - [2.3 `rack up`](#23-rack-up)
- [3. Action Dispatcher Middleware Stack](#3-action-dispatcher-middleware-stack)
  - [3.1 查看 Middleware Stack](#31-查看-middleware-stack)
  - [3.2 設定 Middleware Stack](#32-設定-middleware-stack)
    - [3.2.1 新增 Middleware](#321-新增-middleware)
    - [3.2.2 Swapping a Middleware](#322-swapping-a-middleware)
    - [3.2.3 Middleware Stack is an Enumerable](#323-middleware-stack-is-an-enumerable)
  - [3.3 內部 Middleware Stack](#33-內部-middleware-stack)
  - [3.4 使用 Rack Builder](#34-使用-rack-builder)
- [4. 學習資源](#4-學習資源)
  - [4.1 學習 Rack](#41-學習-rack)
  - [4.2 理解 Middlewares](#42-理解-middlewares)

# 1. 簡介 Rack

Rack 提供了簡單、精簡、模組化的介面，在 Ruby 裡開發 web 應用程式的介面。Rack 將 HTTP request 與 response 包裝成最簡單的形式，統整了 web 伺服器、web 框架、使用者與伺服器之間所需的軟體、API（這也是為什麼會稱為 middleware），全包裝成一個簡單的方法，`call`。

更多內容請參考：[Rack 介紹](/articles/020-rack.md)、[Rack API Documentation](http://rack.rubyforge.org/doc/)、[Rack Wiki](https://github.com/rack/rack/wiki/Tutorials)。

# 2. Rails on Rack

## 2.1 Rails 應用程式的 Rack Object

假設我們的 Rails 應用程式叫做 `myapp`

`MyApp::Application` 便是 Rails 應用程式的 Rack object，可以用 `Rails.application` 來存取。

## 2.2 `rails server`

執行 `rails server` 的時候，會新建一個 Rack object，並啟動伺服器：

```ruby
Rails::Server.new.tap do |server|
  require APP_PATH
  Dir.chdir(Rails.application.root)
  server.start
end
```

`Rails::Server` 從 `::Rack::Server` 繼承而來，用 `start` 來呼叫 `call`：


```ruby
class Server < ::Rack::Server
  def start
    ...
    super
  end
end
```

Rails 如何加載 Middlewares?

```ruby
def middleware
  middlewares = []
  middlewares << [Rails::Rack::Debugger] if options[:debugger]
  middlewares << [::Rack::ContentLength]
  Hash.new(middlewares)
end
```

開發模式下，多 2 個 Middleware：

| Middleware | 用途 |
| :--------- | :------ |
| Rails::Rack::Debugger | 啟動 Debugger
| Rack::ContentLength   | 計算 response 有幾個 byte，並設定 HTTP Content-Length header|

## 2.3 `rack up`

可以不用 `rails server` 來啟動 Rails，修改 Rails 專案的 `config.ru` 即可：

```ruby
# Rails.root/config.ru
require ::File.expand_path('../config/environment', __FILE__)

use Rack::Debugger
use Rack::ContentLength
run Rails.application
```

啟動伺服器：

```bash
$ rackup config.ru
```

`rackup` 更多選項：

```bash
$ rackup --help
```

# 3. Action Dispatcher Middleware Stack

許多 Action Dispatcher 內部的組件（Component）都是以 Rack Middleware 的方式實作。

`Rails::Application` 使用了 `ActionDispatch::MiddlewareStack` 將內部與外部的 Middleware 結合起來。

一句話總結：

Rack 有 `Rack::Builder`；Rails 有 `ActionDispatch::MiddlewareStack`。

## 3.1 查看 Middleware Stack

新建一個 Rails app：

```bash
$ rails new MyApp
```

查看 Middleware stack：

```bash
$ rake middleware
```

輸出：

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

每個 middleware 的用途在 [3.3 內部 Middleware Stack](#33-內部-middleware-stack) 小節講解。

## 3.2 設定 Middleware Stack

Rails 提供了 `config.middleware` 介面，讓你新增、移除、修改 middleware stack。

整個應用程式的設定，在 `config/application.rb`；針對不同環境，在 `config/environments/<environment>.rb` 設定。

### 3.2.1 新增 Middleware

|語法|用途|
|:--|:--|
|`config.middleware.use(new_middleware, args)`|新增 middleware 到 Middleware stack 的底部|
|`config.middleware.insert_before(existing_middleware, new_middleware, args)`|新增 middleware 在某個 middleware 之前。|
|`config.middleware.insert_after(existing_middleware, new_middleware, args)`|新增 middleware 在某個 middleware 之後。|

範例：

```ruby
# Push Rack::BounceFavicon at the bottom
config.middleware.use Rack::BounceFavicon

# Add Lifo::Cache after ActiveRecord::QueryCache.
# Pass { page_cache: false } argument to Lifo::Cache.
config.middleware.insert_after ActiveRecord::QueryCache, Lifo::Cache, page_cache: false
```

### 3.2.2 Swapping a Middleware

將 Middleware stack 的 middleware 交換加載順序：

```ruby
# config/application.rb

# Replace ActionDispatch::ShowExceptions with Lifo::ShowExceptions
config.middleware.swap ActionDispatch::ShowExceptions, Lifo::ShowExceptions
```

### 3.2.3 Middleware Stack is an Enumerable

Middleware Stack 其實就是 Ruby 的 Enumerable。任何 Enumerable 可用的方法都有提供。Middleware Stack 也實現了 3 個 Array 的方法：`[]`、`unshift`、`delete`。

__刪掉某個 middleware__

```ruby
# config/application.rb
config.middleware.delete "Rack::Lock"
```

__移除與 session 有關的 middlewares__

```ruby
# config/application.rb
config.middleware.delete "ActionDispatch::Cookies"
config.middleware.delete "ActionDispatch::Session::CookieStore"
config.middleware.delete "ActionDispatch::Flash"
```

__移除瀏覽器相關的 middleware__

```ruby
# config/application.rb
config.middleware.delete "Rack::MethodOverride"
```

## 3.3 內部 Middleware Stack

Action Controller 多數的功能皆以 middleware 的方式實現，下面這個清單介紹每個 middleware 的用途：

| Middleware | Purpose |
| :-- | :-- |
| **`ActionDispatch::Static`** | 讓 Rails 提供靜態 assets。可透過 `config.serve_static_assets` 選項來開啟或關閉。 |
| **`Rack::Lock`** | 將 `env["rack.multithread"]` 設為 `false` 可將應用程式包在 Mutex 裡。|
| **`ActiveSupport::Cache::Strategy::LocalCache::Middleware`** | 用來做 memory cache。注意，此 cache 不是線程安全的。|
| **`Rack::Runtime`** | 設定 X-Runtime header，並記錄這個 Request 跑多久（秒為單位）。|
| **`Rack::MethodOverride`** | 透過 `params[:_method]` 允許重寫方法。這也是用來處理 HTTP PUT 與 DELETE 方法的 middleware。|
| **`ActionDispatch::RequestId`** | 給 response 產生獨立的 `X-Request-Id` Header，並啟用 `ActionDispatch::Request#uuid` 方法。|
| **`Rails::Rack::Logger`** | 告訴 log 有 Request 進來了，Request 結束時，清空 log。|
| **`ActionDispatch::ShowExceptions`** | Rescue 任何由應用程式拋出的 exception，並呼叫 exceptions app，將 expception 包裝成適合顯示給使用者的格式。|
| **`ActionDispatch::DebugExceptions`** | 負責記錄 exceptions 並在 request 為本機的情況下，顯示 debugging 頁面。|
| **`ActionDispatch::RemoteIp`** | 檢查 IP spoofing 攻擊。|
| **`ActionDispatch::Reloader`** | 準備及清除 callbacks。在開發模式下用來重新加載程式碼的 middleware。|
| **`ActionDispatch::Callbacks`** | 處理請求前，先執行預備好的 callback。|
| **`ActiveRecord::Migration::CheckPending`** | 檢查是否有未執行的 migrations，若有，拋出 `PendingMigrationError` 錯誤。|
| **`ActiveRecord::ConnectionAdapters::ConnectionManagement`** | 每個請求結束後，若 `rack.test` 不為真，則將作用中的連結（active connection）結束。|
| **`ActiveRecord::QueryCache`** | 啟用 Active Record 的 query cache。|
| **`ActionDispatch::Cookies`** | 幫 Request 設定 cookie。|
| **`ActionDispatch::Session::CookieStore`** | 負責把 session 存到 cookie。|
| **`ActionDispatch::Flash`** | `config.action_controller.session_store` 設定為真時，設定 [flash][theflash] keys。|
| **`ActionDispatch::ParamsParser`** | 將參數解析成 `params` hash。|
| **`ActionDispatch::Head`** | 將 HTTP HEAD 請求轉換成 GET 請求處理。|
| **`Rack::ConditionalGet`** | 讓 Server 支持 HTTP 的 Conditional GET。|
| **`Rack::ETag`** | 為所有字串 body 加上 ETag header，用來驗證 cache 之用。|

以上的 middleware 都可以在自己的 Rack stack 裡使用。

# 4. 學習資源

## 4.1 學習 Rack

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
