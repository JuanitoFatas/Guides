# 定制与添加 Rails 生成器与模版

要改进工作流程，Rails 生成器是基本工具。
这篇指南教你如何自己写生成器、定制 Rails 的生成器。

读完本篇可能会学到.....

* 知道应用程序里有哪些生成器可用。
* 如何用模版生成生成器。
* Rails 如何在调用生成器之前找到它们。
* 如何用新的生成器来定制脚手架。
* 如何变更生成器模版来定制脚手架。
* 如何用替代方案避免覆写一大组生成器。
* 如何创建应用程序模版。

## 目录

- [1. 初次接触](#1-初次接触)
- [2. 第一个生成器](#2-第一个生成器)
- [3. 创建生成器](#3-创建生成器)
- [4.生成器查找顺序信息](#4生成器查找顺序信息)
- [5. 定制工作流程](#5-定制工作流程)
- [6. 更改生成器的模版来定制工作流程](#6-更改生成器的模版来定制工作流程)
- [7. 加入生成器替代方案](#7-加入生成器替代方案)
- [8. 应用程序模版](#8-应用程序模版)
- [9.生成器方法](#9生成器方法)
    - [`gem`](#gem)
    - [`gem_group`](#gem_group)
    - [`add_source`](#add_source)
    - [`inject_into_file`](#inject_into_file)
    - [`gsub_file`](#gsub_file)
    - [`application`](#application)
    - [`git`](#git)
    - [`vendor`](#vendor)
    - [`lib`](#lib)
    - [`rakefile`](#rakefile)
    - [`initializer`](#initializer)
    - [`generate`](#generate)
    - [`rake`](#rake)
    - [`capify!`](#capify!)
    - [`route`](#route)
    - [`readme`](#readme)
- [延伸阅读](#延伸阅读)

# 1. 初次接触

最开始用 `rails` 命令时，其实就使用了 Rails 生成器。要查看 Rails 完整的生成器清单，输入 `rails generate`：

```bash
$ rails new myapp
$ cd myapp
$ rails generate
```

需要特定生成器的详细说明，比如 helper 生成器的说明，可以用 `--help`：

```bash
$ rails generate helper --help
```

# 2. 第一个生成器

从 Rails 3.0 起，Generator 用 [Thor](https://github.com/erikhuda/thor)
重写了。Thor 负责解析命令行参数、具有强大的文件处理 API。轻轻松松便能打造一个生成器，如何写个能在 `config/initializers` 目录下生成 `initializer` 文件（`initializer.rb`）的生成器呢？

首先创建 `lib/generators/initializer_generator.rb` 文件，填入如下内容：


```ruby
class InitializerGenerator < Rails::Generators::Base
  def create_initializer_file
    create_file "config/initializers/initializer.rb", "# Add initialization content here"
  end
end
```

注意：`create_file` 是 `Thor::Actions` 提供的方法。`create_file` 及其它 Thor 提供的方法请查阅 [Thor 的 API](http://rdoc.info/github/wycats/thor/master/Thor/Actions.html)。

让我们来分析一下刚刚的生成器。

从 `Rails::Generators::Base` 继承而来：

```ruby
class InitializerGenerator < Rails::Generators::Base
```

定义了 `create_initializer_file` 方法：

```ruby
def create_initializer_file
  create_file "config/initializers/initializer.rb", "# Add initialization content here"
end
```

调用生成器时，公有的方法会依定义先后运行。最后，呼叫 `create_file` 方法，将 `"Add initialization content here"` 填入指定的文件（`"config/initializers/initializer.rb"`）。

写好了，如何使用？

```bash
$ rails generate initializer
```

才没写几行代码，还附送命令说明！

```bash
$ rails generate initializer --help
```

如果生成器命名适当，比如 `ActiveRecord::Generators::ModelGenerator`，Rails 通常会生出“还凑合”的命令说明。当然也可自己写，用 `desc`：

```ruby
class InitializerGenerator < Rails::Generators::Base
  desc "This generator creates an initializer file at config/initializers"
  def create_initializer_file
    create_file "config/initializers/initializer.rb", "# Add initialization content here"
  end
end
```

<!-- 另一种方式是将叙述写在 `USAGE` 文件里，再读进来。下节示范。 -->

# 3. 创建生成器

创建生成器：用 `rails generate` 命令。

```bash
$ rails generate generator initializer
      create  lib/generators/initializer
      create  lib/generators/initializer/initializer_generator.rb
      create  lib/generators/initializer/USAGE
      create  lib/generators/initializer/templates
```

刚生成的生成器，`initializer`：

```ruby
class InitializerGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("../templates", __FILE__)
end
```

首先注意到我们从 `Rails::Generators::NamedBase` ，而不是前例的 `Rails::Generators::Base` 继承而来。这表示生成器至少接受一个参数，来指定 `initializer` 的名字，读入后存至 `name` 变数。

用 `--help` 看看是不是这样：

```bash
$ rails generate initializer --help
Usage:
  rails generate initializer NAME [options]
```

`NAME` 便是需要传入的参数。

`source_root` 指向生成器模版所在之处，预设指向 `lib/generators/initializer/templates` 目录。

那什么是生成器模版？创建一个 `lib/generators/initializer/templates/initializer.rb` 文件，并填入如下内容：

```ruby
# Add initialization content here
```

接著修改刚刚的生成器，让它在调用时，拷贝这个模版：

```ruby
class InitializerGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("../templates", __FILE__)

  def copy_initializer_file
    copy_file "initializer.rb", "config/initializers/#{file_name}.rb"
  end
end
```

运行看看：

```bash
$ rails generate initializer core_extensions
```

现在 `config/initializers/` 目录下生成了 `core_extensions.rb`，内容为刚刚填入的内容：

```ruby
# Add initialization content here
```

稍稍解释下 `copy_file` 的用途：

`copy_file 来源文件 目的文件` 将位于 `source_root` 的`来源文件`，拷贝到`目的文件`。

```ruby
copy_file "initializer.rb", "config/initializers/#{file_name}.rb"
```

来源文件：`"../templates/initializer.rb"`

目的文件：`config/initializers/#{name}.rb`

`file_name` 方法怎么来的？ 从 [`Rails::Generators::NamedBase` 继承而来](https://github.com/rails/rails/blob/master/railties/lib/rails/generators/named_base.rb)。

# 4.生成器查找顺序信息

运行 `rails generate initializer core_extensions` 时，Rails 怎么知道要用哪个生成器？查找顺序如下：

```bash
rails/generators/initializer/initializer_generator.rb
generators/initializer/initializer_generator.rb
rails/generators/initializer_generator.rb
generators/initializer_generator.rb
```

直到找到对应的生成器为止，没找到会回报错误信息。

但是上节我们的生成器是在 `lib/generators/initializer/initializer_generator.rb` 这里呀，没在 Rails 的查找目录里啊？

这是因为 `lib` 属于 `$LOAD_PATH`，Rails 会自动帮我们加载。

# 5. 定制工作流程

Rails 自带的生成器非常灵活，可用来定制脚手架。打开 `config/application.rb`，修改配置：

```ruby
config.app_generators do |g|
  g.orm             :active_record
  g.template_engine :erb
  g.test_framework  :test_unit, fixture: true
end
```

在定制之前，先看看目前脚手架的输出如何：

```bash
$ rails generate scaffold User name:string
      invoke  active_record
      create    db/migrate/20130924121859_create_users.rb
      create    app/models/user.rb
      invoke    test_unit
      create      test/models/user_test.rb
      create      test/fixtures/users.yml
      invoke  resource_route
       route    resources :users
      invoke  scaffold_controller
      create    app/controllers/users_controller.rb
      invoke    erb
      create      app/views/users
      create      app/views/users/index.html.erb
      create      app/views/users/edit.html.erb
      create      app/views/users/show.html.erb
      create      app/views/users/new.html.erb
      create      app/views/users/_form.html.erb
      invoke    test_unit
      create      test/controllers/users_controller_test.rb
      invoke    helper
      create      app/helpers/users_helper.rb
      invoke      test_unit
      create        test/helpers/users_helper_test.rb
      invoke    jbuilder
      create      app/views/users/index.json.jbuilder
      create      app/views/users/show.json.jbuilder
      invoke  assets
      invoke    coffee
      create      app/assets/javascripts/users.js.coffee
      invoke    scss
      create      app/assets/stylesheets/users.css.scss
      invoke  scss
      create    app/assets/stylesheets/scaffolds.css.scss
```

光看输出就知道是咋回事了。脚手架生成器自己没有生成东西，只是帮你调用其它的生成器。如此一来我们便可把调用的这些生成器换掉。

举例来说，脚手架生成器调用了 scaffold_controller 生成器、scaffold_controller 又调用了 erb、test_unit 及 helper 生成器。

每个生成器各司其职，因此达到「重用性高，代码重复少」的目标。

假如我们不要生成样式表、JS 文件及假数据（fixture）。

```ruby
# config/application.rb
config.app_generators do |g|
  g.orm             :active_record
  g.template_engine :erb
  g.test_framework  :test_unit, fixture: false
  g.stylesheets     false
  g.javascripts     false
end
```

现在再次运行：

```bash
$ rails generate scaffold User name:string
```

便不会生成假数据、样式表、JS 文件及单元测试。亦可把测试框架换成 RSpec；ORM 换成 DataMapper。

接著我们来自己做一个 helper 生成器，帮 helper 里，某些实例变量自动加入 reader。

首先创建这个生成器，并放在 `rails` 命名空间下，以便 Rails 查找我们的生成器：

```bash
$ rails generate generator rails/my_helper
```

接著，删掉我们不需要的 `templates` 目录：

```bash
$ rm -rf lib/generators/rails/my_helper/templates/
```


打开 `lib/generators/rails/my_helper/my_helper_generator.rb`，删掉 `source_root` 这行。并添加下列代码：

```ruby
class Rails::MyHelperGenerator < Rails::Generators::NamedBase
  def create_helper_file
    create_file "app/helpers/#{file_name}_helper.rb", <<-FILE
module #{class_name}Helper
  attr_reader :#{plural_name}, :#{plural_name.singularize}
end
    FILE
  end
end
```

现在生成 helper 看看：

```bash
$ rails generate my_helper products
      create  app/helpers/products_helper.rb
```

啊哈，成功了！

```ruby
module ProductsHelper
  attr_reader :products, :product
end
```

现在让脚手架使用我们写的 helper 生成器，编辑 `config/application.rb`：

```ruby
config.app_generators do |g|
  g.orm             :active_record
  g.template_engine :erb
  g.test_framework  :test_unit, fixture: false
  g.stylesheets     false
  g.javascripts     false
  g.helper          :my_helper
end
```

再生成看看，是不是用了我们写的 helper 生成器：

```bash
$ rails generate scaffold Post body:text
      [...]
      invoke    my_helper
      create      app/helpers/posts_helper.rb
```

但好像少了什么？测试！helper 的测试，让我们修改刚刚的生成器


```ruby
# lib/generators/rails/my_helper/my_helper_generator.rb
class Rails::MyHelperGenerator < Rails::Generators::NamedBase
  def create_helper_file
    create_file "app/helpers/#{file_name}_helper.rb", <<-FILE
module #{class_name}Helper
  attr_reader :#{plural_name}, :#{plural_name.singularize}
end
    FILE
  end

  hook_for :test_framework
end
```

现在调用 helper 生成器时，会试著去调用 `Rails::TestUnitGenerator` 与 `TestUnit::MyHelperGenerator`，由于我们没有定义这两个，所以得告诉 Rails，用 Rails 自带的 `TestUnit::Generators::HelperGenerator`。

```ruby
# Search for :helper instead of :my_helper
hook_for :test_framework, as: :helper
```

大功告成！

# 6. 更改生成器的模版来定制工作流程

上例我们不过给 helper 生成器添加一行代码，没加别的功能。其实还有更简单的方法，即换掉 Rails helper 生成器（`Rails::Generators::HelperGenerator`）自带的模版。

Rails 3.0 之后，生成器不仅会在模版 的 `source_root` 查找，也会在其它路径下，找看看有没有模版。现在让我们来定制 `Rails::Generators::HelperGenerator`，添加所需的目录及文件：

```bash
mkdir -p lib/templates/rails/helper
touch lib/templates/rails/helper/helper.rb
```

并填入如下内容：

```erb
module <%= class_name %>Helper
  attr_reader :<%= plural_name %>, :<%= plural_name.singularize %>
end
```

将上节 `config/application.rb` 的修改还原（删除下面这段）：

```ruby
config.app_generators do |g|
  g.orm             :active_record
  g.template_engine :erb
  g.test_framework  :test_unit, fixture: false
  g.stylesheets     false
  g.javascripts     false
end
```

这与上例的效果相同。想定制脚手架，


改模版在只想生成某些文件的场景下很有用，比如脚手架只想生成 `edit.html.erb`、`index.html.erb`。

在 `lib/templates/erb/scaffold/` 目录下创建 `index.html.erb` 与 `edit.html.erb`，填入想生成的内容即可。

可以参考：[自定义 Rails 的 Scaffold 模板提高开发效率 - 李华顺](http://huacnlee.com/blog/how-to-custom-scaffold-templates-in-rails3/)

# 7. 加入生成器替代方案

生成器最后要加入的功能是替代方案（Fallbacks）。举个例子，假设想在 `TestUnit` 加入像是 [shoulda](https://github.com/thoughtbot/shoulda) 的功能。由于 TestUnit 已实现所有 Rails生成器s 需要的方法，而 Shoulda 不过是覆写某部分功能，不需要为了 Shoulda 重新实现这些生成器s，可以告诉 Rails 在 `Shoulda` 命名空间下没找到生成器时可以用 `TestUnit`

看看怎么加入替代方案，打开 `config/application.rb`：

```ruby
config.generators do |g|
  g.orm             :active_record
  g.template_engine :erb
  g.test_framework  :shoulda, fixture: false
  g.stylesheets     false
  g.javascripts     false

  # Add a fallback!
  g.fallbacks[:shoulda] = :test_unit
end
```

现在用脚手架创建 Comment resouce，会看到输出里有 `shoulda`，并使用替代的 TestUnit 生成器：

```bash
$ rails generate scaffold Comment body:text
      invoke  active_record
      create    db/migrate/20091120151323_create_comments.rb
      create    app/models/comment.rb
      invoke    shoulda
      create      test/models/comment_test.rb
      create      test/fixtures/comments.yml
      invoke  resource_route
       route    resources :comments
      invoke  scaffold_controller
      create    app/controllers/comments_controller.rb
      invoke    erb
      create      app/views/comments
      create      app/views/comments/index.html.erb
      create      app/views/comments/edit.html.erb
      create      app/views/comments/show.html.erb
      create      app/views/comments/new.html.erb
      create      app/views/comments/_form.html.erb
      invoke    shoulda
      create      test/controllers/comments_controller_test.rb
      invoke    my_helper
      create      app/helpers/comments_helper.rb
      invoke      shoulda
      create        test/helpers/comments_helper_test.rb
      invoke  assets
      invoke    coffee
      create      app/assets/javascripts/comments.js.coffee
      invoke    scss
```

Fallback 允许生成器各司其职、提高代码重用性、减少代码重复性。

# 8. 应用程序模版

现在已经会用生成器了，那想定制生出来的应用程序该怎么做？透过应用程序模版来实现。下面是模版 API 的概要，详细资讯请查阅 [Rails Application Templates guide](http://edgeguides.rubyonrails.org/rails_application_templates.html)。

```ruby
gem "rspec-rails", group: "test"
gem "cucumber-rails", group: "test"

if yes?("Would you like to install Devise?")
  gem "devise"
  generate "devise:install"
  model_name = ask("What would you like the user model to be called? [user]")
  model_name = "user" if model_name.blank?
  generate "devise", model_name
end
```

上例中我们为生成的 Rails 应用程序添加了两个 gem（`rspec-rails`、`cucumber-rails`），放在 `test` group，会自动加到 Gemfile。接著问使用者是否要安装 Devise？若使用者回答 `y` 或 `yes`，则会把 `gem "devise"` 加到 Gemfile，并运行 `devise:install` generator，并询问默认的用户 model 名称为？并生出该 model。

现在将上面的代码存成 `template.rb`，便可以在 `rails new` 输入 `-m` 选项来使用这个模版：

```bash
$ rails new thud -m template.rb
```

这个命令会用给入的模版 生出 `Thud` 应用程序。

模版也可存在网络上，如：

```bash
$ rails new thud -m https://gist.github.com/radar/722911/raw/
```

下一节会带你走一遍模版 与生成器可用的方法有哪些，这些方法组合起来有无穷的可能性。上吧，孩子！

了解更多关于应用程序模版 的内容：[#148 App Templates in Rails 2.3 - RailsCasts](http://railscasts.com/episodes/148-app-templates-in-rails-2-3)

# 9.生成器方法

以下是 Rails 生成器与模版内可用的方法（[源码](https://github.com/rails/rails/blob/master/railties/lib/rails/generators/actions.rb)）

关于 Thor 提供的方法请查阅 [Thor 的 API](http://rdoc.info/github/wycats/thor/master/Thor/Actions.html)。

### `gem`

声明应用程序需要的 Gem。

```ruby
gem "rspec", group: "test", version: "2.1.0"
gem "devise", "1.1.5"
```

选项有：

* `:group` - Gem 所属的群组。
* `:version` - Gem 的版本。也可放在第二个参数。
* `:git` - Gem 的 git repository URL。

任何其他的选项需放在行尾：

```ruby
gem "devise", git: "git://github.com/plataformatec/devise", branch: "master"
```

上面的代码会将下行写入 `Gemfile`：

```ruby
gem "devise", git: "git://github.com/plataformatec/devise", branch: "master"
```

### `gem_group`

帮 Gem 分组：

```ruby
gem_group :development, :test do
  gem "rspec-rails"
end
```

### `add_source`

加入 Gem 的来源至 `Gemfile` ：

```ruby
add_source "http://gems.github.com"
```

### `inject_into_file`

注入一块代码到文件指定位置：

```ruby
inject_into_file 'name_of_file.rb', after: "#The code goes below this line. Don't forget the Line break at the end\n" do <<-'RUBY'
  puts "Hello World"
RUBY
end
```

### `gsub_file`

文件内替换文字：

```ruby
gsub_file 'name_of_file.rb', 'method.to_be_replaced', 'method.the_replacing_code'
```

用正规表达式更简洁。亦可用 `append_file` 及 `prepend_file` 来附加、插入代码到文件里。

### `application`

在 `config/application.rb` application 类别定义后面，添加一行代码。

```ruby
application "config.asset_host = 'http://example.com'"
```

接受区块参数：

```ruby
application do
  "config.asset_host = 'http://example.com'"
end
```

可用选项：

* `:env` - 指定该配置针对的环境。也可用区块语法：

```ruby
application(nil, env: "development") do
  "config.asset_host = 'http://localhost:3000'"
end
```

### `git`

运行特定 `git` 命令：

```ruby
git :init
git add: "."
git commit: "-m First commit!"
git add: "onefile.rb", rm: "badfile.cxx"
```

这里传的 hash 为传给 `git` 命令的选项。一次可使用多个 `git` 命令， __但不保证运行的顺序。__

### `vendor`

将含有特定代码的文件，放入 `vendor` 目录里。

```ruby
vendor "sekrit.rb", '#top secret stuff'
```

接受区块参数：

```ruby
vendor "seeds.rb" do
  "puts 'in ur app, seeding ur database'"
end
```

### `lib`

将含有特定代码的文件，放入 `lib` 目录里。

```ruby
lib "special.rb", "p Rails.root"
```

接受区块参数：

```ruby
lib "super_special.rb" do
  puts "Super special!"
end
```

### `rakefile`

在应用程序的 `lib/tasks` 创建一个 Rake 文件：

```ruby
rakefile "test.rake", "hello there"
```

接受区块参数：

```ruby
rakefile "test.rake" do
  %Q{
    task rock: :environment do
      puts "Rockin'"
    end
  }
end
```

### `initializer`

在应用程序的 `config/initializers` 创建一个 initializer：

```ruby
initializer "begin.rb", "puts 'this is the beginning'"
```

接受区块参数，并返回字串：

```ruby
initializer "begin.rb" do
  "puts 'this is the beginning'"
end
```

### `generate`

运行特定的生成器，第一个参数为生成器的名字，其余参数直接传给生成器。

```ruby
generate "scaffold", "forums title:string description:text"
```

### `rake`

运行特定的 Rake 任务。

```ruby
rake "db:migrate"
```

可用选项有：

* `:env` - 指定运行此 Rake 任务的环境。
* `:sudo` - 是否用 `sudo` 运行此任务，默认是 `false`。

### `capify!`

在应用程序根目录运行 Capistrano 的 `capify` 命令（会生出 Capistrano 的配置文件）。

```ruby
capify!
```

### `route`

添加一条路由至 `config/routes.rb`：

```ruby
route "resources :people"
```

### `readme`

在 console 里印出 `source_path` 下指定文件的内容。

```ruby
readme "README"
```

# 延伸阅读

[#218 Making Generators in Rails 3 - RailsCasts](http://railscasts.com/episodes/218-making-generators-in-rails-3)

[#148 Custom App Generators (revised) - RailsCasts](http://railscasts.com/episodes/148-custom-app-generators-revised)
