# A Guide for Upgrading Ruby on Rails

本篇講升級至新版 Rails 所需的步驟。同時也提供各版本的升級指導。

# 1. 一般建議

升級前先想好為何要升級：需要新功能？舊代碼越來越難維護？有多少時間？有能力解決升級的兼容問題嗎？等等。

## 1.1 測試覆蓋度

最好的方式來確保應用程式升級後仍然正常工作，便是有廣的測試覆蓋度。若沒有撰寫測試，將會花上許多時間，來處理升級帶來的新變化。在升級前，先確保測試覆蓋得夠廣吧！

## 1.2 Ruby 版本

Rails 通常與最新的 Ruby 一起前進：

* Rails 3 以上需要高於 1.8.7 版本的 Ruby。
* Rails 3.2.x 是最後支持 Ruby 1.8.7 的版本。
* Rails 4 推薦使用 Ruby 2.0。

講個秘訣：Ruby 1.8.7 p248 與 p249 有 marshaling bugs，會讓 Rails 無預警的 crash。REE 從 1.8.7-2010.02 之後的版本已經修正了這個問題。關於 Ruby 1.9，不要使用 1.9.1，有 segfaults 的問題，1.9 就用 1.9.3 吧。

定案：

* Ruby 2.0.0-p247（__強烈推薦使用__）
* Ruby 1.9.3-p448

