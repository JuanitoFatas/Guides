Rails 命令行
======================

__特別要強調的翻譯名詞__

> Command Line ＝ 命令行

> Template ＝ 模版

讀完本篇可能會學到.....

* 新建 Rails 應用程式。
* 產生 models、controllers、資料庫 migrations、單元測試。
* 啟動開發伺服器。
* 用互動的 shell 對物件做實驗。
* 測量應用程式的瓶頸。

--------------------------------------------------------------------------------

1. 命令行基礎
-------------------

每天都會用到的 Rails 命令（按常用程度排序）：

* `rails console`
* `rails server`
* `rake`
* `rails generate`
* `rails dbconsole`
* `rails new app_name`

用 `-h` 或 `--help` 可獲得詳細說明。

用個簡單的 Rails 應用程式把每個命令都玩玩看。

### `rails new`

新建 Rails 應用程序。

如果還沒安裝 Rails，輸入 `gem install rails` 來安裝 Rails。

```bash
$ rails new commandsapp
      create
      create  README.rdoc
      create  Rakefile
      create  config.ru
      create  .gitignore
      create  Gemfile
      create  app
      create  app/assets/javascripts/application.js
      create  app/assets/stylesheets/application.css
      create  app/controllers/application_controller.rb
      create  app/helpers/application_helper.rb
      create  app/views/layouts/application.html.erb
      create  app/assets/images/.keep
      create  app/mailers/.keep
      create  app/models/.keep
      create  app/controllers/concerns/.keep
      create  app/models/concerns/.keep
      create  bin
      create  bin/bundle
      create  bin/rails
      create  bin/rake
      create  config
      create  config/routes.rb
      create  config/application.rb
      create  config/environment.rb
      create  config/environments
      create  config/environments/development.rb
      create  config/environments/production.rb
      create  config/environments/test.rb
      create  config/initializers
      create  config/initializers/backtrace_silencers.rb
      create  config/initializers/filter_parameter_logging.rb
      create  config/initializers/inflections.rb
      create  config/initializers/mime_types.rb
      create  config/initializers/secret_token.rb
      create  config/initializers/session_store.rb
      create  config/initializers/wrap_parameters.rb
      create  config/locales
      create  config/locales/en.yml
      create  config/boot.rb
      create  config/database.yml
      create  db
      create  db/seeds.rb
      create  lib
      create  lib/tasks
      create  lib/tasks/.keep
      create  lib/assets
      create  lib/assets/.keep
      create  log
      create  log/.keep
      create  public
      create  public/404.html
      create  public/422.html
      create  public/500.html
      create  public/favicon.ico
      create  public/robots.txt
      create  test/fixtures
      create  test/fixtures/.keep
      create  test/controllers
      create  test/controllers/.keep
      create  test/mailers
      create  test/mailers/.keep
      create  test/models
      create  test/models/.keep
      create  test/helpers
      create  test/helpers/.keep
      create  test/integration
      create  test/integration/.keep
      create  test/test_helper.rb
      create  tmp/cache
      create  tmp/cache/assets
      create  vendor/assets/javascripts
      create  vendor/assets/javascripts/.keep
      create  vendor/assets/stylesheets
      create  vendor/assets/stylesheets/.keep
         run  bundle install
```

Rails 會產生一大堆東西，都是 Rails 應用程式需要的檔案。

### `rails server`

`rails server` 命令會啟動 Ruby 內建的 WEBrick 伺服器。也可用別的伺服器，比如 passengers、puma、rainbows、thin、unicorn（按字母排序）。

```bash
$ cd commandsapp
$ rails server
=> Booting WEBrick
=> Rails 4.0.0 application starting in development on http://0.0.0.0:3000
=> Call with -d to detach
=> Ctrl-C to shutdown server
[2013-08-07 02:00:01] INFO  WEBrick 1.3.1
[2013-08-07 02:00:01] INFO  ruby 2.0.0 (2013-06-27) [x86_64-darwin11.2.0]
[2013-08-07 02:00:01] INFO  WEBrick::HTTPServer#start: pid=69680 port=3000
```

