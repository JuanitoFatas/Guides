# Rails Engine 介紹

## 目錄

# 1. Rails Engine

__特別要強調的翻譯名詞__

> Web application ＝ Web 應用程式 ＝ 應用程式。

> host application ＝ 宿主。

> plugin ＝ 插件。

--

本篇介紹 「Rails Engine」。怎麼優雅地把 Engine 掛到應用程式裡。

讀完本篇可能會學到：

  * 什麼是 Engine。

  * 如何產生 Engine。

  * 怎麼給 Engine 加功能。

  * 怎麼讓 Engine 與應用程式結合。

  * 在應用程式裡覆寫 Engine 的功能。


# 1. What are engines?

Engine 可以想成是抽掉了某些功能的 Rails 應用程式：__微型的 Rails 應用程式__ 。可以安裝到（mount）宿主，為宿主添加新功能。Rails 本身也是個 Engine，Rails 應用程式 `Rails::Application` 繼承自 `Rails::Engine`，其實 Rails 不過就是個“強大的” Engine。

Rails 還有插件功能，插件跟 Engine 很像。兩者都有 `lib` 目錄結構，皆采用 `rails plugin new` 來產生 Engine 與插件。Engine 可以是插件；插件也可是 Engine。但還是不太一樣，Engine 可以想成是“完整的插件”。

下面會用一個 `blorgh` Engine 的例子來講解。這個 `blorgh` 給宿主提供了：新增 posts、新增 comments 等功能。接著我們會先開發 Engine，再把 Engine 安裝到應用程式。

假設路由裡有 `posts_path` 這個 routing helper，宿主會提供這個功能、Engine 也會提供，這兩者並不衝突。也就是說 Engine 可從宿主抽離出來。

__記住！宿主的優先權最高，Engine 不過給宿主提供新功能。__

以下皆是以 Rails Engine 實現的 RubyGems：

