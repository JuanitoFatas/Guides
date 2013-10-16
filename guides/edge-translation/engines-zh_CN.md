# Rails Engine 介绍

__特别要强调的翻译名词__

> host application ＝ 宿主。

> mount ＝ 安装

本篇介绍 「Rails Engine」。怎么优雅地把 Engine 挂到应用程序里。

读完本篇可能会学到.....

  * 什么是 Engine。

  * 如何产生 Engine。

  * 怎么给 Engine 加功能。

  * 怎么让 Engine 与应用程序结合。

  * 在应用程序里覆写 Engine 的功能。

## 目录

- [1. Engine 是什么](#1-engine-是什么)
  - [1.1 Engine 开发简史](#11-engine-开发简史)
  - [1.2 Rails 2.x 使用 Engine](#12-rails-2x-使用-engine)
- [2. 产生 Engine](#2-产生-engine)
  - [2.1 Engine 里面有什么](#21-engine-里面有什么)
    - [2.1.1 重要的文件](#211-重要的文件)
    - [2.1.2 `app` 目录](#212-app-目录)
    - [2.1.3 `bin` 目录](#213-bin-目录)
    - [2.1.4 `test` 目录](#214-test-目录)
- [3. 给 Engine 加功能](#3-给-engine-加功能)
  - [3.1 建立 post resource](#31-建立-post-resource)
  - [3.2 产生 comment resource](#32-产生-comment-resource)
- [4. 安装至宿主](#4-安装至宿主)
  - [4.1 安装 Engine](#41-安装-engine)
  - [4.2 Engine setup](#42-engine-setup)
  - [4.3 使用宿主提供的类别](#43-使用宿主提供的类别)
    - [4.3.1 使用宿主提供的 model](#431-使用宿主提供的-model)
    - [4.3.2 使用宿主提供的 controller](#432-使用宿主提供的-controller)
  - [4.4 自定 `User` model](#44-自定-user-model)
    - [4.4.1 在宿主设定](#441-在宿主设定)
    - [4.4.2 配置 Engine](#442-配置-engine)
      - [4.4.2.1 Initalizer 例子：Devise `devise_for`](#4421-initalizer-例子：devise-devise_for)
      - [4.4.2.2 变更 Engine 默认的 ORM、模版引擎、测试框架](#4422-变更-engine-默认的-orm、模版引擎、测试框架)
      - [4.4.2.3 变更 Engine 的名称](#4423-变更-engine-的名称)
      - [4.4.2.4 添加 Middleware 到 Engine 的 Middleware stack](#4424-添加-middleware-到-engine-的-middleware-stack)
    - [4.4.3 撰写 Engine 的 Generator](#443-撰写-engine-的-generator)
- [5. 测试 Engine](#5-测试-engine)
  - [5.1 功能性测试](#51-功能性测试)
- [6. 增进 Engine 的功能](#6-增进-engine-的功能)
  - [6.1 覆写 Model 与 Controller](#61-覆写-model-与-controller)
  - [6.2 关于 Decorator 与加载代码](#62-关于-decorator-与加载代码)
  - [6.3 用 `Class#class_eval` 来实现 Decorator 设计模式](#63-用-class#class_eval-来实现-decorator-设计模式)
  - [6.4 用 `ActiveSupport::Concern` 来实现 Decorator 设计模式](#64-用-activesupportconcern-来实现-decorator-设计模式)
  - [6.5 覆写 views](#65-覆写-views)
  - [6.6 路由](#66-路由)
    - [6.6.1 路由优先权](#661-路由优先权)
    - [6.6.2 重新命名 Engine Routing Proxy 方法](#662-重新命名-engine-routing-proxy-方法)
  - [6.7 Assets](#67-assets)
  - [6.8 宿主用不到的 Assets 与预编译](#68-宿主用不到的-assets-与预编译)
  - [6.9 Engine 依赖的 Gem](#69-engine-依赖的-gem)
- [延伸阅读](#延伸阅读)

# 1. Engine 是什么

Engine 可以想成是抽掉了某些功能的 Rails 应用程序： __微型的 Rails 应用程序__ 。可以安装到（mount）宿主，为宿主添加新功能。Rails 本身也是个 Engine，Rails 应用程序 `Rails::Application` 继承自 `Rails::Engine`，其实 Rails 不过就是个“强大的” Engine。

Rails 还有插件功能，插件跟 Engine 很像。两者都有 `lib` 目录结构，皆采用 `rails plugin new` 来产生 Engine 与插件。Engine 可以是插件；插件也可是 Engine。但还是不太一样，Engine 可以想成是“完整的插件”。

下面会用一个 `blorgh` Engine 的例子来讲解。这个 `blorgh` 给宿主提供了：新增文章（posts）、新增评论（comments），这两个功能。我们会先开发 Engine，再把 Engine 安装到应用程序。

假设路由里有 `posts_path` 这个 routing helper，宿主会提供这个功能、Engine 也会提供，这两者并不冲突。也就是说 Engine 可从宿主抽离出来。稍后会解释这是如何实现的。

__记住！宿主的优先权最高，Engine 不过给宿主提供新功能。__

以下皆是以 Rails Engine 实现的 RubyGems：

* [Devise](https://github.com/plataformatec/devise) 提供使用者验证功能。

* [Forem](https://github.com/radar/forem) 提供论坛功能。

* [Spree](https://github.com/spree/spree) 提供电子商务平台。

* [RefineryCMS](https://github.com/refinery/refinerycms) 内容管理系统。

* [Rails Admin](https://github.com/sferik/rails_admin) 内容管理系统。

* [Active Admin](https://github.com/sferik/active_admin) 内容管理系统。

## 1.1 Engine 开发简史

> 滚滚长江东逝水，<br>
> 浪花滔尽英雄。<br>
> 是非成败转头空。<br>
> 青山依旧在，几度夕阳红。<br>
> 白发渔樵江渚上，<br>
> 惯看秋月春风。<br>
> 一壶浊酒喜相逢。<br>
> 古今多少事，都付笑谈中。

James Adam 2005 年 10 月 31 日（万圣节）开始开发 Rails Engine，作为 plugin 的形式提交到 Rails（当时 Rails 的版本为 0.14.2），Kevin Smith 稍后写了一篇文章提到：

> Engine is also a nasty hack that breaks every new version of Rails because it hooks into internals that aren’t publicly supported.
> [Guide: Things You Shouldn't do in Rails by Kevin Smith ](http://glu.ttono.us/articles/2006/08/30/guide-things-you-shouldnt-be-doing-in-rails)

DHH 也说：

> I didn't want Rails to succumb to the lure of high-level components like login systems, forums, content management, and the likes.
> [The case against high-level components](http://david.heinemeierhansson.com/arc/000407.html)

DHH 又说：

> But the goal of Rails is to create a world where they are neither needed or strongly desired. Obviously, we are not quite there yet.
> [Why engines and components are not evil but distracting](http://weblog.rubyonrails.org/2005/11/11/why-engines-and-components-are-not-evil-but-distracting/)

...

> Engines have not received the blessing of the RoR core team, and I wouldn't expect any different, because it would be madness to include them in the
core Rails.
> [gmane.comp.lang.ruby.rails mailing list](http://article.gmane.org/gmane.comp.lang.ruby.rails/29166)

哇赛，Madness...这看起来像是 DHH 会讲的话，但是却是 Engine 作者 James Adam 自己说的。

历经了多少无数的编程夜晚，本来与 Rails 错综复杂各种核心功能，在 Rails 3.1 起，全都被抽离出来，变成 `Rails::Engine` 了，甚至 Rails 本身也是个 Engine：

```
# Rails 3.1+, try this in Pry or Irb.
require 'rails'
Rails::Application.superclass
=> Rails::Engine
```

Rails 3.2 Plugin 走入历史，Engine 正式当家。

Piotr Sarnacki 在 2010 Ruby Summer of Code 把 [Russian Doll Pattern](http://vimeo.com/4611379) 实现到 Rails Engine 里...

感谢 [James Adam](http://lazyatom.com/)、[Piotr Sarnacki](http://piotrsarnacki.com/)、Rails 核心成员及无数人员的辛苦努力，
没有他们就没有 Rails Engine！下次碰到他们记得感谢他们一下.....

__DHH 又再度被打脸了。__

## 1.2 Rails 2.x 使用 Engine

还在用 2.x? COOL. 可以用这个 Gem：

&nbsp;&nbsp;&nbsp;&nbsp; :point_right: &nbsp; [lazyatom/engines](https://github.com/lazyatom/engines)

# 2. 产生 Engine

用 plugin 产生器来产生 Engine（加上 `--mountable` 选项）：

```bash
$ rails plugin new blorgh --mountable
```

看看产生出来的 Engine 的目录结构：

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

`--help` 可查看完整说明：

```bash
$ rails plugin --help
```

让我们看看 `--full` 选项跟 `--mountable` 的差异，`--mountable` 多加了下列文件：

* Asset Manifest 文件（`application.css`、`application.js`）。
* Controller `application_controller.rb`。
* Helper `application_helper.rb`。
* layout 的 view 模版: `application.html.erb`。
* 命名空间与 Rails 应用程序分离的 `config/routes.rb`：

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

除了上述差异外，`--mountable` 还会把产生出来的 Engine 安装至 `test/dummy` 下的 Rails 应用程序，`test/dummy/config/routes.rb`:

```ruby
mount Blorgh::Engine, at: "blorgh"
```

## 2.1 Engine 里面有什么

Engine 目录结构：

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

### 2.1.1 重要的文件

__`blorgh.gemspec`__

当 Engine 开发完毕时，安装到宿主的时候，需要在宿主的 Gemfile 添加：

```ruby
gem 'blorgh', path: "vendor/engines/blorgh"
```

运行 `bundle install` 安装时，Bundler 会去解析 `blorgh.gemspec`，并安装其他相依的 Gems；同时，Bundler 会 require Engine `lib` 目录下的 `lib/blorgh.rb`，这个文件又 require 了 `lib/blorgh/engine.rb`，达到将 Engine 定义成 Module 的目的：

```ruby
# lib/blorgh/engine.rb
module Blorgh
  class Engine < ::Rails::Engine
    isolate_namespace Blorgh
  end
end
```

__`lib/blorgh/engine.rb` 可以放 Engine 的全局设定。__

Engine 继承自 `Rails::Engine`，告诉 Rails 说：嘿！这个目录下有个 Engine 呢！Rails 便知道该如何安装这个 Engine，并把 Engine `app` 目录下的 model、mailers、controllers、views 加载到 Rails 应用程序的 load path 里。

__`isolate_namespace` 方法非常重要！这把 Engine 的代码放到 Engine 的命名空间下，不与宿主冲突。__

加了这行，在我们开发 Engine，产生 model 时 `rails g model post` 便会将 model 放在对的命名空间下：

```
$ rails g model Post
invoke  active_record
create    db/migrate/20130921084428_create_blorgh_posts.rb
create    app/models/blorgh/post.rb
invoke    test_unit
create      test/models/blorgh/post_test.rb
create      test/fixtures/blorgh/posts.yml
```

数据库的 table 名称也会更改成 `blorgh_posts`。Controller 与 view 同理，都会被放在命名空间下。

想了解更多可看看 [`isolate_namespace` 的源码](https://github.com/rails/rails/blob/master/railties/lib/rails/engine.rb)：

### 2.1.2 `app` 目录

`app` 目录下有一般 Rails 应用程序里常见的 `assets`、`controllers`、`helpers`、`mailers`、`models`、`views`。

__`app/assets` 目录__

```
app/assets/
├── images
│   └── blorgh
├── javascripts
│   └── blorgh
│       └── application.js
└── stylesheets
    └── blorgh
        └── application.css
```

Engine 所需的 `images`、`javascripts`、`stylesheets`，皆放在 `blorgh` 下（命名空间分离）：

__`app/controllers` 目录__

Engine controller 的功能放这里。

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

命名成 `ApplicationController` 的原因，是让你能够轻松的将现有的 Rails 应用程序，抽离成 Engine。

__`app/views` 目录__

```
app/views/
└── layouts
    └── blorgh
        └── application.html.erb
```

Engine 的 layout 放这里。Engine 单独使用的话，就可以在这里改 layout，而不用到 Rails 应用程序的 `app/views/layouts/application.html.erb` 下修改。

要是不想要使用 Engine 的 layout，删除这个文件，并在 Engine 的 controller 指定你要用的 layout。

### 2.1.3 `bin` 目录

```
bin
└── rails
```

这让 Engine 可以像原本的 Rails 应用程序一样，用 `rails` 相关的命令。

### 2.1.4 `test` 目录

```
test
├── blorgh_test.rb
├── dummy
│   ├── README.rdoc
│   ├── Rakefile
│   ├── app
│   ├── bin
│   ├── config
│   ├── config.ru
│   ├── db
│   ├── lib
│   ├── log
│   ├── public
│   └── tmp
├── fixtures
│   └── blorgh
├── integration
│   └── navigation_test.rb
├── models
│   └── blorgh
└── test_helper.rb
```

关于 Engine 的测试放这里。里面还附了一个 `test/dummy` Rails 应用程序，供你测试 Engine，这个 dummy 应用程序已经装好了你正在开发的 Engine：

```ruby
Rails.application.routes.draw do
  mount Blorgh::Engine => "/blorgh"
end
```

__`test/integration`__

Engine 的整合测试（Integration test）放这里。其他相关的测试也可以放在这里，比如关于 controller 的测试（`test/controller`）、关于 model （`test/model`）的测试等。

# 3. 给 Engine 加功能

我们的 blorgh Engine，提供了 post 与 comment 的功能，跟 [Getting Started Guide](http://edgeguides.rubyonrails.org/getting_started.html) 功能差不多。

## 3.1 建立 post resource

先用脚手架产生 `Post` model：

```bash
$ rails generate scaffold post title:string text:text
```

会输出：

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

好，究竟产生了什么？一个一个看。

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

__注意，产生出来的文件都是放在 Engine 的命名空间下，因为我们有 `isolate_namespace Blorgh`__

* `invoke  active_record` 产生 migration 与 model。
* `invoke    text_unit` 产生该 model 的测试及假数据。
* `invoke  resource_route` 添加了一个 route 到 `config/routes.rb`：

    ```ruby
    resources :posts
    ```

* `invoke  scaffold_controller` 产生 controller：

    ```
    # Engine 目录下的 app/controllers/blorgh/posts_controller.rb
    require_dependency "blorgh/application_controller"

    module Blorgh
      class PostsController < ApplicationController
      ...
      end
    end
    ```

__注意这里继承的 `ApplicationController` 是 `Blorgh::ApplicationController`。__

__`require_dependency` 是 Rails 特有的方法，让你开发 Engine 时不用重启（开发模式下）。__

[require_dependency 源代码可在此找到](https://github.com/rails/rails/blob/master/activesupport/lib/active_support/dependencies.rb#L201)

* `invoke    erb` 产生 controller 相关的 views。
* `invoke    test_unit` 产生 controller 相关的测试。
* `invoke    helper` 产生 controller 相关的 helper。
* `invoke      test_unit` 产生 helper 的测试。
* `invoke  assets` 产生关于这个 resource 的 css 与 js。
* `invoke    js` 产生关于这个 resource 的 js
* `invoke    css` 产生关于这个 resource 的 css
* `invoke  css` scaffold 为这个 resource 产生的样式。

要载入 scaffold 产生的样式，添加下面这行到 `app/views/layouts/blorgh/application.html.erb`：

```erb
<%= stylesheet_link_tag "scaffold" %>
```

好了，可以运行我们熟悉的 `rake db:migrate` 了。并在 `test/dummy` 下运行 `rails server`：

```bash
$ test/dummy/bin/rails server
```

打开 [http://localhost:3000/blorgh/posts](http://localhost:3000/blorgh/posts) 看看刚刚用 scaffold 产生出来的 Post resource。

哇赛！你给 Engine 加了一个新功能了，自己掌声鼓励一下。

也可以用 `rails console`，不过要注意 model 的名称是 `Blorgh::Post`。

```ruby
>> Blorgh::Post.find(1)
=> #<Blorgh::Post id: 1 ...>
```

最后把 `root` 指向 `post` 的 `index` action 吧，修改 Engine 目录的 `config/routes.rb`：

```ruby
root to: "posts#index"
```

现在只要到 [http://localhost:3000/blorgh](http://localhost:3000/blorgh/) 就可以跳转到 [http://localhost:3000/blorgh/posts](http://localhost:3000/blorgh/posts) 了！

__这里的 `root` 是 Engine 的：`http://localhost:3000/blorgh/`__

## 3.2 产生 comment resource

好了，Engine 现在可以新增文章了！接下来加入评论功能。怎么加呢？先产生 comment model、comment controller 并修改由 scaffold 产生出的 post，让使用者可以浏览评论或新增评论。

一步一步来，从建立 `Comment` model 开始，每个 comment 都有与之关联的 post (`post_id`)：

```bash
$ rails generate model Comment post_id:integer text:text
```

会输出：

```
invoke  active_record
create    db/migrate/[timestamp]_create_blorgh_comments.rb
create    app/models/blorgh/comment.rb
invoke    test_unit
create      test/models/blorgh/comment_test.rb
create      test/fixtures/blorgh/comments.yml
```

同样，这都放在 Engine 的 Namespace 下。

migrate 我们的 comment model：

```bash
$ rake db:migrate
==  CreateBlorghComments: migrating ===========================================
-- create_table(:blorgh_comments)
   -> 0.0051s
==  CreateBlorghComments: migrated (0.0052s) ==================================
```

要在文章里显示评论，打开 `app/views/blorgh/posts/show.html.erb`，找到：

```erb
<%= link_to 'Edit', edit_post_path(@post) %> |
```

在这行之前添加：

```html+erb
<h3>Comments</h3>
<%= render @post.comments %>
```

`@post.comments` 会需要声明 Post 与 Comment 之间的关系。打开 `app/models/blorgh/post.rb`，添加 `has_many :comments`：

```ruby
module Blorgh
  class Post < ActiveRecord::Base
    has_many :comments
  end
end
```

好了，厉害的同学可能会问：「老师！为什么不用 `has_many` 里面的 `:class_name` 选项呢？」因为 model 是定义在 `Blorgh` Module 里面，Rails 自己就知道要用 `Blorgh::Comment` model 了哦 ^_^！

接下来新增在文章中添加评论的表单，打开 `app/views/blorgh/posts/show.html.erb`，添加这行到刚刚添加的 `render @post.comments` 下面：

```erb
<%= render "blorgh/comments/form" %>
```

但我们还没有新增这个 partial，首先新增目录：

```bash
$ mkdir -p app/views/blorgh/comments
```

并新增：

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

表单送出时，会对 `/posts/:post_id/comments/` 做 POST。目前还没有这条路由，让我们来添加一下，打开 `config/routes.rb`

```ruby
resources :posts do
  resources :comments
end
```

现在 model、路由有了，接著就是处理 route 的 controller 了：

```bash
$ rails g controller comments
```

会输出：

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

当表单送 POST 请求到 `/posts/:post_id/comments/` 时，controller （`Blorgh::CommentsController`）要有 `create` action 来回应，打开 `app/controllers/blorgh/comments_controller.rb`，并添加：

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

好了，新增评论的功能完成了！但...有点小问题，如果你试著要新增评论，则会看到下面这个错误：

```
Missing partial blorgh/comments/comment with {:handlers=>[:erb, :builder], :formats=>[:html], :locale=>[:en, :en]}. Searched in:
  * "/Users/yourname/parth-to-engine/blorgh/test/dummy/app/views"
  * "/Users/yourname/parth-to-engine/blorgh/app/views"
```

Engine 找不到 partial。因为 Rails 在 `test/dummy` 的 `app/views` 目录下面找，接著去 Engine 的 `app/views` 目录找，然后没找到！

但 Engine 知道要在 `blorgh/comments/comment` 找，因为 model 物件是从 `Blorgh:Comment` 传来的，好，那就新增 `app/views/blorgh/comments/_comment.html.erb` 并添加：

```erb
<%= comment_counter + 1 %>. <%= comment.text %> <br>
```

`comment_counter` 是从哪来的？ :point_right: `<%= render @post.comments %>`。

好了，评论功能做完了！

# 4. 安装至宿主

接下来讲解如何将 Engine 安装到宿主，并假设宿主有 `User` class，把我们的评论与文章功能添加到宿主的 User 上。

## 4.1 安装 Engine

首先产生一个宿主吧：

```bash
$ rails new unicorn
```

打开 Gemfile，添加 Devise：

```ruby
gem 'devise'
```

接著加入我们的 `blorgh` Engine：

```ruby
gem 'blorgh', path: "/path/to/blorgh"
```

记得 `bundle install` 安装。

接著添加 `blorgh` Engine 所需的路由，打开宿主的 `config/routes.rb`：

```ruby
mount Blorgh::Engine, at: "/blog"
```

`http://localhost:3000/blog` 就会交给我们的 Engine 处理。

## 4.2 Engine setup

接著要把 Engine 的 migration 拷贝到宿主这里，产生对应的 tables。Rails 已经帮我们提供了方便的命令：

```bash
$ rake blorgh:install:migrations
```

如果有多个 Engine 都要把 migration 拷贝过来，可以：

```bash
$ rake railties:install:migrations
```

__已经拷贝过的 migraiton 不会重复拷贝__


好了，有细心的同学又发问了：「老师！那拷贝过来，timestamp 不就是当初开发 Engine 的 Timestamp 吗？要是很久以前开发的 Engine，不就比我的应用程序的 migration 还早运行了吗？」呵呵，小朋友，Rails 也想到这件事了！

运行 `$ rake blorgh:install:migrations` 会输出：

```
Copied migration [timestamp_1]_create_blorgh_posts.rb from blorgh
Copied migration [timestamp_2]_create_blorgh_comments.rb from blorgh
```

`timestamp_1` 会是拷贝当下的时间，`timestamp_2` 会是现在时间加 1 秒，以此类推。

OK. 准备完毕，现在可以跑 migration 了：

```bash
rake db:migrate
```

打开 [http://localhost:3000/blog](http://localhost:3000/blog) 看看。

今天要是装了很多个 Engine，只想跑某个 Engine 的 migration 怎么办？

```bash
rake db:migrate SCOPE=blorgh
```

取消（Revert）Blorgh Engine 的 migration 呢？

```bash
rake db:migrate SCOPE=blorgh VERSION=0
```

## 4.3 使用宿主提供的类别

### 4.3.1 使用宿主提供的 model

好了，现在 `blorgh` 装起来了，现在看看 Engine 怎么跟宿主结合：帮我们的 post 与 comment 加上 author。

通常会用 `User` 来表示文章或评论的作者，但叫 `Person` 也不是不可以，Engine 在处理 model 关联时，不要硬编码成 `User`。之后讲解如何自定作者的类别名称。


这里为了保持简单，就用 `User` 当评论或文章的作者：

```bash
rails g model user name:string
```

记得运行 `rake db:migrate` 来产生 `users` table。

接著让我们来把新增文章的表单加上 `author_name`，Engine 会用这个名字来新增一个 `User` 物件，并把 `user` 与 `post` 关联起来。

新增 `author_name` text field 加到 Engine 的 `app/views/blorgh/posts/_form.html.erb` partial，加在 `title` 上面吧：

```html+erb
<div class="field">
  <%= f.label :author_name %><br>
  <%= f.text_field :author_name %>
</div>
```

接下来，更新 `Blorgh::PostController` 的 `post_params`：

```ruby
def post_params
  params.require(:post).permit(:title, :text, :author_name)
end
```

`Blorgh::Post` model 要能够把 `author_name` 转换成实际的 `User` 物件，并在 `post` 储存前，将该 `post` 与 `author` 关联起来。同时加上 `attr_accessor` 让我们可以 `author_name` 知道作者是谁以及修改作者，将 `app/models/blorgh/post.rb` 修改为：

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

接著处理 `blorgh_posts` table 与 `users` table 的关系。由于我们想要的是 `author`，所以要帮 `blorgh_posts` 加上 `author_id`，在 Engine 的根目录下运行：

```bash
$ rails g migration add_author_id_to_blorgh_posts author_id:integer
```
<!-- rails g migration add_author_id_to_blorgh_posts author_id:references -->

把 migration 拷贝到宿主：

```bash
$ rake blorgh:install:migrations
```

运行 migration：

```bash
$ rake db:migrate
```

现在作者（宿主：`users`）与文章（Engine：`blorgh_posts`）的关联做好了！

首页显示作者，打开 `app/views/blorgh/posts/index.html.erb`：

在这行 `<th>Title</th>` 上面添加：

```html
<th>Author</th>
```

并在 `<td><%= post.title %></td>` 上面添加：

```erb+html
<td><%= post.author %></td>
```

最后，在文章页面显示作者吧，打开 `app/views/blorgh/posts/show.html.erb`：

```html+erb
<p>
  <strong>Author:</strong>
  <%= @post.author %>
</p>
```

默认行为会输出：

```
#<User:0x00000100ccb3b0>
```

但我们要的是名字，添加 `to_s` 到 `User`：

```ruby
def to_s
  name
end
```

完成！

### 4.3.2 使用宿主提供的 controller

Rails controller 通常会共享一些功能，像是 authentication、session 变量，通常都从 `ApplicationController` 继承而来。Rails Engine，是独立运行在宿主之外，每个 Engine 有自己的 `ApplicationController` （在某个 scope 之下），像我们例子中的 `Blorgh::ApplicationController`。

但有时 Engine 需要宿主 `ApplicationController` 的某些功能，该怎么做呢？简单的办法是让 Engine 的继承自宿主的 `ApplicationController`：

将 `app/controllers/blorgh/application_controller.rb` 修改为

```ruby
class Blorgh::ApplicationController < ApplicationController
end
```

便可获得来自宿主 `ApplicationController` 的功能，这样看起来就像是宿主的某个 controller。

## 4.4 自定 `User` model

要是 `User` model 要换成别的名字怎么办？让我们看看，要怎么实现自定 `User` model 这个功能。

### 4.4.1 在宿主设定

Engine 可以加入一个设定，叫做 `author_class`，可以让使用 Engine 的人设定，他们的 “User” model 叫什么名字。

打开 Engine 目录下，`lib/blorgh.rb`，加入这行：

```ruby
mattr_accessor :author_class
```

`mattr_accessor` 跟 `attr_accessor` 与 `cattr_accessor` 很类似。可以 `Blorgh.author_class` 来存取。

下一步是修改 `Blorgh::Post` model：

```ruby
belongs_to :author, class_name: Blorgh.author_class
```

同时也得修改 `set_author` 方法：

```ruby
self.author = Blorgh.author_class.constantize.find_or_create_by(name: author_name)
```

但这样每次都得对 `author_class` 调用 `constantize`，可以覆写 `Blorgh` module 里面，`author_class` 的 getter 方法（`lib/blorgh.rb`）：

```ruby
def self.author_class
  @@author_class.constantize
end
```

这样刚刚的 `set_author` 方法便可以改成：

```ruby
self.author = Blorgh.author_class.find_or_create_by(name: author_name)
```

由于更改了 `author_class` 方法（永远回传 `Class` 物件），也得修改 `Blorgh::Post` 的 `belongs_to`：

```ruby
belongs_to :author, class_name: Blorgh.author_class.to_s
```

接著在宿主里新建一个 initializer。Initializer 可确保宿主在启动之前、或是调用任何 Engine 的 model 方法之前，会先套用我们的设定。

在宿主的根目录下，新建 `config/initializers/blorgh.rb`：

```ruby
Blorgh.author_class = "User"
```

__警告！用字串来设定，而不是直接使用 model。__

因为运行 initializer 的时候，model 可能还不存在。

接著试试新增一篇文章，看是不是跟之前一样可以用。但现在我们的 class 是可设定的，YA！

### 4.4.2 配置 Engine

initializer、i18n、或是做其他的设定，在 Engine 里怎么做呢？Engine 其实就是个微型的 Rails 应用程序，所以可以像是在 Rails 里面那般设定。

要设定 initializer，在 Engine 目录 `config/initializers` 新增你的设定即可。关于 initializer 的更多说明请参考 [Rails 官方文件的 Initalizers section](http://edgeguides.rubyonrails.org/configuring.html#initializers)

语系设定放在 Engine 目录下的 `config/locales` 即可。

就跟设定 Rails 应用程序一样。

#### 4.4.2.1 Initalizer 例子：Devise `devise_for`

用过 Devise 的同学可能在 `config/routes.rb` 都看过 `devise_for` ，大概是怎么实现的呢？

以下代码仅做示意之用，并非实际 Devise 的代码：

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

#### 4.4.2.2 变更 Engine 默认的 ORM、模版引擎、测试框架

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

__Rails 3.1 以前请使用 `config.generators`__

#### 4.4.2.3 变更 Engine 的名称

Engine 的名称在两个地方会用到：

* routes

`mount MyEngine::Engine => '/myengine'` 有默认的 default 选项 `:as`，

默认的名称便是 `as: 'engine_name'`

* 拷贝 migration 的 Rake task （如 `myengine:install:migrations`）

__如何变更？__

```ruby
module MyEngine
  class Engine < Rails::Engine
    engine_name "my_engine"
  end
end
```

#### 4.4.2.4 添加 Middleware 到 Engine 的 Middleware stack

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

### 4.4.3 撰写 Engine 的 Generator

让使用者轻松安装你的 Engine，比如：

```bash
$ rake generate blorgh:install
```

Generator 该怎么写呢？（示意）

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

# 5. 测试 Engine

产生 Engine 时，会顺便产生让你测试 Engine 用的 dummy 应用程序，放在 `test/dummy` 。可以给这个 dummy 应用程序加 controller、model、view 啦，用来测试 Engine。

`test` 数据夹就跟一般 Rails 测试一样有三种，分成单元、功能性、整合测试。

## 5.1 功能性测试

有点要提的是，要测试 Engine 的功能，测试在 `test/dummy` 下的应用程序运行，而不是直接在你撰写的 Engine 里。特别是与 controller 有关的测试，假设平常我们可以这样来测试 controller 的功能：

```ruby
get :index
```

但对 Engine 来说没用，因为应用程序不知道怎么把 request 传给 Engine，必须多给一个 `:user_route` 选项：

```ruby
get :index, use_route: :blorgh
```

# 6. 增进 Engine 的功能

本节讲解如何在宿主应用程序里，为 Engine 添加新功能，或是覆写 Engine 的功能。

## 6.1 覆写 Model 与 Controller

要扩展 Engine 的 model 与 controller，在宿主利用 Ruby 可打开某个类的特性，“打开”要修改的类别即可。通常会使用叫做 “decorator” 的设计模式。

简单的类别修改呢，可以用 `Class#class_eval`，复杂的修改用 `ActiveSupport::Concern`。

## 6.2 关于 Decorator 与加载代码

因为这些 `decorator` 是你加的，Rails 应用程序不知道他们在哪，Rails 的 autoload 不会自动帮你加载，也就是需要自己手工 `require`：

比如可以这样子加载（Engine 目录下的 `lib/blorgh/engine.rb`）：

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

不仅是 Decorator，任何你为 Engine 新增，而宿主无法参照的功能都可以。

## 6.3 用 `Class#class_eval` 来实现 Decorator 设计模式

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

**覆写** `Post#summary`

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

## 6.4 用 `ActiveSupport::Concern` 来实现 Decorator 设计模式

简单的改动用 `Class#class_eval` 就可以了，更复杂的情况，考虑看看使用 [`ActiveSupport::Concern`](http://edgeapi.rubyonrails.org/classes/ActiveSupport/Concern.html) 吧。

`ActiveSupport::Concern` 帮你处理错综复杂的 module 相依关系。

**添加** `Post#time_since_created` 并 **覆写** `Post#summary`

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

## 6.5 覆写 views

当 Rails 要渲染某个 view 时，会先从宿主的 `app/views` 找起，接著才是 Engine 的 `app/views`。

`Blorgh::PostController` 的 `index` action 运行时，首先会在宿主的 `app/views/blorgh/posts/index.html.erb` 寻找是否有 `index.html.erb`，接著才在自己的 `app/views/blorgh/posts/index.html.erb` 下寻找。

那要怎么覆写这个 view 呢？在宿主目录下新建 `app/views/blorgh/posts/index.html.erb`。试试看，并填入以下内容：

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

在 Engine 里定义的路由，默认下是与宿主定义的路由分离，确保两者之间不冲突。

假设今天，想要要是 erb 是从 Engine 渲染的，则存取 Engine 的 `posts_path`，要是从宿主，就去宿主的 `posts_path`：

```erb
<%= link_to "Blog posts", posts_path %>
```
这有可能会跳到 Engine 或是宿主的 `posts_path`。

Engine 与宿主的存取方法如下：

Engine 的 `posts_path` （这叫 routing proxy 方法，与 Engine 名字相同）：

```erb
<%= link_to "Blog posts", blorgh.posts_path %>
```

宿主的 `posts_path` （`Rails::Engine` 提供的 [`main_app`](http://edgeapi.rubyonrails.org/classes/Rails/Engine.html) helper）：

```erb
<%= link_to "Home", main_app.root_path %>
```

这可以拿来实现回首页的功能。

### 6.6.1 路由优先权

将 Engine 安装至宿主之后，就会有 2 个 router。让我们看下面这个例子：

```ruby
# host application
Rails.application.routes.draw do
  mount MyEngine::Engine => "/blog"
  get "/blog/omg" => "main#omg"
end
```

`MyEngine` 安装在 `/blog`，`/blog/omg` 会指向宿主的 `main` controller 的 `omg` action。当有 `/blog/omg` 有 request 进来时，会先到 `MyEngine`，要是 `MyEngine` 没有定义这条路由，则会转发给宿主的 `main#omg`。

改写成这样：

```ruby
Rails.application.routes.draw do
  get "/blog/omg" => "main#omg"
  mount MyEngine::Engine => "/blog"
end
```

则 Engine 只会处理宿主没有处理的 request。

### 6.6.2 重新命名 Engine Routing Proxy 方法

有两个地方可换 Engine 名字：

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

Assets 跟平常 Rails 应用程序的工作方式相同。记得 assets 也要放在命名空间下，避免冲突。比如 Engine 有 `style.css`，放在 `app/assets/stylesheets/[engine name]/style.css` 即可。

假设 Engine 有 `app/assets/stylesheets/blorgh/style.css`，在宿主怎么引用呢？用 `stylesheet_link_tag`：

```erb
<%= stylesheet_link_tag "blorgh/style.css" %>
```

Asset Pipeline 的 `require` 语句同样有效：

```
/*
 *= require blorgh/style
*/
```

要使用 Sass 或是 CoffeeScript，记得将这些 gem 加到 Engine 的 `[engine name].gemspec`。

## 6.8 宿主用不到的 Assets 与预编译

某些情况下宿主不需要用到 engine 的 assets。比如说针对 Engine 管理员的 `admin.css` 或 `admin.js`。只有 Engine 的 admin layout 需要这些 assets。这个情况下，可以在预编译里定义这些 assets，告诉 sprockets 要在 `rake assets:precompile` 加入 Engine 的 assets。

可以在 Engine 目录下的 `lib/blorgh/engine.rb`，定义要预编译的 assets：

```ruby
initializer "blorgh.assets.precompile" do |app|
  app.config.assets.precompile += %w(admin.css admin.js)
end
```

更多细节请阅读： [Asset Pipeline guide](http://edgeguides.rubyonrails.org/asset_pipeline.html)。

## 6.9 Engine 依赖的 Gem

Engine 依赖的 Gem 要在 `[engine name].gemspec` 里明确声明。因为 Engine 可能会被当成 gem 安装到宿主，把 Engine 依赖的 Gem 写在 Engine 的 `Gemfile`，不会像传统的 `gem install` 那样安装这些 Gem，进而导致你的 Engine 无法工作。

声明 Engine 运行会用到 Gem，打开 `[engine name].gemspec`，找到 `Gem::Specification` 区块：

```ruby
s.add_dependency "moo"
```

开发 Engine 会用到的 Gem：

```ruby
s.add_development_dependency "moo"
```

运行 `bundle install` 时会安装这些 Gem，而 development dependency 的 Gem 只有在跑 Engine 的测试时会被使用。

注意！若想在 Engine 被使用时，马上用某些相依的 Gem，要在 Engine 的 `engine.rb` 里明确 `require`：


```ruby
require 'other_engine/engine'
require 'yet_another_engine/engine'

module MyEngine
  class Engine < ::Rails::Engine
  end
end
```

# 延伸阅读

* Rails Conf 2013 Creating Mountable Engines
    - [slide](https://speakerdeck.com/peakpg/creating-mountable-engines)
    - [video](http://www.confreaks.com/videos/2476-railsconf2013-creating-mountable-engines)
* Rails Engines — Lesson Learned by Ryan Bigg | SpreeConf 2012
    - [slide](https://speakerdeck.com/radar/rails-engines-lessons-learned)
    - [video](http://www.youtube.com/watch?v=bHKZfIeAbds)
* [Integration Testing Engines by Ryan Bigg](https://speakerdeck.com/radar/integration-testing-engines)
* [#277 Mountable Engines - RailsCasts](http://railscasts.com/episodes/277-mountable-engines)
    - Railscasts 于 Rails 3.1.0.rc5 引入 Engine 的介绍。
* Rails in Actions 3 | Chapter 17 Rails Engine
