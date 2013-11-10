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

URL 的 pattern：`http://(host)/(controller)/(action)`。

比如 `http://localhost:3000/greetings/hello` 會觸發 Greetings Controller 的 `hello` action。

`http://(host)/(controller)` 會觸發 `index` action。

接著看看 model generator:

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

NOTE: For a list of available field types, refer to the [API documentation](http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/TableDefinition.html#method-i-column) for the column method for the `TableDefinition` class.

But instead of generating a model directly (which we'll be doing later), let's set up a scaffold. A **scaffold** in Rails is a full set of model, database migration for that model, controller to manipulate it, views to view and manipulate the data, and a test suite for each of the above.

We will set up a simple resource called "HighScore" that will keep track of our highest score on video games we play.

```bash
$ rails generate scaffold HighScore game:string score:integer
    invoke  active_record
    create    db/migrate/20130717151933_create_high_scores.rb
    create    app/models/high_score.rb
    invoke    test_unit
    create      test/models/high_score_test.rb
    create      test/fixtures/high_scores.yml
    invoke  resource_route
     route    resources :high_scores
    invoke  scaffold_controller
    create    app/controllers/high_scores_controller.rb
    invoke    erb
    create      app/views/high_scores
    create      app/views/high_scores/index.html.erb
    create      app/views/high_scores/edit.html.erb
    create      app/views/high_scores/show.html.erb
    create      app/views/high_scores/new.html.erb
    create      app/views/high_scores/_form.html.erb
    invoke    test_unit
    create      test/controllers/high_scores_controller_test.rb
    invoke    helper
    create      app/helpers/high_scores_helper.rb
    invoke      test_unit
    create        test/helpers/high_scores_helper_test.rb
    invoke    jbuilder
    create      app/views/high_scores/index.json.jbuilder
    create      app/views/high_scores/show.json.jbuilder
    invoke  assets
    invoke    coffee
    create      app/assets/javascripts/high_scores.js.coffee
    invoke    scss
    create      app/assets/stylesheets/high_scores.css.scss
    invoke  scss
   identical    app/assets/stylesheets/scaffolds.css.scss
```

The generator checks that there exist the directories for models, controllers, helpers, layouts, functional and unit tests, stylesheets, creates the views, controller, model and database migration for HighScore (creating the `high_scores` table and fields), takes care of the route for the **resource**, and new tests for everything.

The migration requires that we **migrate**, that is, run some Ruby code (living in that `20130717151933_create_high_scores.rb`) to modify the schema of our database. Which database? The sqlite3 database that Rails will create for you when we run the `rake db:migrate` command. We'll talk more about Rake in-depth in a little while.

```bash
$ rake db:migrate
==  CreateHighScores: migrating ===============================================
-- create_table(:high_scores)
   -> 0.0017s
==  CreateHighScores: migrated (0.0019s) ======================================
```

INFO: Let's talk about unit tests. Unit tests are code that tests and makes assertions about code. In unit testing, we take a little part of code, say a method of a model, and test its inputs and outputs. Unit tests are your friend. The sooner you make peace with the fact that your quality of life will drastically increase when you unit test your code, the better. Seriously. We'll make one in a moment.

Let's see the interface Rails created for us.

```bash
$ rails server
```

Go to your browser and open [http://localhost:3000/high_scores](http://localhost:3000/high_scores), now we can create new high scores (55,160 on Space Invaders!)

### `rails console`

The `console` command lets you interact with your Rails application from the command line. On the underside, `rails console` uses IRB, so if you've ever used it, you'll be right at home. This is useful for testing out quick ideas with code and changing data server-side without touching the website.

INFO: You can also use the alias "c" to invoke the console: `rails c`.

You can specify the environment in which the `console` command should operate.

```bash
$ rails console staging
```

If you wish to test out some code without changing any data, you can do that by invoking `rails console --sandbox`.

```bash
$ rails console --sandbox
Loading development environment in sandbox (Rails 4.0.0)
Any modifications you make will be rolled back on exit
irb(main):001:0>
```

### `rails dbconsole`

`rails dbconsole` figures out which database you're using and drops you into whichever command line interface you would use with it (and figures out the command line parameters to give to it, too!). It supports MySQL, PostgreSQL, SQLite and SQLite3.

INFO: You can also use the alias "db" to invoke the dbconsole: `rails db`.

### `rails runner`

`runner` runs Ruby code in the context of Rails non-interactively. For instance:

```bash
$ rails runner "Model.long_running_method"
```

INFO: You can also use the alias "r" to invoke the runner: `rails r`.

You can specify the environment in which the `runner` command should operate using the `-e` switch.

```bash
$ rails runner -e staging "Model.long_running_method"
```

### `rails destroy`

`generate` 是 `destroy` 的逆操作（可以給 `generate` 做 ctrl+Z、cmd+Z）。


2. Rake
------------

Rake is Ruby Make, a standalone Ruby utility that replaces the Unix utility 'make', and uses a 'Rakefile' and `.rake` files to build up a list of tasks. In Rails, Rake is used for common administration tasks, especially sophisticated ones that build off of each other.

You can get a list of Rake tasks available to you, which will often depend on your current directory, by typing `rake --tasks`. Each task has a description, and should help you find the thing you need.

To get the full backtrace for running rake task you can pass the option
```--trace``` to command line, for example ```rake db:create --trace```.

```bash
$ rake --tasks
rake about              # List versions of all Rails frameworks and the environment
rake assets:clean       # Remove compiled assets
rake assets:precompile  # Compile all the assets named in config.assets.precompile
rake db:create          # Create the database from config/database.yml for the current Rails.env
...
rake log:clear          # Truncates all *.log files in log/ to zero bytes (specify which logs with LOGS=test,development)
rake middleware         # Prints out your Rack middleware stack
...
rake tmp:clear          # Clear session, cache, and socket files from tmp/ (narrow w/ tmp:sessions:clear, tmp:cache:clear, tmp:sockets:clear)
rake tmp:create         # Creates tmp directories for sessions, cache, sockets, and pids
```
INFO: You can also use ```rake -T```  to get the list of tasks.

### `about`

`rake about` gives information about version numbers for Ruby, RubyGems, Rails, the Rails subcomponents, your application's folder, the current Rails environment name, your app's database adapter, and schema version. It is useful when you need to ask for help, check if a security patch might affect you, or when you need some stats for an existing Rails installation.

```bash
$ rake about
About your application's environment
Ruby version              2.0.0 (x86_64-darwin10.8.0)
RubyGems version          2.1.5
Rack version              1.5
Rails version             4.0.0
JavaScript Runtime        Node.js (V8)
Active Record version     4.0.0
Action Pack version       4.0.0
Action Mailer version     4.0.0
Active Support version    4.0.0
Middleware                Rack::Sendfile, ActionDispatch::Static, Rack::Lock, #<ActiveSupport::Cache::Strategy::LocalCache::Middleware:0x00000105508d80>, Rack::Runtime, Rack::MethodOverride, ActionDispatch::RequestId, Rails::Rack::Logger, ActionDispatch::ShowExceptions, ActionDispatch::DebugExceptions, ActionDispatch::RemoteIp, ActionDispatch::Reloader, ActionDispatch::Callbacks, ActiveRecord::Migration::CheckPending, ActiveRecord::ConnectionAdapters::ConnectionManagement, ActiveRecord::QueryCache, ActionDispatch::Cookies, ActionDispatch::Session::CookieStore, ActionDispatch::Flash, ActionDispatch::ParamsParser, Rack::Head, Rack::ConditionalGet, Rack::ETag
Application root          /home/foobar/commandsapp
Environment               development
Database adapter          sqlite3
Database schema version   0
```

### `assets`

You can precompile the assets in `app/assets` using `rake assets:precompile` and remove those compiled assets using `rake assets:clean`.

### `db`

The most common tasks of the `db:` Rake namespace are `migrate` and `create`, and it will pay off to try out all of the migration rake tasks (`up`, `down`, `redo`, `reset`). `rake db:version` is useful when troubleshooting, telling you the current version of the database.

More information about migrations can be found in the [Migrations](migrations.html) guide.

### `doc`

The `doc:` namespace has the tools to generate documentation for your app, API documentation, guides. Documentation can also be stripped which is mainly useful for slimming your codebase, like if you're writing a Rails application for an embedded platform.

* `rake doc:app` generates documentation for your application in `doc/app`.
* `rake doc:guides` generates Rails guides in `doc/guides`.
* `rake doc:rails` generates API documentation for Rails in `doc/api`.

### `notes`

`rake notes` will search through your code for comments beginning with FIXME, OPTIMIZE or TODO. The search is done in files with extension `.builder`, `.rb`, `.erb`, `.haml` and `.slim` for both default and custom annotations.

```bash
$ rake notes
(in /home/foobar/commandsapp)
app/controllers/admin/users_controller.rb:
  * [ 20] [TODO] any other way to do this?
  * [132] [FIXME] high priority for next deploy

app/models/school.rb:
  * [ 13] [OPTIMIZE] refactor this code to make it faster
  * [ 17] [FIXME]
```

If you are looking for a specific annotation, say FIXME, you can use `rake notes:fixme`. Note that you have to lower case the annotation's name.

```bash
$ rake notes:fixme
(in /home/foobar/commandsapp)
app/controllers/admin/users_controller.rb:
  * [132] high priority for next deploy

app/models/school.rb:
  * [ 17]
```

You can also use custom annotations in your code and list them using `rake notes:custom` by specifying the annotation using an environment variable `ANNOTATION`.

```bash
$ rake notes:custom ANNOTATION=BUG
(in /home/foobar/commandsapp)
app/models/post.rb:
  * [ 23] Have to fix this one before pushing!
```

NOTE. When using specific annotations and custom annotations, the annotation name (FIXME, BUG etc) is not displayed in the output lines.

By default, `rake notes` will look in the `app`, `config`, `lib`, `bin` and `test` directories. If you would like to search other directories, you can provide them as a comma separated list in an environment variable `SOURCE_ANNOTATION_DIRECTORIES`.

```bash
$ export SOURCE_ANNOTATION_DIRECTORIES='spec,vendor'
$ rake notes
(in /home/foobar/commandsapp)
app/models/user.rb:
  * [ 35] [FIXME] User should have a subscription at this point
spec/models/user_spec.rb:
  * [122] [TODO] Verify the user that has a subscription works
```

### `routes`

`rake routes` 會列出已定義的 routes，用來追蹤 app 的 routing 問題或是看看 app 有什麼 routes。

### `test`

INFO: A good description of unit testing in Rails is given in [A Guide to Testing Rails Applications](testing.html)

Rails comes with a test suite called Minitest. Rails owes its stability to the use of tests. The tasks available in the `test:` namespace helps in running the different tests you will hopefully write.

### `tmp`

The `Rails.root/tmp` directory is, like the *nix /tmp directory, the holding place for temporary files like sessions (if you're using a file store for files), process id files, and cached actions.

The `tmp:` namespaced tasks will help you clear and create the `Rails.root/tmp` directory:

* `rake tmp:cache:clear` clears `tmp/cache`.
* `rake tmp:sessions:clear` clears `tmp/sessions`.
* `rake tmp:sockets:clear` clears `tmp/sockets`.
* `rake tmp:clear` clears all the three: cache, sessions and sockets.
* `rake tmp:create` creates tmp directories for sessions, cache, sockets, and pids.

### 其他

* `rake stats` is great for looking at statistics on your code, displaying things like KLOCs (thousands of lines of code) and your code to test ratio.
* `rake secret` will give you a pseudo-random key to use for your session secret.
* `rake time:zones:all` lists all the timezones Rails knows about.

### Custom Rake Tasks

Custom rake tasks have a `.rake` extension and are placed in
`Rails.root/lib/tasks`. You can create these custom rake tasks with the
`bin/rails generate task` command.

```ruby
desc "I am short, but comprehensive description for my cool task"
task task_name: [:prerequisite_task, :another_task_we_depend_on] do
  # All your magic here
  # Any valid Ruby code is allowed
end
```

To pass arguments to your custom rake task:

```ruby
task :task_name, [:arg_1] => [:pre_1, :pre_2] do |t, args|
  # You can use args from here
end
```

You can group tasks by placing them in namespaces:

```ruby
namespace :db do
  desc "This task does nothing"
  task :nothing do
    # Seriously, nothing
  end
end
```

Invocation of the tasks will look like:

```bash
rake task_name
rake "task_name[value 1]" # entire argument string should be quoted
rake db:nothing
```

NOTE: If your need to interact with your application models, perform database queries and so on, your task should depend on the `environment` task, which will load your application code.

3. The Rails Advanced Command Line
-------------------------------

More advanced use of the command line is focused around finding useful (even surprising at times) options in the utilities, and fitting those to your needs and specific work flow. Listed here are some tricks up Rails' sleeve.

### Rails with Databases and SCM

When creating a new Rails application, you have the option to specify what kind of database and what kind of source code management system your application is going to use. This will save you a few minutes, and certainly many keystrokes.

Let's see what a `--git` option and a `--database=postgresql` option will do for us:

```bash
$ mkdir gitapp
$ cd gitapp
$ git init
Initialized empty Git repository in .git/
$ rails new . --git --database=postgresql
      exists
      create  app/controllers
      create  app/helpers
...
...
      create  tmp/cache
      create  tmp/pids
      create  Rakefile
add 'Rakefile'
      create  README.rdoc
add 'README.rdoc'
      create  app/controllers/application_controller.rb
add 'app/controllers/application_controller.rb'
      create  app/helpers/application_helper.rb
...
      create  log/test.log
add 'log/test.log'
```

We had to create the **gitapp** directory and initialize an empty git repository before Rails would add files it created to our repository. Let's see what it put in our database configuration:

```bash
$ cat config/database.yml
# PostgreSQL. Versions 8.2 and up are supported.
#
# Install the pg driver:
#   gem install pg
# On OS X with Homebrew:
#   gem install pg -- --with-pg-config=/usr/local/bin/pg_config
# On OS X with MacPorts:
#   gem install pg -- --with-pg-config=/opt/local/lib/postgresql84/bin/pg_config
# On Windows:
#   gem install pg
#       Choose the win32 build.
#       Install PostgreSQL and put its /bin directory on your path.
#
# Configure Using Gemfile
# gem 'pg'
#
development:
  adapter: postgresql
  encoding: unicode
  database: gitapp_development
  pool: 5
  username: gitapp
  password:
...
...
```

It also generated some lines in our database.yml configuration corresponding to our choice of PostgreSQL for database.

NOTE. The only catch with using the SCM options is that you have to make your application's directory first, then initialize your SCM, then you can run the `rails new` command to generate the basis of your app.