Server 啟動後，打開 [http://localhost:3000](http://localhost:3000) 來看看剛剛啟動的 Rails 應用程式。

`rails server` 可縮寫成 `rails s`。

`-p` 變更使用的埠口。

`-e` 變更使用的環境（production、development、test）

`-d` Rails 在背景執行（daemon）。

`-b` 綁定特定 IP。

```bash
$ rails server -e production -p 4000
```

完整的說明可輸入 `rails server --help`:

```
$ rails server -h
Usage: rails server [mongrel, thin, etc] [options]
    -p, --port=port                  Runs Rails on the specified port.
                                     Default: 3000
    -b, --binding=ip                 Binds Rails to the specified ip.
                                     Default: 0.0.0.0
    -c, --config=file                Use custom rackup configuration file
    -d, --daemon                     Make server run as a Daemon.
    -u, --debugger                   Enable the debugger
    -e, --environment=name           Specifies the environment to run this server under (test/development/production).
                                     Default: development
    -P, --pid=pid                    Specifies the PID file.
                                     Default: tmp/pids/server.pid

    -h, --help                       Show this help message.
```

### `rails generate`

`rails generate` 可查詢可用的 Generator:

```
$ rails generate
Usage: rails generate GENERATOR [args] [options]

General options:
  -h, [--help]     # Print generator's options and usage
  -p, [--pretend]  # Run but do not make any changes
  -f, [--force]    # Overwrite files that already exist
  -s, [--skip]     # Skip files that already exist
  -q, [--quiet]    # Suppress status output

Please choose a generator below.

Rails:
  assets
  controller
  generator
  helper
  integration_test
  jbuilder
  mailer
  migration
  model
  resource
  scaffold
  scaffold_controller
  task

Coffee:
  coffee:assets

Jquery:
  jquery:install

Js:
  js:assets

TestUnit:
  test_unit:plugin
```

比如我們來看看 controller generator 的說明：

```bash
$ rails generate controller
Usage:
  rails generate controller NAME [action action] [options]

Options:
      [--skip-namespace]        # Skip namespace (affects only isolated applications)
  -e, [--template-engine=NAME]  # Template engine to be invoked
                                # Default: erb
  -t, [--test-framework=NAME]   # Test framework to be invoked
                                # Default: test_unit
      [--helper]                # Indicates when to generate helper
                                # Default: true
      [--assets]                # Indicates when to generate assets
                                # Default: true

Runtime options:
  -f, [--force]    # Overwrite files that already exist
  -p, [--pretend]  # Run but do not make any changes
  -q, [--quiet]    # Suppress status output
  -s, [--skip]     # Skip files that already exist

Description:
    Stubs out a new controller and its views. Pass the controller name, either
    CamelCased or under_scored, and a list of views as arguments.

    To create a controller within a module, specify the controller name as a
    path like 'parent_module/controller_name'.

    This generates a controller class in app/controllers and invokes helper,
    template engine, assets, and test framework generators.

Example:
    `rails generate controller CreditCards open debit credit close`

    CreditCards controller with URLs like /credit_cards/debit.
        Controller: app/controllers/credit_cards_controller.rb
        Test:       test/controllers/credit_cards_controller_test.rb
        Views:      app/views/credit_cards/debit.html.erb [...]
        Helper:     app/helpers/credit_cards_helper.rb
```

讓我們看看這個命令，`rails generate controller NAME [action action] [options]`。

`rails generate controller` 代表 controller generator。

`NAME` 是 controller 的名字。

`[action action]` 是 controller 的 action，`[...]` 代表可有可無。

`[options]` 是可用的選項。

產生個 `Greetings` controller，內有 `hello` action：

```bash
$ rails generate controller Greetings hello
      create  app/controllers/greetings_controller.rb
       route  get "greetings/hello"
      invoke  erb
      create    app/views/greetings
      create    app/views/greetings/hello.html.erb
      invoke  test_unit
      create    test/controllers/greetings_controller_test.rb
      invoke  helper
      create    app/helpers/greetings_helper.rb
      invoke    test_unit
      create      test/helpers/greetings_helper_test.rb
      invoke  assets
      invoke    coffee
      create      app/assets/javascripts/greetings.js.coffee
      invoke    scss
      create      app/assets/stylesheets/greetings.css.scss
```

產生了 Greetings controller 以及需要的 view、test、js、css 檔案。

讓我們來實作 `hello` action：

```ruby
# app/controllers/greetings_controller.rb
class GreetingsController < ApplicationController
  def hello
    @message = "Hello, how are you today?"
  end
end
```

接著改改 view，來顯示這條 `@message`：

```erb
# app/views/greetings/hello.html.erb
<h1>A Greeting for You!</h1>
<p><%= @message %></p>
```

啟動伺服器：

```bash
$ rails server
=> Booting WEBrick...
```

打開 [http://localhost:3000/greetings/hello](http://localhost:3000/greetings/hello)，會看到 A Greeting for You!

URL 的 pattern：`http://(host)/(controller)/(action)`，比如 `http://localhost:3000/greetings/hello` 就觸發 Greetings controller 的 `hello` action、http://(host)/(controller) 會觸發 `index` action。

接著看看 model generotor:

```bash
$ rails generate model
Usage:
  rails generate model NAME [field[:type][:index] field[:type][:index]] [options]

Options:
      [--skip-namespace]  # Skip namespace (affects only isolated applications)
  -o, --orm=NAME          # Orm to be invoked
                          # Default: active_record

ActiveRecord options:
      [--migration]            # Indicates when to generate migration
                               # Default: true
      [--timestamps]           # Indicates when to generate timestamps
                               # Default: true
      [--parent=PARENT]        # The parent class for the generated model
      [--indexes]              # Add indexes for references and belongs_to columns
                               # Default: true
  -t, [--test-framework=NAME]  # Test framework to be invoked
                               # Default: test_unit

TestUnit options:
      [--fixture]                   # Indicates when to generate fixture
                                    # Default: true
  -r, [--fixture-replacement=NAME]  # Fixture replacement to be invoked

Runtime options:
  -f, [--force]    # Overwrite files that already exist
  -p, [--pretend]  # Run but do not make any changes
  -q, [--quiet]    # Suppress status output
  -s, [--skip]     # Skip files that already exist

Description:
    Stubs out a new model. Pass the model name, either CamelCased or
    under_scored, and an optional list of attribute pairs as arguments.

    Attribute pairs are field:type arguments specifying the
    model's attributes. Timestamps are added by default, so you don't have to
    specify them by hand as 'created_at:datetime updated_at:datetime'.

    You don't have to think up every attribute up front, but it helps to
    sketch out a few so you can start working with the model immediately.

    This generator invokes your configured ORM and test framework, which
    defaults to ActiveRecord and TestUnit.

    Finally, if --parent option is given, it's used as superclass of the
    created model. This allows you create Single Table Inheritance models.

    If you pass a namespaced model name (e.g. admin/account or Admin::Account)
    then the generator will create a module with a table_name_prefix method
    to prefix the model's table name with the module name (e.g. admin_account)

Available field types:

    Just after the field name you can specify a type like text or boolean.
    It will generate the column with the associated SQL type. For instance:

        `rails generate model post title:string body:text`

    will generate a title column with a varchar type and a body column with a text
    type. You can use the following types:

        integer
        primary_key
        decimal
        float
        boolean
        binary
        string
        text
        date
        time
        datetime
        timestamp

    You can also consider `references` as a kind of type. For instance, if you run:

        `rails generate model photo title:string album:references`

    It will generate an album_id column. You should generate this kind of fields when
    you will use a `belongs_to` association for instance. `references` also support
    the polymorphism, you could enable the polymorphism like this:

        `rails generate model product supplier:references{polymorphic}`

    For integer, string, text and binary fields an integer in curly braces will
    be set as the limit:

        `rails generate model user pseudo:string{30}`

    For decimal two integers separated by a comma in curly braces will be used
    for precision and scale:

        `rails generate model product price:decimal{10,2}`

    You can add a `:uniq` or `:index` suffix for unique or standard indexes
    respectively:

        `rails generate model user pseudo:string:uniq`
        `rails generate model user pseudo:string:index`

    You can combine any single curly brace option with the index options:

        `rails generate model user username:string{30}:uniq`
        `rails generate model product supplier:references{polymorphic}:index`


Examples:
    `rails generate model account`

        For ActiveRecord and TestUnit it creates:

            Model:      app/models/account.rb
            Test:       test/models/account_test.rb
            Fixtures:   test/fixtures/accounts.yml
            Migration:  db/migrate/XXX_create_accounts.rb

    `rails generate model post title:string body:text published:boolean`

        Creates a Post model with a string title, text body, and published flag.

    `rails generate model admin/account`

        For ActiveRecord and TestUnit it creates:

            Module:     app/models/admin.rb
            Model:      app/models/admin/account.rb
            Test:       test/models/admin/account_test.rb
            Fixtures:   test/fixtures/admin/accounts.yml
            Migration:  db/migrate/XXX_create_admin_accounts.rb
```
