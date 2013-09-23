# 客製與新增 Rails Generator 與 Template

__特別要強調的翻譯名詞__

> invoke 調用

要改進工作流程，Rails Generators 是基本工具。
這篇指南教你如何自己做一個 generator 及如何客製化現有的 generator。

讀完本篇你可能會學到.....

* 知道應用程式裡有哪些 Generator 可用。
* 如何用 template 產生 generator。
* Rails 如何在調用 genrator 之前找到它們。
* 如何用新的 generator 來客製化鷹架。
* 如何變更 generator template 來客製化鷹架。
* 如何用替代方案避免覆寫一大組 generator
* 如何新建應用程序 template

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

* `:env` - Specifies the environment in which to run this rake task.
* `:sudo` - Whether or not to run this task using `sudo`. Defaults to `false`.

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
