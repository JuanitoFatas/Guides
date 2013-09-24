# 客製與新增 Rails Generator 與 Template

__特別要強調的翻譯名詞__

> invoke 調用

> 不翻譯的名詞我用英文大寫，如 Generator、Template。

要改進工作流程，Rails Generators 是基本工具。
這篇指南教你如何自己做一個 Generator 及如何客製化現有的 Generator。

讀完本篇可能會學到.....

* 知道應用程式裡有哪些 Generator 可用。
* 如何用 Template 產生 Generator。
* Rails 如何在調用 Generator 之前找到它們。
* 如何用新的 Generator 來客製化鷹架。
* 如何變更 Generator Template 來客製化鷹架。
* 如何用替代方案避免覆寫一大組 Generator。
* 如何新建應用程序 Template。

## 目錄

# 1. 初次接觸

最開始用 `rails` 指令時，其實就使用了 Rails Generator。要查看 Rails 完整的 Generator 清單，輸入 `rails generate`：

```bash
$ rails new myapp
$ cd myapp
$ rails generate
```

需要特定 Generator 的詳細說明，比如 helper Generator 的說明：

```bash
$ rails generate helper --help
```

# 2. 新增你的第一個 Generator

從 Rails 3.0 起，Generator 用 [Thor](https://github.com/erikhuda/thor)
重寫了。Thor 提供命令行選項的解析、具有強大的檔案處理 API。讓我們打造一個能在 `config/initializers` 目錄下產生 `initializer` 檔案（`initializer.rb`）的 Generator。

第一步先新建 `lib/generators/initializer_generator.rb` 檔案，填入如下內容：


```ruby
class InitializerGenerator < Rails::Generators::Base
  def create_initializer_file
    create_file "config/initializers/initializer.rb", "# Add initialization content here"
  end
end
```

注意：`create_file` 是 `Thor::Actions` 提供的方法。`create_file` 及其它 Thor 提供的方法請查閱 [Thor 的 API](http://rdoc.info/github/wycats/thor/master/Thor/Actions.html)

讓我們來分析一下剛剛的產生器。

從 `Rails::Generators::Base` 繼承而來：

```ruby
class InitializerGenerator < Rails::Generators::Base
```

定義了一個方法：

```ruby
def create_initializer_file
  create_file "config/initializers/initializer.rb", "Add initialization content here"
end
```

調用每個 Generator 時，公有的方法會依定義的順序執行。最後，呼叫 `create_file` 方法，依據 `content` 填入內容（`"Add initialization content here"`）至指定位置（`"config/initializers/initializer.rb"`）。

如何使用我們自己寫的 Generator：

```bash
$ rails generate initializer
```

才沒寫幾行程式碼，還附送指令說明！

```bash
$ rails generate initializer --help
```

如果 Generator 有適當的命名，比如 `ActiveRecord::Generators::ModelGenerator`，Rails 通常會幫你產生出不錯的指令說明。當然也可自己寫，用 `desc`：

```ruby
class InitializerGenerator < Rails::Generators::Base
  desc "This generator creates an initializer file at config/initializers"
  def create_initializer_file
    create_file "config/initializers/initializer.rb", "# Add initialization content here"
  end
end
```

另一種方式是將敘述寫在 `USAGE` 檔案裡，再讀進來。下節示範。

# 3. 用 `rails generate` 指令來新建 Generator

```bash
$ rails generate generator initializer
      create  lib/generators/initializer
      create  lib/generators/initializer/initializer_generator.rb
      create  lib/generators/initializer/USAGE
      create  lib/generators/initializer/templates
```

這是我們剛產生的 Generator，`initializer`：

```ruby
class InitializerGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("../templates", __FILE__)
end
```

首先注意到我們從 `Rails::Generators::NamedBase` 而不是前例 `Rails::Generators::Base` 繼承而來。這表示我們的 Generator 至少接受一個參數，會是 `initializer` 的名字，並會存在 `name` 變數裡。

用 `--help` 看看是不是這樣：

```bash
$ rails generate initializer --help
Usage:
  rails generate initializer NAME [options]
```

`source_root` 指向 Generator Template 所在之處，預設指向 `lib/generators/initializer/templates` 目錄。

那什麼是 Generator Template？新建一個 `lib/generators/initializer/templates/initializer.rb` 檔案，並填入如下內容：

```ruby
# Add initialization content here
```

接著修改剛剛的 generator，讓它在調用時，複製這個新填入的 Template：

```ruby
class InitializerGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("../templates", __FILE__)

  def copy_initializer_file
    copy_file "initializer.rb", "config/initializers/#{file_name}.rb"
  end
end
```

現在執行我們的 Generator：

```bash
$ rails generate initializer core_extensions
```

現在 `config/initializers/` 目錄下產生了 `core_extensions.rb`，內容為剛剛填入的內容。


`copy_file 甲 乙`

將位於 `source_root` 的甲文件複製到乙。

甲：`"../templates/initializer.rb"`
甲：`config/initializers/#{file_name}.rb`

`file_name` 怎麼來的？`Rails::Generators::NamedBase` 自動會產生。

# 4. Generators 查找順序

執行 `rails generate initializer core_extensions` 時，Rails 檢查順序如下：

```bash
rails/generators/initializer/initializer_generator.rb
generators/initializer/initializer_generator.rb
rails/generators/initializer_generator.rb
generators/initializer_generator.rb
```

直到找到對應的 Generator 為止，沒找到會回報錯誤訊息。

上例將

但之前講新增 Generator ，怎把 Generator 放在 `lib` 目錄下？因為 `lib` 屬於 `$LOAD_PATH`，Rails 會自動幫我們加載。

# 5. 客製化工作流程

Rails 原生的 Generator 非常靈活，可讓你客製化鷹架。可在 `config/application.rb` 修改設定：

```ruby
config.app_generators do |g|
  g.orm             :active_record
  g.template_engine :erb
  g.test_framework  :test_unit, fixture: true
end
```

在客製化我們的工作流程之前，先看看現在 scaffold 的輸出如何：

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

光看輸出就知道是怎回事了。鷹架 Generator 自己沒有產生東西了，只是幫你調用其它的 Generator。如此一來我們便可把調用的這些 Generator 換掉。舉例來說，鷹架 Generator 調用 scaffold_controller Generator，scaffold_controller 又調用了 erb, test_unit 及 helper Generator。每個人各司其職，重用性高，程式碼重複小。

首先要對鷹架做的客製化，便是不要產生樣式表及假資料 (fixture)。

```ruby
# config/application.rb
config.app_generators do |g|
  g.orm             :active_record
  g.template_engine :erb
  g.test_framework  :test_unit, fixture: false
  g.stylesheets     false
end
```

現在再次執行 `$ rails generate scaffold User name:string` 便不會產生假資料、樣式表及單元測試。亦可把測試框架換成 RSpec、ORM 換成 DataMapper。

接著我們自己做一個 helper Generator，加入某些實例變數的 reader。首先新建這個 Generator，並放在 rails 命名空間下，以便 Rails 查找我們的 Generator：

```bash
$ rails generate generator rails/my_helper
```

接著，刪掉我們不需要的東西 `templates` 目錄：

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

現在產生個 helper 看看：

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

現在讓鷹架使用我們寫的這個 helper Generator，編輯 `config/application.rb`：

```ruby
config.generators do |g|
  g.orm             :active_record
  g.template_engine :erb
  g.test_framework  :test_unit, fixture: false
  g.stylesheets     false
  g.helper          :my_helper
end
```

再產生看看適不適用了我們寫的 helper Generator：

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

現在調用 helper Generator 時，會試著去調用 `Rails::TestUnitGenerator` 與 `TestUnit::MyHelperGenerator`，由於我們沒有定義這兩個，所以得告訴 Rails 用 Rails 原生的 `TestUnit::Generators::HelperGenerator`。

```ruby
# Search for :helper instead of :my_helper
hook_for :test_framework, as: :helper
```

大功告成！


# 9. Generator 方法

下面是 Rails Generator 與 template 內可用的方法：

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

檔案內替換文字

```ruby
gsub_file 'name_of_file.rb', 'method.to_be_replaced', 'method.the_replacing_code'
```

用正規表達式更簡潔。亦可用 `append_file` 及 `prepend_file` 來附加、插入程式碼到檔案裡。

### `application`

在 `config/application.rb` application 類別定義後面，直接新增一行程式碼。

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

hash 的數值為傳給 `git` 指令的參數或選項。一次可使用多個 `git` 指令， __但執行的順序不保證與你給入的相同。__

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

接受區塊參數，並回傳字串, expected to return a string:

```ruby
initializer "begin.rb" do
  "puts 'this is the beginning'"
end
```

### `generate`

執行特定的 generator，第一個參數為 generator 的名字，其餘參數直接傳給 generator。

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
* `:sudo` - 是否用 `sudo` 執行此任務，預設為 `false`。

### `capify!`

在應用程式根目錄執行 Capistrano 的 `capify` 指令（會產生出 Capistrano 的設定檔）。

```ruby
capify!
```

### `route`

新增文字至 `config/routes.rb`：

```ruby
route "resources :people"
```

### `readme`

輸出 README 檔案至 template `source_path`。

```ruby
readme "README"
```
