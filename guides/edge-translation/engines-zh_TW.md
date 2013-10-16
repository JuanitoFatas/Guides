# Rails Engine 介紹

__特別要強調的翻譯名詞__

> Web application ＝ Web 應用程式 ＝ 應用程式。

> host application ＝ 宿主。

> plugin ＝ 外掛。

--

本篇介紹 「Rails Engine」。怎麼優雅地把 Engine 掛到應用程式裡。

讀完本篇可能會學到.....

  * 什麼是 Engine。

  * 如何產生 Engine。

  * 怎麼給 Engine 加功能。

  * 怎麼讓 Engine 與應用程式結合。

  * 在應用程式裡覆寫 Engine 的功能。

## 目錄

- [1. Engine 是什麼](#1-engine-是什麼)
  - [1.1 Engine 開發簡史](#11-engine-開發簡史)
  - [1.2 Rails 2.x 使用 Engine](#12-rails-2x-使用-engine)
- [2. 產生 Engine](#2-產生-engine)
  - [2.1 Engine 裡面有什麼](#21-engine-裡面有什麼)
    - [2.1.1 重要的檔案](#211-重要的檔案)
    - [2.1.2 `app` 目錄](#212-app-目錄)
    - [2.1.3 `bin` 目錄](#213-bin-目錄)
    - [2.1.4 `test` 目錄](#214-test-目錄)
- [3. 給 Engine 加功能](#3-給-engine-加功能)
  - [3.1 建立 post resource](#31-建立-post-resource)
  - [3.2 產生 comment resource](#32-產生-comment-resource)
- [4. 安裝至宿主](#4-安裝至宿主)
  - [4.1 安裝 Engine](#41-安裝-engine)
  - [4.2 Engine setup](#42-engine-setup)
  - [4.3 使用宿主提供的類別](#43-使用宿主提供的類別)
    - [4.3.1 使用宿主提供的 model](#431-使用宿主提供的-model)
    - [4.3.2 使用宿主提供的 controller](#432-使用宿主提供的-controller)
  - [4.4 自定 `User` model](#44-自定-user-model)
    - [4.4.1 在宿主設定](#441-在宿主設定)
    - [4.4.2 設定 Engine](#442-設定-engine)
      - [4.4.2.1 Initalizer 例子：Devise `devise_for`](#4421-initalizer-例子：devise-devise_for)
      - [4.4.2.2 變更 Engine 預設的 ORM、模版引擎、測試框架](#4422-變更-engine-預設的-orm、模版引擎、測試框架)
      - [4.4.2.3 變更 Engine 的名稱](#4423-變更-engine-的名稱)
      - [4.4.2.5 新增 Middleware 到 Engine 的 Middleware stack](#4425-新增-middleware-到-engine-的-middleware-stack)
    - [4.4.3 撰寫 Engine 的 Generator](#443-撰寫-engine-的-generator)
- [5. 測試 Engine](#5-測試-engine)
  - [5.1 功能性測試](#51-功能性測試)
- [6. 增進 Engine 的功能](#6-增進-engine-的功能)
  - [6.1 覆寫 Model 與 Controller](#61-覆寫-model-與-controller)
  - [6.2 關於 Decorator 與加載代碼](#62-關於-decorator-與加載代碼)
  - [6.3 用 `Class#class_eval` 來實現 Decorator 設計模式](#63-用-class#class_eval-來實現-decorator-設計模式)
  - [6.4 用 `ActiveSupport::Concern` 來實現 Decorator 設計模式](#64-用-activesupportconcern-來實現-decorator-設計模式)
  - [6.5 覆寫 views](#65-覆寫-views)
  - [6.6 路由](#66-路由)
    - [6.6.1 路由優先權](#661-路由優先權)
    - [6.6.2 重新命名 Engine Routing Proxy 方法](#662-重新命名-engine-routing-proxy-方法)
  - [6.7 Assets](#67-assets)
  - [6.8 宿主用不到的 Assets 與預編譯](#68-宿主用不到的-assets-與預編譯)
  - [6.9 Engine 依賴的 Gem](#69-engine-依賴的-gem)
- [延伸閱讀](#延伸閱讀)

# 1. Engine 是什麼

Engine 可以想成是抽掉了某些功能的 Rails 應用程式： __微型的 Rails 應用程式__ 。可以安裝到（mount）宿主，為宿主新增新功能。Rails 本身也是個 Engine，Rails 應用程式 `Rails::Application` 繼承自 `Rails::Engine`，其實 Rails 不過就是個“強大的” Engine。

Rails 還有外掛功能，外掛跟 Engine 很像。兩者都有 `lib` 目錄結構，皆採用 `rails plugin new` 來產生 Engine 與外掛。Engine 可以是外掛；外掛也可是 Engine。但還是不太一樣，Engine 可以想成是“完整的外掛”。

下面會用一個 `blorgh` Engine 的例子來講解。這個 `blorgh` 給宿主提供了：新增文章（posts）、新增評論（comments），這兩個功能。我們會先開發 Engine，再把 Engine 安裝到應用程式。

假設路由裡有 `posts_path` 這個 routing helper，宿主會提供這個功能、Engine 也會提供，這兩者並不衝突。也就是說 Engine 可從宿主抽離出來。稍後會解釋這是如何實作的。

__記住！宿主的優先權最高，Engine 不過給宿主提供新功能。__

以下皆是以 Rails Engine 實現的 RubyGems：

* [Devise](https://github.com/plataformatec/devise) 提供使用者驗證功能。

* [Forem](https://github.com/radar/forem) 提供論壇功能。

* [Spree](https://github.com/spree/spree) 提供電子商務平台。

* [RefineryCMS](https://github.com/refinery/refinerycms) 內容管理系統。

* [Rails Admin](https://github.com/sferik/rails_admin) 內容管理系統。

* [Active Admin](https://github.com/sferik/active_admin) 內容管理系統。

## 1.1 Engine 開發簡史

> 滾滾長江東逝水，<br>
> 浪花滔盡英雄。<br>
> 是非成敗轉頭空。<br>
> 青山依舊在，幾度夕陽紅。<br>
> 白髮漁樵江渚上，<br>
> 慣看秋月春風。<br>
> 一壺濁酒喜相逢。<br>
> 古今多少事，都付笑談中。

James Adam 2005 年 10 月 31 日（萬聖節）開始開發 Rails Engine，作為 plugin 的形式提交到 Rails（當時 Rails 的版本為 0.14.2），Kevin Smith 稍後寫了一篇文章提到：

> Engine is also a nasty hack that breaks every new version of Rails because it hooks into internals that aren’t publicly supported.
> [Guide: Things You Shouldn't do in Rails by Kevin Smith ](http://glu.ttono.us/articles/2006/08/30/guide-things-you-shouldnt-be-doing-in-rails)

DHH 也說：

> I didn't want Rails to succumb to the lure of high-level components like login systems, forums, content management, and the likes.
> [The case against high-level components](http://david.heinemeierhansson.com/arc/000407.html)

DHH 又說：

> But the goal of Rails is to create a world where they are neither needed or strongly desired. Obviously, we are not quite there yet.
> [Why engines and components are not evil but distracting](http://weblog.rubyonrails.org/2005/11/11/why-engines-and-components-are-not-evil-but-distracting/)

...

> Engines have not received the blessing of the RoR core team, and I wouldn't expect any different, because it would be madness to include them in the
core Rails.
> [gmane.comp.lang.ruby.rails mailing list](http://article.gmane.org/gmane.comp.lang.ruby.rails/29166)

哇賽，Madness...這看起來像是 DHH 會講的話，但是卻是 Engine 作者 James Adam 自己說的。

歷經了多少無數的編程夜晚，本來與 Rails 錯綜複雜各種核心功能，在 Rails 3.1 起，全都被抽離出來，變成 `Rails::Engine` 了，甚至 Rails 本身也是個 Engine：

```
# Rails 3.1+, try this in Pry or Irb.
require 'rails'
Rails::Application.superclass
=> Rails::Engine
```

Rails 3.2 Plugin 走入歷史，Engine 正式當家。

Piotr Sarnacki 在 2010 Ruby Summer of Code 把 [Russian Doll Pattern](http://vimeo.com/4611379) 實現到 Rails Engine 裡...

感謝 [James Adam](http://lazyatom.com/)、[Piotr Sarnacki](http://piotrsarnacki.com/)、Rails 核心成員及無數人員的辛苦努力，
沒有他們就沒有 Rails Engine！下次碰到他們記得感謝他們一下.....

__DHH 又再度被打臉了。__

## 1.2 Rails 2.x 使用 Engine

還在用 2.x? COOL. 可以用這個 Gem：

&nbsp;&nbsp;&nbsp;&nbsp; :point_right: &nbsp; [lazyatom/engines](https://github.com/lazyatom/engines)

# 2. 產生 Engine

用 plugin 產生器來產生 Engine（加上 `--mountable` 選項）：

```bash
$ rails plugin new blorgh --mountable
```

看看產生出來的 Engine 的目錄結構：

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

當 Engine 開發完畢時，安裝到宿主的時候，需要在宿主的 Gemfile 新增：

```ruby
gem 'blorgh', path: "vendor/engines/blorgh"
```

執行 `bundle install` 安裝時，Bundler 會去解析 `blorgh.gemspec`，並安裝其他相依的 Gems；同時，Bundler 會 require Engine `lib` 目錄下的 `lib/blorgh.rb`，這個檔案又 require 了 `lib/blorgh/engine.rb`，達到將 Engine 定義成 Module 的目的：

```ruby
# lib/blorgh/engine.rb
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

Engine 所需的 `images`、`javascripts`、`stylesheets`，皆放在 `blorgh` 下（命名空間分離）：

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

要是不想要使用 Engine 的 layout，刪除這個檔案，並在 Engine 的 controller 指定你要用的 layout。

### 2.1.3 `bin` 目錄

```
bin
└── rails
```

這讓 Engine 可以像原本的 Rails 應用程式一樣，用 `rails` 相關的命令。

### 2.1.4 `test` 目錄

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

Engine 的整合測試（Integration test）放這裡。其他相關的測試也可以放在這裡，比如關於 controller 的測試（`test/controller`）、關於 model （`test/model`）的測試等。

# 3. 給 Engine 加功能

我們的 blorgh Engine，提供了 post 與 comment 的功能，跟 [Getting Started Guide](http://edgeguides.rubyonrails.org/getting_started.html) 功能差不多。

## 3.1 建立 post resource

先用鷹架產生 `Post` model：

```bash
$ rails generate scaffold post title:string text:text
```

會輸出：

```
invoke  active_record
create    db/migrate/[timestamp]_create_blorgh_posts.rb
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
* `invoke  resource_route` 新增了一個 route 到 `config/routes.rb`：

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

[require_dependency 原始碼可在此找到](https://github.com/rails/rails/blob/master/activesupport/lib/active_support/dependencies.rb#L201)

* `invoke    erb` 產生 controller 相關的 views。
* `invoke    test_unit` 產生 controller 相關的測試。
* `invoke    helper` 產生 controller 相關的 helper。
* `invoke      test_unit` 產生 helper 的測試。
* `invoke  assets` 產生關於這個 resource 的 css 與 js。
* `invoke    js` 產生關於這個 resource 的 js
* `invoke    css` 產生關於這個 resource 的 css
* `invoke  css` scaffold 為這個 resource 產生的樣式。

要載入 scaffold 產生的樣式，新增下面這行到 `app/views/layouts/blorgh/application.html.erb`：

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

__這裡的 `root` 是 Engine 的：`http://localhost:3000/blorgh/`__

## 3.2 產生 comment resource

好了，Engine 現在可以新增文章了！接下來加入評論功能。怎麼加呢？先產生 comment model、comment controller 並修改由 scaffold 產生出的 post，讓使用者可以瀏覽評論或新增評論。

一步一步來，從建立 `Comment` model 開始，每個 comment 都有與之關聯的 post (`post_id`)：

```bash
$ rails generate model Comment post_id:integer text:text
```

會輸出：

```
invoke  active_record
create    db/migrate/[timestamp]_create_blorgh_comments.rb
create    app/models/blorgh/comment.rb
invoke    test_unit
create      test/models/blorgh/comment_test.rb
create      test/fixtures/blorgh/comments.yml
```

同樣，這都放在 Engine 的 Namespace 下。

migrate 我們的 comment model：

```bash
$ rake db:migrate
==  CreateBlorghComments: migrating ===========================================
-- create_table(:blorgh_comments)
   -> 0.0051s
==  CreateBlorghComments: migrated (0.0052s) ==================================
```

要在文章裡顯示評論，打開 `app/views/blorgh/posts/show.html.erb`，找到：

```erb
<%= link_to 'Edit', edit_post_path(@post) %> |
```

在這行之前新增：

```html+erb
<h3>Comments</h3>
<%= render @post.comments %>
```

`@post.comments` 會需要聲明 Post 與 Comment 之間的關係。打開 `app/models/blorgh/post.rb`，新增 `has_many :comments`：

```ruby
module Blorgh
  class Post < ActiveRecord::Base
    has_many :comments
  end
end
```

好了，厲害的同學可能會問：「老師！為什麼不用 `has_many` 裡面的 `:class_name` 選項呢？」因為 model 是定義在 `Blorgh` Module 裡面，Rails 自己就知道要用 `Blorgh::Comment` model 了哦 ^_^！

接下來新增在文章中新增評論的表單，打開 `app/views/blorgh/posts/show.html.erb`，新增這行到剛剛新增的 `render @post.comments` 下面：

```erb
<%= render "blorgh/comments/form" %>
```

但我們還沒有新增這個 partial，首先新增目錄：

```bash
$ mkdir -p app/views/blorgh/comments
```

並新增：

```bash
$ touch app/views/blorgh/comments/_form.html.erb
```

填入：

```html+erb
<h3>New comment</h3>
<%= form_for [@post, @post.comments.build] do |f| %>
  <p>
    <%= f.label :text %><br>
    <%= f.text_area :text %>
  </p>
  <%= f.submit %>
<% end %>
```

表單送出時，會對 `/posts/:post_id/comments/` 做 POST。目前還沒有這條路由，讓我們來新增一下，打開 `config/routes.rb`

```ruby
resources :posts do
  resources :comments
end
```

現在 model、路由有了，接著就是處理 route 的 controller 了：

```bash
$ rails g controller comments
```

會輸出：

```
create  app/controllers/blorgh/comments_controller.rb
invoke  erb
 exist    app/views/blorgh/comments
invoke  test_unit
create    test/controllers/blorgh/comments_controller_test.rb
invoke  helper
create    app/helpers/blorgh/comments_helper.rb
invoke    test_unit
create      test/helpers/blorgh/comments_helper_test.rb
invoke  assets
invoke    js
create      app/assets/javascripts/blorgh/comments.js
invoke    css
create      app/assets/stylesheets/blorgh/comments.css
```

當表單送 POST 請求到 `/posts/:post_id/comments/` 時，controller （`Blorgh::CommentsController`）要有 `create` action 來回應，打開 `app/controllers/blorgh/comments_controller.rb`，並新增：

```ruby
def create
  @post = Post.find(params[:post_id])
  @comment = @post.comments.create(comment_params)
  flash[:notice] = "Comment has been created!"
  redirect_to posts_path
end

private
  def comment_params
    params.require(:comment).permit(:text)
  end
```

好了，新增評論的功能完成了！但...有點小問題，如果你試著要新增評論，則會看到下面這個錯誤：

```
Missing partial blorgh/comments/comment with {:handlers=>[:erb, :builder], :formats=>[:html], :locale=>[:en, :en]}. Searched in:
  * "/Users/yourname/parth-to-engine/blorgh/test/dummy/app/views"
  * "/Users/yourname/parth-to-engine/blorgh/app/views"
```

Engine 找不到 partial。因為 Rails 在 `test/dummy` 的 `app/views` 目錄下面找，接著去 Engine 的 `app/views` 目錄找，然後沒找到！

但 Engine 知道要在 `blorgh/comments/comment` 找，因為 model 物件是從 `Blorgh:Comment` 傳來的，好，那就新增 `app/views/blorgh/comments/_comment.html.erb` 並新增：

```erb
<%= comment_counter + 1 %>. <%= comment.text %> <br>
```

`comment_counter` 是從哪來的？ :point_right: `<%= render @post.comments %>`。

好了，評論功能做完了！

# 4. 安裝至宿主

接下來講解如何將 Engine 安裝到宿主，並假設宿主有 `User` class，把我們的評論與文章功能新增到宿主的 User 上。

## 4.1 安裝 Engine

首先產生一個宿主吧：

```bash
$ rails new unicorn
```

打開 Gemfile，新增 Devise：

```ruby
gem 'devise'
```

接著加入我們的 `blorgh` Engine：

```ruby
gem 'blorgh', path: "/path/to/blorgh"
```

記得 `bundle install` 安裝。

接著新增 `blorgh` Engine 所需的路由，打開宿主的 `config/routes.rb`：

```ruby
mount Blorgh::Engine, at: "/blog"
```

`http://localhost:3000/blog` 就會交給我們的 Engine 處理。

## 4.2 Engine setup

接著要把 Engine 的 migration 複製到宿主這裡，產生對應的 tables。Rails 已經幫我們提供了方便的命令：

```bash
$ rake blorgh:install:migrations
```

如果有多個 Engine 都要把 migration 複製過來，可以：

```bash
$ rake railties:install:migrations
```

__已經複製過的 migraiton 不會重複複製__


好了，有細心的同學又發問了：「老師！那複製過來，timestamp 不就是當初開發 Engine 的 Timestamp 嗎？要是很久以前開發的 Engine，不就比我的應用程式的 migration 還早執行了嗎？」呵呵，小朋友，Rails 也想到這件事了！

執行 `$ rake blorgh:install:migrations` 會輸出：

```
Copied migration [timestamp_1]_create_blorgh_posts.rb from blorgh
Copied migration [timestamp_2]_create_blorgh_comments.rb from blorgh
```

`timestamp_1` 會是複製當下的時間，`timestamp_2` 會是現在時間加 1 秒，以此類推。

OK. 準備完畢，現在可以跑 migration 了：

```bash
rake db:migrate
```

打開 [http://localhost:3000/blog](http://localhost:3000/blog) 看看。

今天要是裝了很多個 Engine，只想跑某個 Engine 的 migration 怎麼辦？

```bash
rake db:migrate SCOPE=blorgh
```

取消（Revert）Blorgh Engine 的 migration 呢？

```bash
rake db:migrate SCOPE=blorgh VERSION=0
```

## 4.3 使用宿主提供的類別

### 4.3.1 使用宿主提供的 model

好了，現在 `blorgh` 裝起來了，現在看看 Engine 怎麼跟宿主結合：幫我們的 post 與 comment 加上 author。

通常會用 `User` 來表示文章或評論的作者，但叫 `Person` 也不是不可以，Engine 在處理 model 關聯時，不要寫死成 `User`。之後講解如何自定作者的類別名稱。


這裡為了保持簡單，就用 `User` 當評論或文章的作者：

```bash
rails g model user name:string
```

記得執行 `rake db:migrate` 來產生 `users` table。

接著讓我們來把新增文章的表單加上 `author_name`，Engine 會用這個名字來新增一個 `User` 物件，並把 `user` 與 `post` 關聯起來。

新增 `author_name` text field 加到 Engine 的 `app/views/blorgh/posts/_form.html.erb` partial，加在 `title` 上面吧：

```html+erb
<div class="field">
  <%= f.label :author_name %><br>
  <%= f.text_field :author_name %>
</div>
```

接下來，更新 `Blorgh::PostController` 的 `post_params`：

```ruby
def post_params
  params.require(:post).permit(:title, :text, :author_name)
end
```

`Blorgh::Post` model 要能夠把 `author_name` 轉換成實際的 `User` 物件，並在 `post` 儲存前，將該 `post` 與 `author` 關聯起來。同時加上 `attr_accessor` 讓我們可以 `author_name` 知道作者是誰以及修改作者，將 `app/models/blorgh/post.rb` 修改為：

```ruby
module Blorgh
  class Post < ActiveRecord::Base
    has_many :comments
    attr_accessor :author_name
    belongs_to :author, class_name: "User"
    before_save :set_author

    private
      def set_author
        self.author = User.find_or_create_by(name: author_name)
      end
  end
end
```

接著處理 `blorgh_posts` table 與 `users` table 的關係。由於我們想要的是 `author`，所以要幫 `blorgh_posts` 加上 `author_id`，在 Engine 的根目錄下執行：

```bash
$ rails g migration add_author_id_to_blorgh_posts author_id:integer
```
<!-- rails g migration add_author_id_to_blorgh_posts author_id:references -->

把 migration 複製到宿主：

```bash
$ rake blorgh:install:migrations
```

執行 migration：

```bash
$ rake db:migrate
```

現在作者（宿主：`users`）與文章（Engine：`blorgh_posts`）的關聯做好了！

首頁顯示作者，打開 `app/views/blorgh/posts/index.html.erb`：

在這行 `<th>Title</th>` 上面新增：

```html
<th>Author</th>
```

並在 `<td><%= post.title %></td>` 上面新增：

```erb+html
<td><%= post.author %></td>
```

最後，在文章頁面顯示作者吧，打開 `app/views/blorgh/posts/show.html.erb`：

```html+erb
<p>
  <strong>Author:</strong>
  <%= @post.author %>
</p>
```

默認行為會輸出：

```
#<User:0x00000100ccb3b0>
```

但我們要的是名字，新增 `to_s` 到 `User`：

```ruby
def to_s
  name
end
```

完成！

### 4.3.2 使用宿主提供的 controller

Rails controller 通常會共享一些功能，像是 authentication、session 變數，通常都從 `ApplicationController` 繼承而來。Rails Engine，是獨立運行在宿主之外，每個 Engine 有自己的 `ApplicationController` （在某個 scope 之下），像我們例子中的 `Blorgh::ApplicationController`。

但有時 Engine 需要宿主 `ApplicationController` 的某些功能，該怎麼做呢？簡單的辦法是讓 Engine 的繼承自宿主的 `ApplicationController`：

將 `app/controllers/blorgh/application_controller.rb` 修改為

```ruby
class Blorgh::ApplicationController < ApplicationController
end
```

便可獲得來自宿主 `ApplicationController` 的功能，這樣看起來就像是宿主的某個 controller。

## 4.4 自定 `User` model

要是 `User` model 要換成別的名字怎麼辦？讓我們看看，要怎麼實現客製化 `User` model 這個功能。

### 4.4.1 在宿主設定

Engine 可以加入一個設定，叫做 `author_class`，可以讓使用 Engine 的人設定，他們的 “User” model 叫什麼名字。

打開 Engine 目錄下，`lib/blorgh.rb`，加入這行：

```ruby
mattr_accessor :author_class
```

`mattr_accessor` 跟 `attr_accessor` 與 `cattr_accessor` 很類似。可以 `Blorgh.author_class` 來存取。

下一步是修改 `Blorgh::Post` model：

```ruby
belongs_to :author, class_name: Blorgh.author_class
```

同時也得修改 `set_author` 方法：

```ruby
self.author = Blorgh.author_class.constantize.find_or_create_by(name: author_name)
```

但這樣每次都得對 `author_class` 呼叫 `constantize`，可以覆寫 `Blorgh` module 裡面，`author_class` 的 getter 方法（`lib/blorgh.rb`）：

```ruby
def self.author_class
  @@author_class.constantize
end
```

這樣剛剛的 `set_author` 方法便可以改成：

```ruby
self.author = Blorgh.author_class.find_or_create_by(name: author_name)
```

由於更改了 `author_class` 方法（永遠回傳 `Class` 物件），也得修改 `Blorgh::Post` 的 `belongs_to`：

```ruby
belongs_to :author, class_name: Blorgh.author_class.to_s
```

接著在宿主裡新建一個 initializer。Initializer 可確保宿主在啟動之前、或是呼叫任何 Engine 的 model 方法之前，會先套用我們的設定。

在宿主的根目錄下，新建 `config/initializers/blorgh.rb`：

```ruby
Blorgh.author_class = "User"
```

__警告！用字串來設定，而不是直接使用 model。__

因為執行 initializer 的時候，model 可能還不存在。

接著試試新增一篇文章，看是不是跟之前一樣可以用。但現在我們的 class 是可設定的，YA！

### 4.4.2 設定 Engine

initializer、i18n、或是做其他的設定，在 Engine 裡怎麼做呢？Engine 其實就是個微型的 Rails 應用程式，所以可以像是在 Rails 裡面那般設定。

要設定 initializer，在 Engine 目錄 `config/initializers` 新增你的設定即可。關於 initializer 的更多說明請參考 [Rails 官方文件的 Initalizers section](http://edgeguides.rubyonrails.org/configuring.html#initializers)

語系設定放在 Engine 目錄下的 `config/locales` 即可。

就跟設定 Rails 應用程式一樣。

#### 4.4.2.1 Initalizer 例子：Devise `devise_for`

用過 Devise 的同學可能在 `config/routes.rb` 都看過 `devise_for` ，大概是怎麼實現的呢？

以下代碼僅做示意之用，並非實際 Devise 的代碼：

```ruby
# lib/devise/engine.rb
require 'devise/routing_extensions'

module Devise
  class Engine < ::Rails::Engines
    isolate_namespace Devise

    initializer 'devise.new_routes', after: 'action_dispatch.prepare_dispatcher' do |app|
      ActionDispatch::Routing::Mapper.send :include, Devise::RouteExtensions
    end
  end
end
```

```ruby
# lib/devise/routing_extensions.rb
module Devise
  module RouteExtensions
    def devise_for
      mount Devise::Engine => "/user"
      get "sign_in", :to => "devise/sessions#new"
    end
  end
end
```

#### 4.4.2.2 變更 Engine 預設的 ORM、模版引擎、測試框架

```ruby
# lib/blorgh/engine.rb
module Blorgh
  class Engine < ::Rails::Engines
    isolate_namespace Blorgh
    config.generators.orm             :datamapper
    config.generators.template_engine :haml
    config.generators.test_framework  :rspec
  end
end
```

亦可：

```ruby
# lib/blorgh/engine.rb
module Blorgh
  class Engine < ::Rails::Engines
    isolate_namespace Blorgh
    config.generators do |c|
      c.orm             :datamapper
      c.template_engine :haml
      c.test_framework  :rspec
    end
  end
end
```

__Rails 3.1 以前請使用 `config.generators`__

#### 4.4.2.3 變更 Engine 的名稱

Engine 的名稱在兩個地方會用到：

* routes

`mount MyEngine::Engine => '/myengine'` 有默認的 default 選項 `:as`，

默認的名稱便是 `as: 'engine_name'`

* 複製 migration 的 Rake task （如 `myengine:install:migrations`）

__如何變更？__

```ruby
module MyEngine
  class Engine < Rails::Engine
    engine_name "my_engine"
  end
end
```

#### 4.4.2.4 新增 Middleware 到 Engine 的 Middleware stack

```ruby
# lib/blorgh/engine.rb
module Blorgh
  class Engine < ::Rails::Engines
    isolate_namespace Blorgh
    middleware.use Rack::Cache,
      :verbose => true,
      :metastore   => 'file:/var/cache/rack/meta',
      :entitystore => 'file:/var/cache/rack/body'
  end
end
```

### 4.4.3 撰寫 Engine 的 Generator

讓使用者輕鬆安裝你的 Engine，比如：

```bash
$ rake generate blorgh:install
```

Generator 該怎麼寫呢？（示意）

```ruby
# lib/generators/blorgh/install_generator.rb
module Blorgh
  class InstallGenerator < Rails::Generator::Base
    def install
      run "bundle install"
      route "mount Blorgh::Engine" => '/blorgh'
      rake "blorgh:install:migrations"
      ...
    end
  end
end
```

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

# 6. 增進 Engine 的功能

本節講解如何在宿主應用程式裡，為 Engine 新增新功能，或是覆寫 Engine 的功能。

## 6.1 覆寫 Model 與 Controller

要擴展 Engine 的 model 與 controller，在宿主利用 Ruby 可打開某個類的特性，“打開”要修改的類別即可。通常會使用叫做 “decorator” 的設計模式。

簡單的類別修改呢，可以用 `Class#class_eval`，複雜的修改用 `ActiveSupport::Concern`。

## 6.2 關於 Decorator 與加載代碼

因為這些 `decorator` 是你加的，Rails 應用程式不知道他們在哪，Rails 的 autoload 不會自動幫你加載，也就是需要自己手工 `require`：

比如可以這樣子加載（Engine 目錄下的 `lib/blorgh/engine.rb`）：

```ruby
module Blorgh
  class Engine < ::Rails::Engine
    isolate_namespace Blorgh

    config.to_prepare do
      Dir.glob(Rails.root + "app/decorators/**/*_decorator*.rb").each do |c|
        require_dependency(c)
      end
    end
  end
end
```

不僅是 Decorator，任何你為 Engine 新增，而宿主無法參照的功能都可以。

## 6.3 用 `Class#class_eval` 來實現 Decorator 設計模式

**比如要新增** `Post#time_since_created`，

```ruby
# unicorn/app/decorators/models/blorgh/post_decorator.rb

Blorgh::Post.class_eval do
  def time_since_created
    Time.current - created_at
  end
end
```

```ruby
# Blorgh/app/models/post.rb

class Post < ActiveRecord::Base
  has_many :comments
end
```

**覆寫** `Post#summary`

```ruby
# unicorn/app/decorators/models/blorgh/post_decorator.rb

Blorgh::Post.class_eval do
  def summary
    "#{title} - #{truncate(text)}"
  end
end
```

```ruby
# Blorgh/app/models/post.rb

class Post < ActiveRecord::Base
  has_many :comments
  def summary
    "#{title}"
  end
end
```

## 6.4 用 `ActiveSupport::Concern` 來實現 Decorator 設計模式

簡單的改動用 `Class#class_eval` 就可以了，更複雜的情況，考慮看看使用 [`ActiveSupport::Concern`](http://edgeapi.rubyonrails.org/classes/ActiveSupport/Concern.html) 吧。

`ActiveSupport::Concern` 幫你處理錯綜複雜的 module 相依關係。

**新增** `Post#time_since_created` 並 **覆寫** `Post#summary`

```ruby
# unicorn/app/models/blorgh/post.rb

class Blorgh::Post < ActiveRecord::Base
  include Blorgh::Concerns::Models::Post

  def time_since_created
    Time.current - created_at
  end

  def summary
    "#{title} - #{truncate(text)}"
  end
end
```

```ruby
# Blorgh/app/models/post.rb

class Post < ActiveRecord::Base
  include Blorgh::Concerns::Models::Post
end
```

```ruby
# Blorgh/lib/concerns/models/post

module Blorgh::Concerns::Models::Post
  extend ActiveSupport::Concern

  # 'included do' causes the included code to be evaluated in the
  # context where it is included (post.rb), rather than be
  # executed in the module's context (blorgh/concerns/models/post).
  included do
    attr_accessor :author_name
    belongs_to :author, class_name: "User"

    before_save :set_author

    private
      def set_author
        self.author = User.find_or_create_by(name: author_name)
      end
  end

  def summary
    "#{title}"
  end

  module ClassMethods
    def some_class_method
      'some class method string'
    end
  end
end
```

## 6.5 覆寫 views

當 Rails 要渲染某個 view 時，會先從宿主的 `app/views` 找起，接著才是 Engine 的 `app/views`。

`Blorgh::PostController` 的 `index` action 執行時，首先會在宿主的 `app/views/blorgh/posts/index.html.erb` 尋找是否有 `index.html.erb`，接著才在自己的 `app/views/blorgh/posts/index.html.erb` 下尋找。

那要怎麼覆寫這個 view 呢？在宿主目錄下新建 `app/views/blorgh/posts/index.html.erb`。試試看，並填入以下內容：

```html+erb
<h1>Posts</h1>
<%= link_to "New Post", new_post_path %>
<% @posts.each do |post| %>
  <h2><%= post.title %></h2>
  <small>By <%= post.author %></small>
  <%= simple_format(post.text) %>
  <hr>
<% end %>
```

## 6.6 路由

在 Engine 裡定義的路由，默認下是與宿主定義的路由分離，確保兩者之間不衝突。

假設今天，想要要是 erb 是從 Engine 渲染的，則存取 Engine 的 `posts_path`，要是從宿主，就去宿主的 `posts_path`：

```erb
<%= link_to "Blog posts", posts_path %>
```
這有可能會跳到 Engine 或是宿主的 `posts_path`。

Engine 與宿主的存取方法如下：

Engine 的 `posts_path` （這叫 routing proxy 方法，與 Engine 名字相同）：

```erb
<%= link_to "Blog posts", blorgh.posts_path %>
```

宿主的 `posts_path` （`Rails::Engine` 提供的 [`main_app`](http://edgeapi.rubyonrails.org/classes/Rails/Engine.html) helper）：

```erb
<%= link_to "Home", main_app.root_path %>
```

這可以拿來實現回首頁的功能。

### 6.6.1 路由優先權

將 Engine 安裝至宿主之後，就會有 2 個 router。讓我們看下面這個例子：

```ruby
# host application
Rails.application.routes.draw do
  mount MyEngine::Engine => "/blog"
  get "/blog/omg" => "main#omg"
end
```

`MyEngine` 安裝在 `/blog`，`/blog/omg` 會指向宿主的 `main` controller 的 `omg` action。當有 `/blog/omg` 有 request 進來時，會先到 `MyEngine`，要是 `MyEngine` 沒有定義這條路由，則會轉發給宿主的 `main#omg`。

改寫成這樣：

```ruby
Rails.application.routes.draw do
  get "/blog/omg" => "main#omg"
  mount MyEngine::Engine => "/blog"
end
```

則 Engine 只會處理宿主沒有處理的 request。

### 6.6.2 重新命名 Engine Routing Proxy 方法

有兩個地方可換 Engine 名字：

1. `lib/blorgh/engine.rb`：

```ruby
module Blorgh
  class Engine < ::Rails::Engine
    isolate_namespace Blorgh
    engine_name "blogger"
  end
end
```

2. 在宿主或是使用 Engine 的（`test/dummy`） `config/routes.rb`：

```ruby
Rails.application.routes.draw do
  mount Blorgh::Engine => "/blorgh", as: "blogger"
end
```

## 6.7 Assets

Assets 跟平常 Rails 應用程式的工作方式相同。記得 assets 也要放在命名空間下，避免衝突。比如 Engine 有 `style.css`，放在 `app/assets/stylesheets/[engine name]/style.css` 即可。

假設 Engine 有 `app/assets/stylesheets/blorgh/style.css`，在宿主怎麼引用呢？用 `stylesheet_link_tag`：

```erb
<%= stylesheet_link_tag "blorgh/style.css" %>
```

Asset Pipeline 的 `require` 語句同樣有效：

```
/*
 *= require blorgh/style
*/
```

要使用 Sass 或是 CoffeeScript，記得將這些 gem 加到 Engine 的 `[engine name].gemspec`。

## 6.8 宿主用不到的 Assets 與預編譯

某些情況下宿主不需要用到 engine 的 assets。比如說針對 Engine 管理員的 `admin.css` 或 `admin.js`。只有 Engine 的 admin layout 需要這些 assets。這個情況下，可以在預編譯裡定義這些 assets，告訴 sprockets 要在 `rake assets:precompile` 加入 Engine 的 assets。

可以在 Engine 目錄下的 `lib/blorgh/engine.rb`，定義要預編譯的 assets：

```ruby
initializer "blorgh.assets.precompile" do |app|
  app.config.assets.precompile += %w(admin.css admin.js)
end
```

更多細節請閱讀： [Asset Pipeline guide](http://edgeguides.rubyonrails.org/asset_pipeline.html)。

## 6.9 Engine 依賴的 Gem

Engine 依賴的 Gem 要在 `[engine name].gemspec` 裡明確聲明。因為 Engine 可能會被當成 gem 安裝到宿主，把 Engine 依賴的 Gem 寫在 Engine 的 `Gemfile`，不會像傳統的 `gem install` 那樣安裝這些 Gem，進而導致你的 Engine 無法工作。

聲明 Engine 執行會用到 Gem，打開 `[engine name].gemspec`，找到 `Gem::Specification` 區塊：

```ruby
s.add_dependency "moo"
```

開發 Engine 會用到的 Gem：

```ruby
s.add_development_dependency "moo"
```

執行 `bundle install` 時會安裝這些 Gem，而 development dependency 的 Gem 只有在跑 Engine 的測試時會被使用。

注意！若想在 Engine 被使用時，馬上用某些相依的 Gem，要在 Engine 的 `engine.rb` 裡明確 `require`：


```ruby
require 'other_engine/engine'
require 'yet_another_engine/engine'

module MyEngine
  class Engine < ::Rails::Engine
  end
end
```

# 延伸閱讀

* Rails Conf 2013 Creating Mountable Engines
    - [slide](https://speakerdeck.com/peakpg/creating-mountable-engines)
    - [video](http://www.confreaks.com/videos/2476-railsconf2013-creating-mountable-engines)
* Rails Engines — Lesson Learned by Ryan Bigg | SpreeConf 2012
    - [slide](https://speakerdeck.com/radar/rails-engines-lessons-learned)
    - [video](http://www.youtube.com/watch?v=bHKZfIeAbds)
* [Integration Testing Engines by Ryan Bigg](https://speakerdeck.com/radar/integration-testing-engines)
* [#277 Mountable Engines - RailsCasts](http://railscasts.com/episodes/277-mountable-engines)
    - Railscasts 於 Rails 3.1.0.rc5 引入 Engine 的介紹。
* Rails in Actions 3 | Chapter 17 Rails Engine
