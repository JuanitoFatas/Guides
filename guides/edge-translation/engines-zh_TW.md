# Rails Engine 介紹

## 目錄

- [1. Rails Engine](#1-rails-engine)
  - [](#)
- [1. What are engines?](#1-what-are-engines)
  - [1.1 Rails Engine 開發簡史](#11-rails-engine-開發簡史)
- [2. 產生 Engine](#2-產生-engine)
  - [2.1 Engine 裡面有什麼](#21-engine-裡面有什麼)
    - [2.1.1 重要的檔案](#211-重要的檔案)
    - [2.1.2 `app` 目錄](#212-app-目錄)
    - [2.1.3 `bin` 目錄](#213-bin-目錄)
    - [2.1.4 `test` 目錄](#214-test-目錄)
- [3. 給 Engine 加功能](#3-給-engine-加功能)
  - [3.1 建立 post resource](#31-建立-post-resource)
  - [3.2 產生 comment resource](#32-產生-comment-resource)

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

在這行之前添加：

```html+erb
<h3>Comments</h3>
<%= render @post.comments %>
```

`@post.comments` 會需要聲明 Post 與 Comment 之間的關係。打開 `app/models/blorgh/post.rb`，添加 `has_many :comments`：

```ruby
module Blorgh
  class Post < ActiveRecord::Base
    has_many :comments
  end
end
```

好了，厲害的同學可能會問：「老師！為什麼不用 `has_many` 裡面的 `:class_name` 選項呢？」因為 model 是定義在 `Blorgh` Module 裡面，Rails 自己就知道要用 `Blorgh::Comment` model 了哦 ^_^！

接下來新增在文章中添加評論的表單，打開 `app/views/blorgh/posts/show.html.erb`，添加這行到剛剛添加的 `render @post.comments` 下面：

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

表單送出時，會對 `/posts/:post_id/comments/` 做 POST。目前還沒有這條路由，讓我們來添加一下，打開 `config/routes.rb`

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

當表單送 POST 請求到 `/posts/:post_id/comments/` 時，controller （`Blorgh::CommentsController`）要有 `create` action 來回應，打開 `app/controllers/blorgh/comments_controller.rb`，並添加：

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

但 Engine 知道要在 `blorgh/comments/comment` 找，因為 model 物件是從 `Blorgh:Comment` 傳來的，好，那就新增 `app/views/blorgh/comments/_comment.html.erb` 並添加：

```erb
<%= comment_counter + 1 %>. <%= comment.text %> <br>
```

`comment_counter` 是從哪來的？ :point_right: `<%= render @post.comments %>`。

好了，評論功能做完了！

# 4. 安裝至宿主

接下來講解如何將 Engine 安裝到宿主，並假設宿主有 `User` class，把我們的評論與文章功能添加到宿主的 User 上。

## 4.1 安裝 Engine

首先產生一個宿主吧：

```bash
$ rails new unicorn
```

打開 Gemfile，添加 Devise：

```ruby
gem 'devise'
```

接著加入我們的 `blorgh` Engine：

```ruby
gem 'blorgh', path: "/path/to/blorgh"
```

記得 `bundle install` 安裝。

接著添加 `blorgh` Engine 所需的路由，打開宿主的 `config/routes.rb`：

```ruby
mount Blorgh::Engine, at: "/blog"
```

`http://localhost:3000/blog` 就會交給我們的 Engine 處理。

## 4.2 Engine setup

接著要把 Engine 的 migration 拷貝到宿主這裡，產生對應的 tables。Rails 已經幫我們提供了方便的命令：

```bash
$ rake blorgh:install:migrations
```

如果有多個 Engine 都要把 migration 拷貝過來，可以：

```bash
$ rake railties:install:migrations
```

__已經拷貝過的 migraiton 不會重複拷貝__


好了，有細心的同學又發問了：「老師！那拷貝過來，timestamp 不就是當初開發 Engine 的 Timestamp 嗎？要是很久以前開發的 Engine，不就比我的應用程式的 migration 還早執行了嗎？」呵呵，小朋友，Rails 也想到這件事了！

執行 `$ rake blorgh:install:migrations` 會輸出：

```
Copied migration [timestamp_1]_create_blorgh_posts.rb from blorgh
Copied migration [timestamp_2]_create_blorgh_comments.rb from blorgh
```

`timestamp_1` 會是拷貝當下的時間，`timestamp_2` 會是現在時間加 1 秒，以此類推。

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

## 4.3 Using a class provided by the application

### 4.3.1 Using a model provided by the application

好了，現在 `blorgh` 裝起來了，現在看看 Engine 怎麼跟宿主結合：幫我們的 post 與 comment 加上 author。

通常會用 `User` 來表示文章或評論的作者，但叫 `Person` 也不是不可以，Engine 在處理 model 關聯時，不要寫死成 `User`。


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

把 migration 拷貝到宿主：

```bash
$ rake blorgh:install:migrations
```

執行 migration：

```bash
$ rake db:migrate
```

現在作者（宿主：`users`）與文章（Engine：`blorgh_posts`）的關聯做好了！

首頁顯示作者，打開 `app/views/blorgh/posts/index.html.erb`：

在這行 `<th>Title</th>` 上面添加：

```html
<th>Author</th>
```

並在 `<td><%= post.title %></td>` 上面添加：

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

但我們要的是名字，添加 `to_s` 到 `User`：

```ruby
def to_s
  name
end
```

完成！

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

## 6.9 Other gem dependencies

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