* [Devise](https://github.com/plataformatec/devise) 提供使用者驗證功能。

* [Forem](https://github.com/radar/forem) 提供論壇功能。

* [Spree](https://github.com/spree/spree) 提供電子商務平台。

* [RefineryCMS](https://github.com/refinery/refinerycms) 內容管理系統。

* [Rails Admin](https://github.com/sferik/rails_admin) 內容管理系統。

* [Active Admin](https://github.com/sferik/active_admin) 內容管理系統。

## 1.1 Rails Engine 開發簡史

<!--TOWRITE-->
感謝 James Adam、Piotr Sarnacki、Rails 核心成員及無數人員的辛苦努力，沒有他們就沒有 Rails Engine！

# 2. 產生 Engine

用 plugin 產生器來產生 Engine（加上 `--mountable` 選項）：

```bash
$ rails plugin new blorgh --mountable
```

產生出的 Engine 的目錄結構：

```
.
├── app
├── bin
├── blorgh.gemspec
├── config
├── lib
├── test
├── Gemfile
├── Gemfile.lock
├── MIT-LICENSE
├── README.rdoc
└── Rakefile
```

`--help` 可查看完整說明：

```bash
$ rails plugin --help
```

讓我們看看 `--full` 選項跟 `--mountable` 的差異，`--mountable` 多加了下列檔案：

* Asset Manifest 檔案（`application.css`、`application.js`）。
* Controller `application_controller.rb`。
* Helper `application_helper.rb`。
* layout 的 view 模版: `application.html.erb`。
* 命名空間與 Rails 應用程式分離的 `config/routes.rb`：

  - `--full`：

    ```ruby
    Rails.application.routes.draw do
    end
    ```

  - `--mountable`：

    ```ruby
    Blorgh::Engine.routes.draw do
    end
    ```
* `lib/blorgh/engine.rb`：

  - `--full`：

    ```ruby
    module Blorgh
      class Engine < ::Rails::Engine
      end
    end
    ```

  - `--mountable`：

    ```ruby
    module Blorgh
      class Engine < ::Rails::Engine
        isolate_namespace Blorgh
      end
    end
    ```

除了上述差異外，`--mountable` 還會把產生出來的 Engine 安裝至 `test/dummy` 下的 Rails 應用程式，`test/dummy/config/routes.rb`:

```ruby
mount Blorgh::Engine, at: "blorgh"
```

## 2.1 Engine 裡面有什麼

Engine 目錄結構：
```
.
├── app
├── bin
├── blorgh.gemspec
├── config
├── db
├── lib
├── test
├── Gemfile
├── Gemfile.lock
├── MIT-LICENSE
├── README.rdoc
└── Rakefile
```

### 2.1.1 重要的檔案

__`blorgh.gemspec`__

當 Engine 開發完畢時，安裝到宿主的時候，需要在宿主的 Gemfile 添加：

```ruby
gem 'blorgh', path: "vendor/engines/blorgh"
```

執行 `bundle install` 安裝時，Bundler 會去解析 `blorgh.gemspec`，並安裝其他相依的 Gems；同時，Bundler 會 require Engine `lib` 目錄下的 `lib/blorgh.rb`，這個檔案又 require 了 `lib/blorgh/engine.rb`，達到將 Engine 定義成 Module 的目的：

```
# Engine 目錄下的 lib/blorgh/engine.rb
module Blorgh
  class Engine < ::Rails::Engine
    isolate_namespace Blorgh
  end
end
```

__`lib/blorgh/engine.rb` 可以放 Engine 的全域設定。__

Engine 繼承自 `Rails::Engine`，告訴 Rails 說：嘿！這個目錄下有個 Engine 呢！Rails 便知道該如何安裝這個 Engine，並把 Engine `app` 目錄下的 model、mailers、controllers、views 加載到 Rails 應用程式的 load path 裡。

__`isolate_namespace` 方法非常重要！這把 Engine 的代碼放到 Engine 的命名空間下，不與宿主衝突。__

加了這行，在我們開發 Engine，產生 model 時 `rails g model post` 便會將 model 放在對的命名空間下：

```
$ rails g model Post
invoke  active_record
create    db/migrate/20130921084428_create_blorgh_posts.rb
create    app/models/blorgh/post.rb
invoke    test_unit
create      test/models/blorgh/post_test.rb
create      test/fixtures/blorgh/posts.yml
```

資料庫的 table 名稱也會更改成 `blorgh_posts`。Controller 與 view 同理，都會被放在命名空間下。

想了解更多可看看 [`isolate_namespace` 的源碼](https://github.com/rails/rails/blob/master/railties/lib/rails/engine.rb)：

### 2.1.2 `app` 目錄

`app` 目錄下有一般 Rails 應用程式裡常見的 `assets`、`controllers`、`helpers`、`mailers`、`models`、`views`。

__`app/assets` 目錄__

```
app/assets/
├── images
│   └── blorgh
├── javascripts
│   └── blorgh
│       └── application.js
└── stylesheets
    └── blorgh
        └── application.css
```

存放 Engine 所需的 `images`、`javascripts`、`stylesheets`，皆放在 `blorgh` 下（命名空間分離）：

__`app/controllers` 目錄__

Engine controller 的功能放這裡。

```
app/controllers/
└── blorgh
    └── application_controller.rb
```

注意到

```
module Blorgh
  class ApplicationController < ActionController::Base
  end
end
```

命名成 `ApplicationController` 的原因，是讓你能夠輕鬆的將現有的 Rails 應用程式，抽離成 Engine。

__`app/views` 目錄__

```
app/views/
└── layouts
    └── blorgh
        └── application.html.erb
```

Engine 的 layout 放這裡。Engine 單獨使用的話，就可以在這裡改 layout，而不用到 Rails 應用程式的 `app/views/layouts/application.html.erb` 下修改。

要是不想 Engine 的使用者，使用 Engine 的 layout，刪除這個檔案，並在 Engine 的 controller 指定你要用的 layout。

### 2.1.3 `bin` 目錄

```
bin
└── rails
```

這讓 Engine 可以像原本的 Rails 應用程式一樣，用 `rails` 相關的命令。

### 2.1.4 `test` directory

```
test
├── blorgh_test.rb
├── dummy
│   ├── README.rdoc
│   ├── Rakefile
│   ├── app
│   ├── bin
│   ├── config
│   ├── config.ru
│   ├── db
│   ├── lib
│   ├── log
│   ├── public
│   └── tmp
├── fixtures
│   └── blorgh
├── integration
│   └── navigation_test.rb
├── models
│   └── blorgh
└── test_helper.rb
```

關於 Engine 的測試放這裡。裡面還附了一個 `test/dummy` Rails 應用程式，供你測試 Engine，這個 dummy 應用程式已經裝好了你正在開發的 Engine：

```ruby
Rails.application.routes.draw do
  mount Blorgh::Engine => "/blorgh"
end
```

__`test/integration`__

Engine 的整合測試（Integration test）放這裡。其他相關的測試也可以放在這裡，比如關於 controller 的測試（`test/controller`）、關於 model （`test/model`）等。

# 3. 給 Engine 加功能

我們的 blorgh Engine，提供了 post 與 comment 的功能，跟 [Getting Started Guide](http://edgeguides.rubyonrails.org/getting_started.html) 功能差不多。

## 3.1 建立 post resource

先產生 `Post` model：

```bash
$ rails generate scaffold post title:string text:text
```

會輸出：

```
invoke  active_record
create    db/migrate/20130921092807_create_blorgh_posts.rb
create    app/models/blorgh/post.rb
invoke    test_unit
create      test/models/blorgh/post_test.rb
create      test/fixtures/blorgh/posts.yml
invoke  resource_route
 route    resources :posts
invoke  scaffold_controller
create    app/controllers/blorgh/posts_controller.rb
invoke    erb
create      app/views/blorgh/posts
create      app/views/blorgh/posts/index.html.erb
create      app/views/blorgh/posts/edit.html.erb
create      app/views/blorgh/posts/show.html.erb
create      app/views/blorgh/posts/new.html.erb
create      app/views/blorgh/posts/_form.html.erb
invoke    test_unit
create      test/controllers/blorgh/posts_controller_test.rb
invoke    helper
create      app/helpers/blorgh/posts_helper.rb
invoke      test_unit
create        test/helpers/blorgh/posts_helper_test.rb
invoke  assets
invoke    js
create      app/assets/javascripts/blorgh/posts.js
invoke    css
create      app/assets/stylesheets/blorgh/posts.css
invoke  css
create    app/assets/stylesheets/scaffold.css
```

好，究竟產生了什麼？一個一個看。

```
invoke  active_record
invoke    test_unit
invoke  resource_route
invoke  scaffold_controller
invoke    erb
invoke    test_unit
invoke    helper
invoke  assets
invoke  css
```

__注意，產生出來的檔案都是放在 Engine 的命名空間下，因為我們有 `isolate_namespace Blorgh`__

* `invoke  active_record` 產生 migration 與 model。
* `invoke    text_unit` 產生該 model 的測試及假資料。
* `invoke  resource_route` 添加了一個 route 到 `config/routes.rb`：

    ```ruby
    resources :posts
    ```

* `invoke  scaffold_controller` 產生 controller：

    ```
    # Engine 目錄下的 app/controllers/blorgh/posts_controller.rb
    require_dependency "blorgh/application_controller"

    module Blorgh
      class PostsController < ApplicationController
      ...
      end
    end
    ```

__注意這裡繼承的 `ApplicationController` 是 `Blorgh::ApplicationController`。__

__`require_dependency` 是 Rails 特有的方法，讓你開發 Engine 時不用重啟（開發模式下）。__

[require_dependency 源代碼可在此找到](https://github.com/rails/rails/blob/master/activesupport/lib/active_support/dependencies.rb#L201)

* `invoke    erb` 產生 controller 相關的 views。
* `invoke    test_unit` 產生 controller 相關的測試。
* `invoke    helper` 產生 controller 相關的 helper。
* `invoke      test_unit` 產生 helper 的測試。
* `invoke  assets` 產生關於這個 resource 的 css 與 js。
* `invoke    js` 產生關於這個 resource 的 js
* `invoke    css` 產生關於這個 resource 的 css
* `invoke  css` scaffold 為這個 resource 產生的樣式。

要載入 scaffold 產生的樣式，添加下面這行到 `app/views/layouts/blorgh/application.html.erb`：

```erb
<%= stylesheet_link_tag "scaffold" %>
```

好了，可以執行我們熟悉的 `rake db:migrate` 了。並在 `test/dummy` 下執行 `rails server`：

```bash
$ test/dummy/bin/rails server
```

打開 [http://localhost:3000/blorgh/posts](http://localhost:3000/blorgh/posts) 看看剛剛用 scaffold 產生出來的 Post resource。

哇賽！你給 Engine 加了一個新功能了，自己掌聲鼓勵一下。

也可以用 `rails console`，不過要注意 model 的名稱是 `Blorgh::Post`。

```ruby
>> Blorgh::Post.find(1)
=> #<Blorgh::Post id: 1 ...>
```

最後把 `root` 指向 `post` 的 `index` action 吧，修改 Engine 目錄的 `config/routes.rb`：

```ruby
root to: "posts#index"
```

現在只要到 [http://localhost:3000/blorgh](http://localhost:3000/blorgh/) 就可以跳轉到 [http://localhost:3000/blorgh/posts](http://localhost:3000/blorgh/posts) 了！

__這裡的 `root` 指得是 Engine 的：`http://localhost:3000/blorgh/`__

## 3.2 Generating a comment resource

# 4. Hooking into an application

## 4.1 Mounting the engine

## 4.2 Engine setup

## 4.3 Using a class provided by the application

## 4.4 Configuring an engine

# 5. 測試 Engine

產生 Engine 時，會順便產生讓你測試 Engine 用的 dummy 應用程式，放在 `test/dummy` 。可以給這個 dummy 應用程式加 controller、model、view 啦，用來測試 Engine。

`test` 資料夾就跟一般 Rails 測試一樣有三種，分成單元、功能性、整合測試。

## 5.1 功能性測試

有點要提的是，要測試 Engine 的功能，測試在 `test/dummy` 下的應用程式執行，而不是直接在你撰寫的 Engine 裡。特別是與 controller 有關的測試，假設平常我們可以這樣來測試 controller 的功能：

```ruby
get :index
```

但對 Engine 來說沒用，因為應用程式不知道怎麼把 request 傳給 Engine，必須多給一個 `:user_route` 選項：

```ruby
get :index, use_route: :blorgh
```

# 6. Improving engine functionality

## 6.1 Overriding Models and Controllers

## 6.2 A note on Decorators and loading code

## 6.3 Implementing Decorator Pattern Using Class#class_eval

## 6.4 Implementing Decorator Pattern Using ActiveSupport::Concern

## 6.5 Overriding views

## 6.6 Routes

## 6.7 Assets

## 6.8 Separate Assets & Precompiling

# 延伸閱讀

* [Rails Engines by Ryan Bigg](https://github.com/radar/guides/blob/master/engines.md)

用很短的篇幅介紹了 Rails Engine，值得一讀。

* [#277 Mountable Engines - RailsCasts](http://railscasts.com/episodes/277-mountable-engines)

3.1.0.rc5 初次介紹 Engines 所做的影片教學。

* [Start Your Engines by Ryan Bigg at Ruby on Ales 2012 - YouTube](http://www.youtube.com/watch?v=bHKZfIeAbds)

* [Rails Conf 2013 Creating Mountable Engines by Patrick Peak](http://www.youtube.com/watch?v=s3NJ15Svq8U)

* Rails in Actions 4 | Chapter 17 Rails Engine
