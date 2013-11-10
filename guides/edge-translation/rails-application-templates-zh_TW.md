Rails 應用程式模版
===========================

__特別要強調的翻譯名詞__

> Application Template ＝ 應用程式模版。

> Template ＝ 模版。模版

應用程式模版是一套用來給 Rails 專案添磚加瓦的 DSL。

讀完本篇可能會學到.....

* 怎麼使用模版來產生、客製化 Rails 應用程式。
* 如何用 Rails 模版 API 寫出可重用的應用程式模版。

--------------------------------------------------------------------------------

使用方式
---------

要套用模版需要告訴 Rails 模版放在哪。可放在本機（PATH）或是遠端（URL）。

```bash
$ rails new blog -m ~/template.rb
$ rails new blog -m http://example.com/template.rb
```

Rails 提供了 `rails:template` 這個 rake 任務，用來幫現有的 Rails 應用程式套版。模版的位置需傳入 `LOCATION` 變數。

```bash
$ rake rails:template LOCATION=~/template.rb
$ rake rails:template LOCATION=http://example.com/template.rb
```

模版 API
------------

模版 API 非常簡單，直接看個例子：

```ruby
# template.rb
generate(:scaffold, "person name:string")
route "root to: 'people#index'"
rake("db:migrate")

git :init
git add: "."
git commit: %Q{ -m 'Initial commit' }
```

下面為模版 API 的概覽：

### gem(*args)

加入 gem 至應用程式的 Gemfile。

```ruby
gem "nokogiri"
```

注意！加入至 Gemfile，並不會安裝它，需自己執行 `bundle install`。

```bash
bundle install
```

### gem_group(*names, &block)

幫 Gem 分組。

```ruby
gem_group :development, :test do
  gem "rspec-rails"
end
```

### add_source(source, options = {})

新增 Gem 的來源。

```ruby
add_source "http://ruby.taobao.org/"
```

### environment/application(data=nil, options={}, &block)

在 `config/application.rb` application 類別定義後面，新增一行程式碼。

Adds a line inside the `Application` class for `config/application.rb`.

If `options[:env]` is specified, the line is appended to the corresponding file in `config/environments`.

```ruby
environment 'config.action_mailer.default_url_options = {host: "http://yourwebsite.example.com"}', env: 'production'
```

A block can be used in place of the `data` argument.

### vendor/lib/file/initializer(filename, data = nil, &block)

Adds an initializer to the generated application's `config/initializers` directory.

Let's say you like using `Object#not_nil?` and `Object#not_blank?`:

```ruby
initializer 'bloatlol.rb', <<-CODE
  class Object
    def not_nil?
      !nil?
    end

    def not_blank?
      !blank?
    end
  end
CODE
```

Similarly, `lib()` creates a file in the `lib/` directory and `vendor()` creates a file in the `vendor/` directory.

There is even `file()`, which accepts a relative path from `Rails.root` and creates all the directories/files needed:

```ruby
file 'app/components/foo.rb', <<-CODE
  class Foo
  end
CODE
```

That'll create the `app/components` directory and put `foo.rb` in there.

### rakefile(filename, data = nil, &block)

Creates a new rake file under `lib/tasks` with the supplied tasks:

```ruby
rakefile("bootstrap.rake") do
  <<-TASK
    namespace :boot do
      task :strap do
        puts "i like boots!"
      end
    end
  TASK
end
```

The above creates `lib/tasks/bootstrap.rake` with a `boot:strap` rake task.

### generate(what, *args)

Runs the supplied rails generator with given arguments.

```ruby
generate(:scaffold, "person", "name:string", "address:text", "age:number")
```

### run(command)

Executes an arbitrary command. Just like the backticks. Let's say you want to remove the `README.rdoc` file:

```ruby
run "rm README.rdoc"
```

### rake(command, options = {})

Runs the supplied rake tasks in the Rails application. Let's say you want to migrate the database:

```ruby
rake "db:migrate"
```

You can also run rake tasks with a different Rails environment:

```ruby
rake "db:migrate", env: 'production'
```

### route(routing_code)

Adds a routing entry to the `config/routes.rb` file. In the steps above, we generated a person scaffold and also removed `README.rdoc`. Now, to make `PeopleController#index` the default page for the application:

```ruby
route "root to: 'person#index'"
```

### inside(dir)

Enables you to run a command from the given directory. For example, if you have a copy of edge rails that you wish to symlink from your new apps, you can do this:

```ruby
inside('vendor') do
  run "ln -s ~/commit-rails/rails rails"
end
```

### ask(question)

`ask()` gives you a chance to get some feedback from the user and use it in your templates. Let's say you want your user to name the new shiny library you're adding:

```ruby
lib_name = ask("What do you want to call the shiny library ?")
lib_name << ".rb" unless lib_name.index(".rb")

lib lib_name, <<-CODE
  class Shiny
  end
CODE
```

### yes?(question) or no?(question)

問問題，並獲得使用者輸入。yes?

These methods let you ask questions from templates and decide the flow based on the user's answer. Let's say you want to freeze rails only if the user wants to:

```ruby
rake("rails:freeze:gems") if yes?("Freeze rails gems?")
# no?(question) acts just the opposite.
```

### git(:command)

Rails templates let you run any git command:

```ruby
git :init
git add: "."
git commit: "-a -m 'Initial commit'"
```

進階用法
--------------

應用程式模版是在

舉例來說，

The application template is evaluated in the context of a
`Rails::Generators::AppGenerator` instance. It uses the `apply` action
provided by
[Thor](https://github.com/erikhuda/thor/blob/master/lib/thor/actions.rb#L207).
This means you can extend and change the instance to match your needs.

For example by overwriting the `source_paths` method to contain the
location of your template. Now methods like `copy_file` will accept
relative paths to your template's location.

```ruby
def source_paths
  [File.expand_path(File.dirname(__FILE__))]
end
```
