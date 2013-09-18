# 1. Rails Engine

__特別要強調的翻譯名詞__

> Web application ＝ Web 應用程式 ＝ 應用程式。

> host application ＝ 宿主。

--

本篇介紹 「Rails Engine」。怎麼優雅地把 Engine 掛到應用程式裡。

讀完本篇可能會學到：

  * 什麼是 Engine。

  * 如何產生 Engine。

  * 怎麼給 Engine 加功能。

  * 怎麼讓 Engine 與應用程式結合。

  * 在 application 裡覆寫 Engine 的功能。


# 1. What are engines?

Engine 可以想成小型的應用程式，可以給你的 web 應用程式（宿主）加新功能。`Rails::Application` 也是繼承自 `Rails::Engine`，Rails 其實只是個超強大的 Engine。

可以把 Engine 跟應用程式想成是一樣的東西，只不過有點微妙的差別。

Rails 還有 plugin，這跟 Engine 很像。兩者都有 `lib` 目錄結構，皆采用 `rails plugin new` 產生器。但還是不太一樣，Engine 可以想成是“完整的 plugin” （用產生器產生時要加上 `--full` 選項）。

接下來會用一個 “blorgh” 的 Engine 例子來講解。這個 “blorgh” 給宿主提供了新增 post、新增 comments 等功能。開始會先開發 Engine，接著再與應用程式結合。

假設路由裡有 `posts_path` 這個 routing helper，宿主會提供這個功能、Engine 也會提供，這兩者並不衝突。也就是說 Engine 可從宿主抽離出來。

__記住！宿主的優先權最高，Engine 不過給宿主提供新功能。__

有幾個 Rails Engine 的例子：

