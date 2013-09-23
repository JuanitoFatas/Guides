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

最開始用 `rails` 指令時，其實就使用了 Rails Generator。查看完整 Rails Generator 的選項，輸入 `rails generate`：

```bash
$ rails new myapp
$ cd myapp
$ rails generate
```

便可查看 Rails 所有的 Generator。需要特定 generator 的詳細說明，比如 helper generator 的說明：

```bash
$ rails generate helper --help
```

# 2. 新增你的第一個 Generator

從 Rails 3.0 起，Generators 用 [Thor](https://github.com/erikhuda/thor)
重寫了。Thor 提供命令行選項的解析、具有強大的 API 來處理檔案。讓我們打造一個能在 `config/initializers` 目錄下產生 `initializer` 檔案（`initializer.rb`）的 Generator。

第一步先在 `lib/generators/initializer_generator.rb` 新建一個檔案，並填入如下內容：


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

並定義了一個方法：

```ruby
def create_initializer_file
  create_file "config/initializers/initializer.rb", "Add initialization content here"
end
```

當每個 Generator 被調用時，公有的方法會依定義的順序執行。最後，呼叫 `create_file` 方法，依據 `content` 填入內容（`"Add initialization content here"`）至指定位置（`"config/initializers/initializer.rb"`）。

如何使用我們自己寫的 Generator：

```bash
$ rails generate initializer
```

甚至還有指令說明！

```bash
$ rails generate initializer --help
```

如果 Generator 有適當的命名，比如 `ActiveRecord::Generators::ModelGenerator`，Rails 通常會幫你產生出不錯的指令敘述。當然也可自己寫敘述：用 `desc`：

```ruby
class InitializerGenerator < Rails::Generators::Base
  desc "This generator creates an initializer file at config/initializers"
  def create_initializer_file
    create_file "config/initializers/initializer.rb", "# Add initialization content here"
  end
end
```

另一種方式是將敘述寫在 `USAGE` 檔案裡，下節示範。

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

用 `--help` 看看我們說的對不對：

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

現在 `config/initializers/` 目錄下產生了 `core_extensions.rb`，內容為剛剛填入的內容。這也間接說明了，`copy_file` 在 `source_root` 指向的地方複製一個檔案。那 `file_name` 怎麼來的？由 `Rails::Generators::NamedBase` 類自動幫我們產生？

# 9. Generator 方法

下面是 Rails generator 與 template 內可用的方法：

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