> [Ruby 1.8.7（官方已經不維護了）](https://www.ruby-lang.org/zh_tw/news/2013/06/30/we-retire-1-8-7/)

## 1.3 HTTP PATCH

Rails 4 更新操作的主要 HTTP 動詞換成了 `PATCH`。當你在 `config/routes.rb` 以 _RESTful_ 形式宣告某個 resource 時，`PUT` 仍會路由到 `update` action，只是多了個 `PATCH` ，同樣路由到 `update` action。

> 這裡的路由作動詞解。

```ruby
resources :users
```

```erb
<%= form_for @user do |f| %>
```

```ruby
class UsersController < ApplicationController
  def update
    # 代碼不用改；偏好使用 PATCH，PUT 仍然可用。
  end
end
```

但是，當使用 `form_for` 來更新自定路由（使用 `PUT` HTTP 動詞）的 resource 時，

```ruby
resources :users, do
  put :update_name, on: :member
end
```

```erb
<%= form_for [ :update_name, @user ] do |f| %>
```

```ruby
class UsersController < ApplicationController
  def update_name
    # 要修改代碼；form_for 會試著使用不存在的 PATCH 路由。
  end
end
```

若不是公有的 API，你可換 HTTP 動詞，那就把它從 `PUT` 改成 `PATCH` 吧。

在 Rails 4 對 `/users/:id` 做 `PUT` 請求，會被導向 `update`。所以要是 API 接受 `PUT` 請求，那沒問題。Router 同時也會將來自 `/users/:id` 的 `PATCH` 請求導向 `update` action。

```ruby
resources :users do
  patch :update_name, on: :member
end
```

若此 action 正被公有的 API 使用，且你無法更改 HTTP 動詞時，可更新 form，使用 `PUT` 動詞：

```erb
<%= form_for [ :update_name, @user ], method: :put do |f| %>
```

至於為什麼要改成 `PATCH`，參考[這篇文章](http://weblog.rubyonrails.org/2012/2/25/edge-rails-patch-is-the-new-primary-http-method-for-updates/)。

#### 關於 media types 的說明

<!-- The errata for the `PATCH` verb [specifies that a 'diff' media type should be
used with `PATCH`](http://www.rfc-editor.org/errata_search.php?rfc=5789). One
such format is [JSON Patch](http://tools.ietf.org/html/rfc6902). While Rails
does not support JSON Patch natively, it's easy enough to add support:
 -->

[RFC 5789 的勘誤](http://www.rfc-editor.org/errata_search.php?rfc=5789)表示某些 media type 要用 `PATCH` 動詞才正確，比如 JSON Patch。

Rails 沒有原生支持 JSON Patch，但添加 JSON Patch 的支持非常簡單：

```
# 在 controller
def update
  respond_to do |format|
    format.json do
      # perform a partial update
      @post.update params[:post]
    end

    format.json_patch do
      # perform sophisticated change
    end
  end
end

# 在 config/initializers/json_patch.rb:
Mime::Type.register 'application/json-patch+json', :json_patch
```

由於 JSON Patch 最近才有 RFC，仍未有好的 Ruby 函式庫出現。Aaron Patterson 的 [hana](https://github.com/tenderlove/hana) 是一個實作 JSON Patch 的 gem，但仍未完整支援 Spec 裡所有最近更新的內容。

# 2. 從 Rails 3.2 升級到 Rails 4.0

__注意：本小節仍在施工當中。__

若你是 3.2 先前的版本，先升到 3.2 再試著升到 Rails 4.0。

以下是針對升級至 Rails 4.0 的說明。

### Gemfile

Rails 4.0 移除了 Gemfile 裡的 `assets` group。升級至 4.0 時要移除這個 group，同時需要更新 `config/application.rb`：

```ruby
# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)
```

### vendor/plugins

Rails 4.0 不再支援從 `vendor/plugins` 載入 plugins。 __必須__將任何 plugins 包成 Gems ，再加入至 Gemfile。

Rails 4.0 no longer supports loading plugins from `vendor/plugins`. You must replace any plugins by extracting them to gems and adding them to your Gemfile. If you choose not to make them gems, you can move them into, say, `lib/my_plugin/*` and add an appropriate initializer in `config/initializers/my_plugin.rb`.

### Active Record

* Rails 4.0 has removed the identity map from Active Record, due to [some inconsistencies with associations](https://github.com/rails/rails/commit/302c912bf6bcd0fa200d964ec2dc4a44abe328a6). If you have manually enabled it in your application, you will have to remove the following config that has no effect anymore: `config.active_record.identity_map`.

* The `delete` method in collection associations can now receive `Fixnum` or `String` arguments as record ids, besides records, pretty much like the `destroy` method does. Previously it raised `ActiveRecord::AssociationTypeMismatch` for such arguments. From Rails 4.0 on `delete` automatically tries to find the records matching the given ids before deleting them.

* In Rails 4.0 when a column or a table is renamed the related indexes are also renamed. If you have migrations which rename the indexes, they are no longer needed.

* Rails 4.0 has changed `serialized_attributes` and `attr_readonly` to class methods only. You shouldn't use instance methods since it's now deprecated. You should change them to use class methods, e.g. `self.serialized_attributes` to `self.class.serialized_attributes`.

* Rails 4.0 has removed `attr_accessible` and `attr_protected` feature in favor of Strong Parameters. You can use the [Protected Attributes gem](https://github.com/rails/protected_attributes) for a smooth upgrade path.

* If you are not using Protected Attributes, you can remove any options related to
this gem such as `whitelist_attributes` or `mass_assignment_sanitizer` options.

* Rails 4.0 requires that scopes use a callable object such as a Proc or lambda:

```ruby
  scope :active, where(active: true)

  # becomes
  scope :active, -> { where active: true }
```

* Rails 4.0 has deprecated `ActiveRecord::Fixtures` in favor of `ActiveRecord::FixtureSet`.

* Rails 4.0 has deprecated `ActiveRecord::TestCase` in favor of `ActiveSupport::TestCase`.

* Rails 4.0 has deprecated the old-style hash based finder API. This means that
  methods which previously accepted "finder options" no longer do.

* All dynamic methods except for `find_by_...` and `find_by_...!` are deprecated.
  Here's how you can handle the changes:

      * `find_all_by_...`           becomes `where(...)`.
      * `find_last_by_...`          becomes `where(...).last`.
      * `scoped_by_...`             becomes `where(...)`.
      * `find_or_initialize_by_...` becomes `find_or_initialize_by(...)`.
      * `find_or_create_by_...`     becomes `find_or_create_by(...)`.

* Note that `where(...)` returns a relation, not an array like the old finders. If you require an `Array`, use `where(...).to_a`.

* These equivalent methods may not execute the same SQL as the previous implementation.

* To re-enable the old finders, you can use the [activerecord-deprecated_finders gem](https://github.com/rails/activerecord-deprecated_finders).

### Active Resource

Rails 4.0 extracted Active Resource to its own gem. If you still need the feature you can add the [Active Resource gem](https://github.com/rails/activeresource) in your Gemfile.

### Active Model

* Rails 4.0 has changed how errors attach with the `ActiveModel::Validations::ConfirmationValidator`. Now when confirmation validations fail, the error will be attached to `:#{attribute}_confirmation` instead of `attribute`.

* Rails 4.0 has changed `ActiveModel::Serializers::JSON.include_root_in_json` default value to `false`. Now, Active Model Serializers and Active Record objects have the same default behaviour. This means that you can comment or remove the following option in the `config/initializers/wrap_parameters.rb` file:

```ruby
# Disable root element in JSON by default.
# ActiveSupport.on_load(:active_record) do
#   self.include_root_in_json = false
# end
```

### Action Pack

* Rails 4.0 introduces `ActiveSupport::KeyGenerator` and uses this as a base from which to generate and verify signed cookies (among other things). Existing signed cookies generated with Rails 3.x will be transparently upgraded if you leave your existing `secret_token` in place and add the new `secret_key_base`.

```ruby
  # config/initializers/secret_token.rb
  Myapp::Application.config.secret_token = 'existing secret token'
  Myapp::Application.config.secret_key_base = 'new secret key base'
```

Please note that you should wait to set `secret_key_base` until you have 100% of your userbase on Rails 4.x and are reasonably sure you will not need to rollback to Rails 3.x. This is because cookies signed based on the new `secret_key_base` in Rails 4.x are not backwards compatible with Rails 3.x. You are free to leave your existing `secret_token` in place, not set the new `secret_key_base`, and ignore the deprecation warnings until you are reasonably sure that your upgrade is otherwise complete.

If you are relying on the ability for external applications or Javascript to be able to read your Rails app's signed session cookies (or signed cookies in general) you should not set `secret_key_base` until you have decoupled these concerns.

* Rails 4.0 encrypts the contents of cookie-based sessions if `secret_key_base` has been set. Rails 3.x signed, but did not encrypt, the contents of cookie-based session. Signed cookies are "secure" in that they are verified to have been generated by your app and are tamper-proof. However, the contents can be viewed by end users, and encrypting the contents eliminates this caveat/concern without a significant performance penalty.

Please read [Pull Request #9978](https://github.com/rails/rails/pull/9978) for details on the move to encrypted session cookies.

* Rails 4.0 removed the `ActionController::Base.asset_path` option. Use the assets pipeline feature.

* Rails 4.0 has deprecated `ActionController::Base.page_cache_extension` option. Use `ActionController::Base.default_static_extension` instead.

* Rails 4.0 has removed Action and Page caching from Action Pack. You will need to add the `actionpack-action_caching` gem in order to use `caches_action` and the `actionpack-page_caching` to use `caches_pages` in your controllers.

* Rails 4.0 has removed the XML parameters parser. You will need to add the `actionpack-xml_parser` gem if you require this feature.

* Rails 4.0 changes the default memcached client from `memcache-client` to `dalli`. To upgrade, simply add `gem 'dalli'` to your `Gemfile`.

* Rails 4.0 deprecates the `dom_id` and `dom_class` methods in controllers (they are fine in views). You will need to include the `ActionView::RecordIdentifier` module in controllers requiring this feature.

* Rails 4.0 deprecates the `:confirm` option for the `link_to` helper. You should
instead rely on a data attribute (e.g. `data: { confirm: 'Are you sure?' }`).
This deprecation also concerns the helpers based on this one (such as `link_to_if`
or `link_to_unless`).

* Rails 4.0 changed how `assert_generates`, `assert_recognizes`, and `assert_routing` work. Now all these assertions raise `Assertion` instead of `ActionController::RoutingError`.

* Rails 4.0 raises an `ArgumentError` if clashing named routes are defined. This can be triggered by explicitly defined named routes or by the `resources` method. Here are two examples that clash with routes named `example_path`:

```ruby
  get 'one' => 'test#example', as: :example
  get 'two' => 'test#example', as: :example
```

```ruby
  resources :examples
  get 'clashing/:id' => 'test#example', as: :example
```

In the first case, you can simply avoid using the same name for multiple
routes. In the second, you can use the `only` or `except` options provided by
the `resources` method to restrict the routes created as detailed in the
[Routing Guide](routing.html#restricting-the-routes-created).

* Rails 4.0 also changed the way unicode character routes are drawn. Now you can draw unicode character routes directly. If you already draw such routes, you must change them, for example:

```ruby
get Rack::Utils.escape('こんにちは'), controller: 'welcome', action: 'index'
```

becomes

```ruby
get 'こんにちは', controller: 'welcome', action: 'index'
```

* Rails 4.0 requires that routes using `match` must specify the request method. For example:

```ruby
  # Rails 3.x
  match "/" => "root#index"

  # becomes
  match "/" => "root#index", via: :get

  # or
  get "/" => "root#index"
```

* Rails 4.0 has removed `ActionDispatch::BestStandardsSupport` middleware, `<!DOCTYPE html>` already triggers standards mode per http://msdn.microsoft.com/en-us/library/jj676915(v=vs.85).aspx and ChromeFrame header has been moved to `config.action_dispatch.default_headers`.

Remember you must also remove any references to the middleware from your application code, for example:

```ruby
# Raise exception
config.middleware.insert_before(Rack::Lock, ActionDispatch::BestStandardsSupport)
```

Also check your environment settings for `config.action_dispatch.best_standards_support` and remove it if present.

* In Rails 4.0, precompiling assets no longer automatically copies non-JS/CSS assets from `vendor/assets` and `lib/assets`. Rails application and engine developers should put these assets in `app/assets` or configure `config.assets.precompile`.

* In Rails 4.0, `ActionController::UnknownFormat` is raised when the action doesn't handle the request format. By default, the exception is handled by responding with 406 Not Acceptable, but you can override that now. In Rails 3, 406 Not Acceptable was always returned. No overrides.

* In Rails 4.0, a generic `ActionDispatch::ParamsParser::ParseError` exception is raised when `ParamsParser` fails to parse request params. You will want to rescue this exception instead of the low-level `MultiJson::DecodeError`, for example.

* In Rails 4.0, `SCRIPT_NAME` is properly nested when engines are mounted on an app that's served from a URL prefix. You no longer have to set `default_url_options[:script_name]` to work around overwritten URL prefixes.

* Rails 4.0 deprecated `ActionController::Integration` in favor of `ActionDispatch::Integration`.
* Rails 4.0 deprecated `ActionController::IntegrationTest` in favor of `ActionDispatch::IntegrationTest`.
* Rails 4.0 deprecated `ActionController::PerformanceTest` in favor of `ActionDispatch::PerformanceTest`.
* Rails 4.0 deprecated `ActionController::AbstractRequest` in favor of `ActionDispatch::Request`.
* Rails 4.0 deprecated `ActionController::Request` in favor of `ActionDispatch::Request`.
* Rails 4.0 deprecated `ActionController::AbstractResponse` in favor of `ActionDispatch::Response`.
* Rails 4.0 deprecated `ActionController::Response` in favor of `ActionDispatch::Response`.
* Rails 4.0 deprecated `ActionController::Routing` in favor of `ActionDispatch::Routing`.

### Active Support

Rails 4.0 removes the `j` alias for `ERB::Util#json_escape` since `j` is already used for `ActionView::Helpers::JavaScriptHelper#escape_javascript`.

### Helpers Loading Order

The order in which helpers from more than one directory are loaded has changed in Rails 4.0. Previously, they were gathered and then sorted alphabetically. After upgrading to Rails 4.0, helpers will preserve the order of loaded directories and will be sorted alphabetically only within each directory. Unless you explicitly use the `helpers_path` parameter, this change will only impact the way of loading helpers from engines. If you rely on the ordering, you should check if correct methods are available after upgrade. If you would like to change the order in which engines are loaded, you can use `config.railties_order=` method.

### Active Record Observer and Action Controller Sweeper

Active Record Observer and Action Controller Sweeper have been extracted to the `rails-observers` gem. You will need to add the `rails-observers` gem if you require these features.

### sprockets-rails

* `assets:precompile:primary` has been removed. Use `assets:precompile` instead.
* The `config.assets.compress` option should be changed to
`config.assets.js_compressor` like so for instance:

```ruby
config.assets.js_compressor = :uglifier
```

### sass-rails

* `asset-url` with two arguments is deprecated. For example: `asset-url("rails.png", image)` becomes `asset-url("rails.png")`

Upgrading from Rails 3.1 to Rails 3.2
-------------------------------------

If your application is currently on any version of Rails older than 3.1.x, you should upgrade to Rails 3.1 before attempting an update to Rails 3.2.

The following changes are meant for upgrading your application to Rails 3.2.12, the latest 3.2.x version of Rails.

### Gemfile

Make the following changes to your `Gemfile`.

```ruby
gem 'rails', '= 3.2.12'

group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier',     '>= 1.0.3'
end
```

### config/environments/development.rb

There are a couple of new configuration settings that you should add to your development environment:

```ruby
# Raise exception on mass assignment protection for Active Record models
config.active_record.mass_assignment_sanitizer = :strict

# Log the query plan for queries taking more than this (works
# with SQLite, MySQL, and PostgreSQL)
config.active_record.auto_explain_threshold_in_seconds = 0.5
```

### config/environments/test.rb

The `mass_assignment_sanitizer` configuration setting should also be be added to `config/environments/test.rb`:

```ruby
# Raise exception on mass assignment protection for Active Record models
config.active_record.mass_assignment_sanitizer = :strict
```

### vendor/plugins

Rails 3.2 deprecates `vendor/plugins` and Rails 4.0 will remove them completely. While it's not strictly necessary as part of a Rails 3.2 upgrade, you can start replacing any plugins by extracting them to gems and adding them to your Gemfile. If you choose not to make them gems, you can move them into, say, `lib/my_plugin/*` and add an appropriate initializer in `config/initializers/my_plugin.rb`.

Upgrading from Rails 3.0 to Rails 3.1
-------------------------------------

If your application is currently on any version of Rails older than 3.0.x, you should upgrade to Rails 3.0 before attempting an update to Rails 3.1.

The following changes are meant for upgrading your application to Rails 3.1.11, the latest 3.1.x version of Rails.

### Gemfile

Make the following changes to your `Gemfile`.

```ruby
gem 'rails', '= 3.1.11'
gem 'mysql2'

# Needed for the new asset pipeline
group :assets do
  gem 'sass-rails',   "~> 3.1.5"
  gem 'coffee-rails', "~> 3.1.1"
  gem 'uglifier',     ">= 1.0.3"
end

# jQuery is the default JavaScript library in Rails 3.1
gem 'jquery-rails'
```

### config/application.rb

The asset pipeline requires the following additions:

```ruby
config.assets.enabled = true
config.assets.version = '1.0'
```

If your application is using an "/assets" route for a resource you may want change the prefix used for assets to avoid conflicts:

```ruby
# Defaults to '/assets'
config.assets.prefix = '/asset-files'
```

### config/environments/development.rb

Remove the RJS setting `config.action_view.debug_rjs = true`.

Add these settings if you enable the asset pipeline:

```ruby
# Do not compress assets
config.assets.compress = false

# Expands the lines which load the assets
config.assets.debug = true
```

### config/environments/production.rb

Again, most of the changes below are for the asset pipeline. You can read more about these in the [Asset Pipeline](asset_pipeline.html) guide.

```ruby
# Compress JavaScripts and CSS
config.assets.compress = true

# Don't fallback to assets pipeline if a precompiled asset is missed
config.assets.compile = false

# Generate digests for assets URLs
config.assets.digest = true

# Defaults to Rails.root.join("public/assets")
# config.assets.manifest = YOUR_PATH

# Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
# config.assets.precompile += %w( search.js )

# Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
# config.force_ssl = true
```

### config/environments/test.rb

You can help test performance with these additions to your test environment:

```ruby
# Configure static asset server for tests with Cache-Control for performance
config.serve_static_assets = true
config.static_cache_control = "public, max-age=3600"
```

### config/initializers/wrap_parameters.rb

Add this file with the following contents, if you wish to wrap parameters into a nested hash. This is on by default in new applications.

```ruby
# Be sure to restart your server when you modify this file.
# This file contains settings for ActionController::ParamsWrapper which
# is enabled by default.

# Enable parameter wrapping for JSON. You can disable this by setting :format to an empty array.
ActiveSupport.on_load(:action_controller) do
  wrap_parameters format: [:json]
end

# Disable root element in JSON by default.
ActiveSupport.on_load(:active_record) do
  self.include_root_in_json = false
end
```

### config/initializers/session_store.rb

You need to change your session key to something new, or remove all sessions:

```ruby
# in config/initializers/session_store.rb
AppName::Application.config.session_store :cookie_store, key: 'SOMETHINGNEW'
```

or

```bash
$ rake db:sessions:clear
```

### Remove :cache and :concat options in asset helpers references in views

* With the Asset Pipeline the :cache and :concat options aren't used anymore, delete these options from your views.