[Devise](https://github.com/plataformatec/devise) 提供使用者驗證功能。

[Forem](https://github.com/radar/forem) 提供論壇功能。

[Spree](https://github.com/spree/spree) 提供電子商務平台。

[RefineryCMS](https://github.com/refinery/refinerycms) 內容管理系統。

感謝 James Adam、Piotr Sarnacki、Rails 核心成員及無數人員的辛苦努力，沒有他們就沒有 Rails Engine！


# 2. 產生 Engine

用 plugin 產生器來產生 Engine（加上 `--mountable` 選項）：

```bash
$ rails plugin new blorgh --mountable
```

除了 `mountable` 選項，還有別的選項，完整選項可在 `--help` 裡找到：

```bash
$ rails plugin --help
```

The `--full` 選項告訴產生器option tells the generator that you want to create an engine, including a skeleton structure by providing the following:

  * An `app` directory tree
  * A `config/routes.rb` file:

    ```ruby
    Rails.application.routes.draw do
    end
    ```
  * A file at `lib/blorgh/engine.rb` which is identical in function to a standard Rails application's `config/application.rb` file:

    ```ruby
    module Blorgh
      class Engine < ::Rails::Engine
      end
    end
    ```

The `--mountable` option tells the generator that you want to create a "mountable" and namespace-isolated engine. This generator will provide the same skeleton structure as would the `--full` option, and will add:

  * Asset manifest files (`application.js` and `application.css`)
  * A namespaced `ApplicationController` stub
  * A namespaced `ApplicationHelper` stub
  * A layout view template for the engine
  * Namespace isolation to `config/routes.rb`:

    ```ruby
    Blorgh::Engine.routes.draw do
    end
    ```

  * Namespace isolation to `lib/blorgh/engine.rb`:

    ```ruby
    module Blorgh
      class Engine < ::Rails::Engine
        isolate_namespace Blorgh
      end
    end
    ```

Additionally, the `--mountable` option tells the generator to mount the engine inside the dummy testing application located at `test/dummy` by adding the following to the dummy application's routes file at `test/dummy/config/routes.rb`:

```ruby
mount Blorgh::Engine, at: "blorgh"
```

### Inside an engine

#### Critical files

At the root of this brand new engine's directory lives a `blorgh.gemspec` file. When you include the engine into an application later on, you will do so with this line in the Rails application's `Gemfile`:

```ruby
gem 'blorgh', path: "vendor/engines/blorgh"
```

Don't forget to run `bundle install` as usual. By specifying it as a gem within the `Gemfile`, Bundler will load it as such, parsing this `blorgh.gemspec` file and requiring a file within the `lib` directory called `lib/blorgh.rb`. This file requires the `blorgh/engine.rb` file (located at `lib/blorgh/engine.rb`) and defines a base module called `Blorgh`.

```ruby
require "blorgh/engine"

module Blorgh
end
```

TIP: Some engines choose to use this file to put global configuration options for their engine. It's a relatively good idea, and so if you want to offer configuration options, the file where your engine's `module` is defined is perfect for that. Place the methods inside the module and you'll be good to go.

Within `lib/blorgh/engine.rb` is the base class for the engine:

```ruby
module Blorgh
  class Engine < Rails::Engine
    isolate_namespace Blorgh
  end
end
```

By inheriting from the `Rails::Engine` class, this gem notifies Rails that there's an engine at the specified path, and will correctly mount the engine inside the application, performing tasks such as adding the `app` directory of the engine to the load path for models, mailers, controllers and views.

The `isolate_namespace` method here deserves special notice. This call is responsible for isolating the controllers, models, routes and other things into their own namespace, away from similar components inside the application. Without this, there is a possibility that the engine's components could "leak" into the application, causing unwanted disruption, or that important engine components could be overridden by similarly named things within the application. One of the examples of such conflicts are helpers. Without calling `isolate_namespace`, engine's helpers would be included in an application's controllers.

NOTE: It is **highly** recommended that the `isolate_namespace` line be left within the `Engine` class definition. Without it, classes generated in an engine **may** conflict with an application.

What this isolation of the namespace means is that a model generated by a call to `rails g model` such as `rails g model post` won't be called `Post`, but instead be namespaced and called `Blorgh::Post`. In addition, the table for the model is namespaced, becoming `blorgh_posts`, rather than simply `posts`. Similar to the model namespacing, a controller called `PostsController` becomes `Blorgh::PostsController` and the views for that controller will not be at `app/views/posts`, but `app/views/blorgh/posts` instead. Mailers are namespaced as well.

Finally, routes will also be isolated within the engine. This is one of the most important parts about namespacing, and is discussed later in the [Routes](#routes) section of this guide.

#### `app` directory

Inside the `app` directory are the standard `assets`, `controllers`, `helpers`, `mailers`, `models` and `views` directories that you should be familiar with from an application. The `helpers`, `mailers` and `models` directories are empty and so aren't described in this section. We'll look more into models in a future section, when we're writing the engine.

Within the `app/assets` directory, there are the `images`, `javascripts` and `stylesheets` directories which, again, you should be familiar with due to their similarity to an application. One difference here however is that each directory contains a sub-directory with the engine name. Because this engine is going to be namespaced, its assets should be too.

Within the `app/controllers` directory there is a `blorgh` directory and inside that a file called `application_controller.rb`. This file will provide any common functionality for the controllers of the engine. The `blorgh` directory is where the other controllers for the engine will go. By placing them within this namespaced directory, you prevent them from possibly clashing with identically-named controllers within other engines or even within the application.

NOTE: The `ApplicationController` class inside an engine is named just like a Rails application in order to make it easier for you to convert your applications into engines.

Lastly, the `app/views` directory contains a `layouts` folder which contains a file at `blorgh/application.html.erb` which allows you to specify a layout for the engine. If this engine is to be used as a stand-alone engine, then you would add any customization to its layout in this file, rather than the application's `app/views/layouts/application.html.erb` file.

If you don't want to force a layout on to users of the engine, then you can delete this file and reference a different layout in the controllers of your engine.

#### `bin` directory

This directory contains one file, `bin/rails`, which enables you to use the `rails` sub-commands and generators just like you would within an application. This means that you will very easily be able to generate new controllers and models for this engine by running commands like this:

```bash
rails g model
```

Keeping in mind, of course, that anything generated with these commands inside an engine that has `isolate_namespace` inside the `Engine` class will be namespaced.

#### `test` directory

The `test` directory is where tests for the engine will go. To test the engine, there is a cut-down version of a Rails application embedded within it at `test/dummy`. This application will mount the engine in the `test/dummy/config/routes.rb` file:

```ruby
Rails.application.routes.draw do
  mount Blorgh::Engine => "/blorgh"
end
```

This line mounts the engine at the path `/blorgh`, which will make it accessible through the application only at that path.

In the test directory there is the `test/integration` directory, where integration tests for the engine should be placed. Other directories can be created in the `test` directory as well. For example, you may wish to create a `test/models` directory for your models tests.