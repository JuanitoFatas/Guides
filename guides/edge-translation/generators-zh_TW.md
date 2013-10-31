# 客製與新增 Rails Generator 與 Template

__特別要強調的翻譯名詞__

> invoke 調用

> 不翻譯的名詞我用英文大寫，如 Generator、Template。

要改進工作流程，Rails Generators 是基本工具。
這篇指南教你如何自幹 Generator 、客製化 Rails 的 Generator。

讀完本篇可能會學到.....

* 知道應用程式裡有哪些 Generator 可用。
* 如何用 Template 產生 Generator。
* Rails 如何在調用 Generator 之前找到它們。
* 如何用新的 Generator 來客製化鷹架。
* 如何變更 Generator Template 來客製化鷹架。
* 如何用替代方案避免覆寫一大組 Generator。
* 如何新建應用程序 Template。

## 目錄

- [1. 初次接觸](#1-初次接觸)
- [2. 第一個 Generator](#2-第一個-generator)
- [3. 新建 Generator](#3-新建-generator)
- [4. Generators 查找順序](#4-generators-查找順序)
- [5. 客製化工作流程](#5-客製化工作流程)
- [6. 更改 Generator 的 Template 來客製化工作流程](#6-更改-generator-的-template-來客製化工作流程)
- [7. 加入 Generators 替代方案](#7-加入-generators-替代方案)
- [8. 應用程式 Templates](#8-應用程式-templates)
- [9. Generator 方法](#9-generator-方法)
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
- [延伸閱讀](#延伸閱讀)

# 1. 初次接觸

最開始用 `rails` 指令時，其實就使用了 Rails Generator。要查看 Rails 完整的 Generator 清單，輸入 `rails generate`：

```bash
$ rails new myapp
$ cd myapp
$ rails generate
```

需要特定 Generator 的詳細說明，比如 helper Generator 的說明，可以用 `--help`：

```bash
$ rails generate helper --help
```

# 2. 第一個 Generator

從 Rails 3.0 起，Generator 用 [Thor](https://github.com/erikhuda/thor)
重寫了。Thor 負責解析命令行參數、具有強大的檔案處理 API。輕輕鬆鬆便能打造一個 Generator，如何寫個能在 `config/initializers` 目錄下產生 `initializer` 檔案（`initializer.rb`）的 Generator 呢？

首先新建 `lib/generators/initializer_generator.rb` 檔案，填入如下內容：


```ruby
class InitializerGenerator < Rails::Generators::Base
  def create_initializer_file
    create_file "config/initializers/initializer.rb", "# Add initialization content here"
  end
end
```

注意：`create_file` 是 `Thor::Actions` 提供的方法。`create_file` 及其它 Thor 提供的方法請查閱 [Thor 的 API](http://rdoc.info/github/wycats/thor/master/Thor/Actions.html)。

讓我們來分析一下剛剛的 Generator。

從 `Rails::Generators::Base` 繼承而來：

```ruby
class InitializerGenerator < Rails::Generators::Base
```

定義了 `create_initializer_file` 方法：

```ruby
def create_initializer_file
  create_file "config/initializers/initializer.rb", "# Add initialization content here"
end
```

調用 Generator 時，公有的方法會依定義先後執行。最後，呼叫 `create_file` 方法，將 `"Add initialization content here"` 填入指定的檔案（`"config/initializers/initializer.rb"`）。

寫好了，如何使用？

```bash
$ rails generate initializer
```

才沒寫幾行程式碼，還附送指令說明！

```bash
$ rails generate initializer --help
```

如果 Generator 命名適當，比如 `ActiveRecord::Generators::ModelGenerator`，Rails 通常會產生出“堪用”的指令說明。當然也可自己寫，用 `desc`：

```ruby
class InitializerGenerator < Rails::Generators::Base
  desc "This generator creates an initializer file at config/initializers"
  def create_initializer_file
    create_file "config/initializers/initializer.rb", "# Add initialization content here"
  end
end
```

<!-- 另一種方式是將敘述寫在 `USAGE` 檔案裡，再讀進來。下節示範。 -->

# 3. 新建 Generator

新建 Generator：用 `rails generate` 指令。

```bash
$ rails generate generator initializer
      create  lib/generators/initializer
      create  lib/generators/initializer/initializer_generator.rb
      create  lib/generators/initializer/USAGE
      create  lib/generators/initializer/templates
```

剛產生的 Generator，`initializer`：

```ruby
class InitializerGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("../templates", __FILE__)
end
```

首先注意到我們從 `Rails::Generators::NamedBase` ，而不是前例的 `Rails::Generators::Base` 繼承而來。這表示 Generator 至少接受一個參數，來指定 `initializer` 的名字，讀入後存至 `name` 變數。

用 `--help` 看看是不是這樣：

```bash
$ rails generate initializer --help
Usage:
  rails generate initializer NAME [options]
```

`NAME` 便是需要傳入的參數。

`source_root` 指向 Generator Template 所在之處，預設指向 `lib/generators/initializer/templates` 目錄。

那什麼是 Generator Template？新建一個 `lib/generators/initializer/templates/initializer.rb` 檔案，並填入如下內容：

```ruby
# Add initialization content here
```

接著修改剛剛的 Generator，讓它在調用時，複製這個 Template：

```ruby
class InitializerGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("../templates", __FILE__)

  def copy_initializer_file
    copy_file "initializer.rb", "config/initializers/#{file_name}.rb"
  end
end
```

執行看看：

```bash
$ rails generate initializer core_extensions
```

現在 `config/initializers/` 目錄下產生了 `core_extensions.rb`，內容為剛剛填入的內容：

```ruby
# Add initialization content here
```

稍稍解釋下 `copy_file` 的用途：

`copy_file 來源檔案 目的檔案` 將位於 `source_root` 的`來源檔案`，複製到`目的檔案`。

```ruby
copy_file "initializer.rb", "config/initializers/#{file_name}.rb"
```

來源檔案：`"../templates/initializer.rb"`

目的檔案：`config/initializers/#{name}.rb`

`file_name` 方法怎麼來的？從 [`Rails::Generators::NamedBase` 繼承而來](https://github.com/rails/rails/blob/master/railties/lib/rails/generators/named_base.rb)

# 4. Generators 查找順序

執行 `rails generate initializer core_extensions` 時，Rails 怎麼知道要用哪個 Generator？查找順序如下：

```bash
rails/generators/initializer/initializer_generator.rb
generators/initializer/initializer_generator.rb
rails/generators/initializer_generator.rb
generators/initializer_generator.rb
```

直到找到對應的 Generator 為止，沒找到會回報錯誤訊息。

但是上節我們的 Generator 是在 `lib/generators/initializer/initializer_generator.rb` 這裡呀，沒在 Rails 的查找目錄裡啊？

這是因為 `lib` 屬於 `$LOAD_PATH`，Rails 會自動幫我們加載。

# 5. 客製化工作流程

Rails 原生的 Generator 非常靈活，可用來客製化鷹架。打開 `config/application.rb`，修改設定：

```ruby
config.app_generators do |g|
  g.orm             :active_record
  g.template_engine :erb
  g.test_framework  :test_unit, fixture: true
end
```

在客製化之前，先看看目前鷹架的輸出如何：

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

光看輸出就知道是怎回事了。鷹架 Generator 自己沒有產生東西，只是幫你調用（invoke）其它的 Generator。如此一來我們便可把調用的這些 Generator 換掉。

舉例來說，鷹架 Generator 調用了 scaffold_controller Generator、scaffold_controller 又調用了 erb、test_unit 及 helper Generator。

每個 Generator 各司其職，因此達到「重用性高，程式碼重複少」的目標。

假如我們不要產生樣式表、JS 檔案及假資料（fixture）。

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

現在再次執行：

```bash
$ rails generate scaffold User name:string
```

便不會產生假資料、樣式表、JS 檔案及單元測試。亦可把測試框架換成 RSpec；ORM 換成 DataMapper。

接著我們來自己做一個 helper Generator，幫 helper 裡，某些 instance variable 自動加入 reader。

首先新建這個 Generator，並放在 `rails` 命名空間下，以便 Rails 查找我們的 Generator：

```bash
$ rails generate generator rails/my_helper
```

接著，刪掉我們不需要的 `templates` 目錄：

```bash
$ rm -rf lib/generators/rails/my_helper/templates/
```


打開 `lib/generators/rails/my_helper/my_helper_generator.rb`，刪掉 `source_root` 這行。並添加下列程式碼：

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

現在產生 helper 看看：

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

現在讓鷹架使用我們寫的 helper Generator，編輯 `config/application.rb`：

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

再產生看看，是不是用了我們寫的 helper Generator：

```bash
$ rails generate scaffold Post body:text
      [...]
      invoke    my_helper
      create      app/helpers/posts_helper.rb
```

但好像少了什麼？測試！helper 的測試，讓我們修改剛剛的 Generator


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

現在調用 helper Generator 時，會試著去調用 `Rails::TestUnitGenerator` 與 `TestUnit::MyHelperGenerator`，由於我們沒有定義這兩個，所以得告訴 Rails，用 Rails 原生的 `TestUnit::Generators::HelperGenerator`。

```ruby
# Search for :helper instead of :my_helper
hook_for :test_framework, as: :helper
```

大功告成！

# 6. 更改 Generator 的 Template 來客製化工作流程

上例我們不過給 helper Generator 新增一行程式碼，沒加別的功能。其實還有更簡單的方法，即換掉 Rails helper Generator （`Rails::Generators::HelperGenerator`）原生的 Template。

Rails 3.0 之後，Generator 不僅會在 Template 的 `source_root` 查找，也會在其它路徑下，找看看有沒有 Template。現在讓我們來客製化 `Rails::Generators::HelperGenerator`，新增所需的目錄及檔案：

```bash
mkdir -p lib/templates/rails/helper
touch lib/templates/rails/helper/helper.rb
```

並填入如下內容：

```erb
module <%= class_name %>Helper
  attr_reader :<%= plural_name %>, :<%= plural_name.singularize %>
end
```

將上節 `config/application.rb` 的修改還原（刪除下面這段）：

```ruby
config.app_generators do |g|
  g.orm             :active_record
  g.template_engine :erb
  g.test_framework  :test_unit, fixture: false
  g.stylesheets     false
  g.javascripts     false
end
```

這與上例的效果相同。想客製化鷹架，


改 Template 在只想產生某些檔案的場景下很有用，比如鷹架只想產生 `edit.html.erb`、`index.html.erb`。

在 `lib/templates/erb/scaffold/` 目錄下新建 `index.html.erb` 與 `edit.html.erb`，填入想產生的內容即可。

可以參考：[自定義 Rails 的 Scaffold 模版提高開發效率 - 李华顺](http://huacnlee.com/blog/how-to-custom-scaffold-templates-in-rails3/)

# 7. 加入 Generators 替代方案

Generator 最後要加入的功能是替代方案（Fallbacks）。舉個例子，假設想在 `TestUnit` 加入像是 [shoulda](https://github.com/thoughtbot/shoulda) 的功能。由於 TestUnit 已實作所有 Rails Generators 需要的方法，而 Shoulda 不過是覆寫某部分功能，不需要為了 Shoulda 重新實作這些 Generators，可以告訴 Rails 在 `Shoulda` 命名空間下沒找到 Generator 時可以用 `TestUnit`


看看怎麼加入替代方案，打開 `config/application.rb`：

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

現在用鷹架新建 Comment resouce，會看到輸出裡有 `shoulda`，並使用替代的 TestUnit Generator：

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

Fallback 允許 Generator 各司其職、提高程式碼重用性、減少程式碼重複性。

# 8. 應用程式 Templates

現在已經會用 Generator 了，那想客製化產生出來的應用程式該怎麼做？透過應用程式 Templates 來實作。下面是 Templates API 的概要，詳細資訊請查閱 [Rails Application Templates guide](http://edgeguides.rubyonrails.org/rails_application_templates.html)。

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

上例中我們為產生的 Rails 應用程式新增了兩個 gem（`rspec-rails`、`cucumber-rails`），放在 `test` group，會自動加到 Gemfile。接著問使用者是否要安裝 Devise？若使用者回答 `y` 或 `yes`，則會把 `gem "devise"` 加到 Gemfile，並執行 `devise:install` generator，並詢問默認的用戶 model 名稱為？並產生出該 model。

現在將上面的程式碼存成 `template.rb`，便可以在 `rails new` 輸入 `-m` 選項來使用這個 Template：

```bash
$ rails new thud -m template.rb
```

這個指令會用給入的 Template 產生出 `Thud` 應用程式。

Template 也可存在網路上，如：

```bash
$ rails new thud -m https://gist.github.com/radar/722911/raw/
```

下一節會帶你走一遍 Template 與 Generator 可用的方法有哪些，這些方法組合起來有無窮的可能性。上吧，孩子！

了解更多關於 Application Template 的內容：[#148 App Templates in Rails 2.3 - RailsCasts](http://railscasts.com/episodes/148-app-templates-in-rails-2-3)

# 9. Generator 方法

以下是 Rails Generator 與 template 內可用的方法（[源碼](https://github.com/rails/rails/blob/master/railties/lib/rails/generators/actions.rb)）

關於 Thor 提供的方法請查閱 [Thor 的 API](http://rdoc.info/github/wycats/thor/master/Thor/Actions.html)。

### `gem`

聲明應用程式需要的 Gem。

```ruby
gem "rspec", group: "test", version: "2.1.0"
gem "devise", "1.1.5"
```

選項有：

* `:group` - Gem 所屬的群組。
* `:version` - Gem 的版本。也可放在第二個參數。
* `:git` - Gem 的 git repository URL。

任何其他的選項需放在行尾：

```ruby
gem "devise", git: "git://github.com/plataformatec/devise", branch: "master"
```

上面的程式碼會將下行寫入 `Gemfile`：

```ruby
gem "devise", git: "git://github.com/plataformatec/devise", branch: "master"
```

### `gem_group`

幫 Gem 分組：

```ruby
gem_group :development, :test do
  gem "rspec-rails"
end
```

### `add_source`

加入 Gem 的來源至 `Gemfile` ：

```ruby
add_source "http://gems.github.com"
```

### `inject_into_file`

注入一塊程式碼到檔案指定位置：

```ruby
inject_into_file 'name_of_file.rb', after: "#The code goes below this line. Don't forget the Line break at the end\n" do <<-'RUBY'
  puts "Hello World"
RUBY
end
```

### `gsub_file`

檔案內替換文字：

```ruby
gsub_file 'name_of_file.rb', 'method.to_be_replaced', 'method.the_replacing_code'
```

用正規表達式更簡潔。亦可用 `append_file` 及 `prepend_file` 來附加、插入程式碼到檔案裡。

### `application`

在 `config/application.rb` application 類別定義後面，新增一行程式碼。

```ruby
application "config.asset_host = 'http://example.com'"
```

接受區塊參數：

```ruby
application do
  "config.asset_host = 'http://example.com'"
end
```

可用選項：

* `:env` - 指定該設定針對的環境。也可用區塊語法：

```ruby
application(nil, env: "development") do
  "config.asset_host = 'http://localhost:3000'"
end
```

### `git`

執行特定 `git` 指令：

```ruby
git :init
git add: "."
git commit: "-m First commit!"
git add: "onefile.rb", rm: "badfile.cxx"
```

這裡傳的 hash 為傳給 `git` 指令的選項。一次可使用多個 `git` 指令， __但不保證執行的順序。__

### `vendor`

將含有特定程式碼的檔案，放入 `vendor` 目錄裡。

```ruby
vendor "sekrit.rb", '#top secret stuff'
```

接受區塊參數：

```ruby
vendor "seeds.rb" do
  "puts 'in ur app, seeding ur database'"
end
```

### `lib`

將含有特定程式碼的檔案，放入 `lib` 目錄裡。

```ruby
lib "special.rb", "p Rails.root"
```

接受區塊參數：

```ruby
lib "super_special.rb" do
  puts "Super special!"
end
```

### `rakefile`

在應用程式的 `lib/tasks` 新建一個 Rake 檔案：

```ruby
rakefile "test.rake", "hello there"
```

接受區塊參數：

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

在應用程式的 `config/initializers` 新建一個 initializer：

```ruby
initializer "begin.rb", "puts 'this is the beginning'"
```

接受區塊參數，並回傳字串

```ruby
initializer "begin.rb" do
  "puts 'this is the beginning'"
end
```

### `generate`

執行特定的 Generator，第一個參數為 Generator 的名字，其餘參數直接傳給 Generator。

```ruby
generate "scaffold", "forums title:string description:text"
```

### `rake`

執行特定的 Rake 任務。

```ruby
rake "db:migrate"
```

可用選項有：

* `:env` - 指定執行此 Rake 任務的環境。
* `:sudo` - 是否用 `sudo` 執行此任務，默認是 `false`。

### `capify!`

在應用程式根目錄執行 Capistrano 的 `capify` 指令（會產生出 Capistrano 的設定檔）。

```ruby
capify!
```

### `route`

新增一條路由至 `config/routes.rb`：

```ruby
route "resources :people"
```

### `readme`

在 console 裡印出 `source_path` 下指定檔案的內容。

```ruby
readme "README"
```

# 延伸閱讀

[#218 Making Generators in Rails 3 - RailsCasts](http://railscasts.com/episodes/218-making-generators-in-rails-3)

[#148 Custom App Generators (revised) - RailsCasts](http://railscasts.com/episodes/148-custom-app-generators-revised)
