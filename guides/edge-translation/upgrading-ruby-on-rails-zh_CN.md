# Ruby on Rails 升级指南

__特别要强调的翻译名词__

> application 应用程序
> deprecated 弃用的、不宜使用的、过时的：即将在下一版移除的功能。
> middleware 中间件
> route 路由
> raise 抛出
> exception 异常
> associations 关联

本篇讲解升级至新版 Rails 所需的步骤。同时也提供各版本的升级指导。

# 1. 一般建议

升级前先想好为何要升级：需要新功能？旧代码越来越难维护？有多少时间？有能力解决升级的兼容问题吗？等等。

## 1.1 测试覆盖度

最好的方式来确保应用程序升级后仍然正常工作，便是有全面的测试覆盖度。若没有撰写测试，将会花上许多时间，来处理升级带来的新变化。在升级前，先确保测试覆盖得够广吧！

## 1.2 Ruby 版本

Rails 通常与最新的 Ruby 一起前进：

* Rails 3 以上需要高于 1.8.7 版本的 Ruby。
* Rails 3.2.x 是最后支持 Ruby 1.8.7 的版本。
* Rails 4 推荐使用 Ruby 2.0。

小贴士：Ruby 1.8.7 p248 与 p249 有 marshaling bugs，会让 Rails 无预警的 crash。REE 从 1.8.7-2010.02 之后的版本已经修正了这个问题。关于 Ruby 1.9，不要使用 1.9.1，有 segfaults 的问题，1.9 就用 1.9.3 吧。

定案：

* __强烈推荐使用 Ruby 2.0.0-p353__
* Ruby 1.9.3-p484

> [Ruby 1.8.7 退出历史舞台](https://www.ruby-lang.org/zh_cn/news/2013/06/30/we-retire-1-8-7/)

# 2. 从 Rails 4.0 升级到 Rails 4.1

# 3. 从 Rails 3.2 升级到 Rails 4.0

若你是 3.2 以前的版本，先升到 3.2 再试著升到 Rails 4.0。

以下是针对从 Rails 3.2 升级至 Rails 4.0 的说明。

## 3.1 HTTP PATCH

> 这里的路由作动词解。

Rails 4 更新操作的主要 HTTP 动词换成了 `PATCH`。当你在 `config/routes.rb` 以 _RESTful_ 形式宣告某个 resource 时，`PUT` 仍会路由到 `update` action，只是多了个 `PATCH`，同样路由到 `update` action。

```ruby
resources :users
```

```erb
<%= form_for @user do |f| %>
```

```ruby
class UsersController < ApplicationController
  def update
    # 代码不用改；偏好使用 PATCH，PUT 仍然可用。
  end
end
```

但是，当使用 `form_for` 来更新自定路由（使用 `PUT` HTTP 动词）的 resource 时，

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
    # 要修改代码；form_for 会试著使用不存在的 PATCH 路由。
  end
end
```

若不是公有的 API，并且你有决定权换 HTTP 动词，那就把它从 `PUT` 改成 `PATCH` 吧。

在 Rails 4 对 `/users/:id` 做 `PUT` 请求，会被导向 `update`。所以要是 API 接受 `PUT` 请求，那没问题。Router 同时也会将来自 `/users/:id` 的 `PATCH` 请求导向 `update` action。

```ruby
resources :users do
  patch :update_name, on: :member
end
```

若此 action 正被公有的 API 使用，且你无权更改 HTTP 动词时，可更新 form，使用 `PUT` 动词：

```erb
<%= form_for [ :update_name, @user ], method: :put do |f| %>
```

至于为什么要改成 `PATCH`，参考[这篇文章](http://weblog.rubyonrails.org/2012/2/26/edge-rails-patch-is-the-new-primary-http-method-for-updates/)。

### 3.1.1 关于 media types 的说明

<!-- The errata for the `PATCH` verb [specifies that a 'diff' media type should be
used with `PATCH`](http://www.rfc-editor.org/errata_search.php?rfc=5789). One
such format is [JSON Patch](http://tools.ietf.org/html/rfc6902). While Rails
does not support JSON Patch natively, it's easy enough to add support:
 -->

[RFC 5789 的勘误](http://www.rfc-editor.org/errata_search.php?rfc=5789)表示某些 media type 要用 `PATCH` 动词才正确，比如 JSON Patch。

Rails 没有原生支持 JSON Patch，但添加 JSON Patch 的支持非常简单：

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

由于 JSON Patch 最近才有 RFC，仍未有好的 Ruby 函式库出现。Aaron Patterson 的 [hana](https://github.com/tenderlove/hana) 是一个实作 JSON Patch 的 gem，但仍未完整支援 Spec 里所有最近更新的内容。

## 3.2 Gemfile

Rails 4.0 移除了 Gemfile 里的 `assets` group。升级至 4.0 时要移除这个 group，同时需要更新 `config/application.rb`：

```ruby
# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)
```

## 3.3 vendor/plugins

Rails 4.0 不再支援从 `vendor/plugins` 载入 plugins。__必须__将任何 plugins 包成 Gems ，再加入至 Gemfile。若你不想包成 Gem，则可将 plugin 移到 `lib/my_plugin/*`，并使用适当的 initializer：`config/initializer/my_plugin.rb`。

## 3.4 Active Record

* Rails 4.0 移除了 Active Record 的 identity map，因为这会导致[某些关联的不一致性](https://github.com/rails/rails/commit/302c912bf6bcd0fa200d964ec2dc4a44abe328a6)。也就是说 `config.active_record.identity_map` ，这个设置不再有作用。

* Collection association 里的 `delete` 方法现在可接受 `Fixnum` 或 `String` 参数作为 record id，跟 `destroy` 类似。先前会抛出 `ActiveRecord::AssociationTypeMismatch`。从 Rails 4.0 起，`delete` 会自动在删除前，找到匹配的 `id`。

* Rails 4.0 当 column 或 table 重命名时，相关的 index 也会重新命名。也就是不用写 rename index 的 migration 了。

* Rails 4.0 将 `serialized_attributes` 及 `attr_readonly` 改为类别方法。即先前 `self.serialized_attributes` 改为 `self.class.serialized_attributes`。

* Rails 4.0 引入 Strong Parameters 机制，故移除了 `attr_accessible` 与 `attr_protected` （抽离成 [Protected Attributes gem](https://github.com/rails/protected_attributes)）。

* 若你没有使用 Protected Attributes，可以把任何与 `whitelist_attributes` 或 `mass_assignment_sanitizer` 有关的选项移除。

* Rails 4.0 要求 scope 必须是可调用的对象（Proc 或 lambda）：

```ruby
scope :active, where(active: true)

# 变成
scope :active, -> { where active: true }
```

* Rails 4.0 弃用了 `ActiveRecord::Fixtures`，请使用 `ActiveRecord::FixtureSet`。

* Rails 4.0 弃用了 `ActiveRecord::TestCase`，请使用 `ActiveSupport::TestCase`。

* Rails 4.0 弃用了旧式，以 hash 为基础的 Finder API。这表示新的 Finder API 不再接受 “finder options”。

* 弃用了除了 `find_by_...`、`find_by_...!` 这两个以外的动态 Finder 方法，以下是如何修正：

  | Rails 3 | Rails 4 |
  |-----|-----|
  | `find_all_by_...` | 改成 `where(...)` |
  | `find_last_by_...`          | 改成 `where(...).last` |
  | `scoped_by_...`             | 改成 `where(...)` |
  | `find_or_initialize_by_...` | 改成 `find_or_initialize_by(...)` |
  | `find_or_create_by_...`     | 改成 `find_or_create_by(...)` |

* 注意！ `where(...)` 返回 relation，而不像旧式 Finder 方法会返回阵列，需要返回阵列请用 `to_a`。

* 注意！这些对应的方法，不会与先前的 Finder 方法，生成出相同的 SQL 语句。

* 要重新启用旧式的 Finder 方法，可以使用 [activerecord-deprecated_finders gem](https://github.com/rails/activerecord-deprecated_finders)。

## 3.5 Active Resource

Rails 4.0 将 Active Resource 抽成独立的 Gem。若你仍需要此功能，将 [Active Resource gem](https://github.com/rails/activeresource) 加到 Gemfile。

## 3.6 Active Model

* Rails 4.0 更改了 `ActiveModel::Validations::ConfirmationValidator` 错误附加的方式。以前 confirmation 验证错误发生时，错误会加到 `attribute` 上，现在则会附加到 `:#{attribute}_confirmation`。

* Rails 4.0 将 `ActiveModel::Serializers::JSON.include_root_in_json` 的缺省值改为 `false`，现在 Active Model Serializers 与 Active Record 对象缺省有著相同的行为。这表示你可以移除或注解掉这一行：

`config/initializers/wrap_parameters.rb`:

```ruby
# Disable root element in JSON by default.
# ActiveSupport.on_load(:active_record) do
#   self.include_root_in_json = false
# end
```

## 3.7 Action Pack

* Rails 4.0 引入了 `ActiveSupport::KeyGenerator`，用来生成及检查已签署的 cookie。请在 `config/initializers/secret_token.rb` 加入新的 `secret_key_base`：

```ruby
# config/initializers/secret_token.rb
Myapp::Application.config.secret_token = 'existing secret token'
Myapp::Application.config.secret_key_base = 'new secret key base'
```

请注意！要等到使用者都使用你的 Rails 4.x app，并确保你不会降级到 Rails 3.x，才设置 `secret_key_base`。因为 cookie 签署的算法并不向下相容。忽略 deprecation warning 使用 `secret_token` 也是没问题的，只要你知道你自己在做什么就好。

如果有外部应用程序或是 JavaScript，需要能够读 Rails app 签署的 session cookies，在你还没有解决这些问题之前，不要设置 `secret_key_base`。

* 有设置 `secret_key_base` 的话，Rails 4.0 会加密以 cookie-based session 的内容。Rails 3.x 有签署，但未加密。签署的 cookie 是安全的，因为他们是经由你的 app 生成与签署。然而 cookie 的内容仍可被使用者看到，因此加密内容排除了此风险，且没有降低多少的效能。

请阅读 [Pull Request #9978](https://github.com/rails/rails/pull/9978) 来了解更多有关 session cookie 加密的细节。

* Rails 4.0 移除了 `ActionController::Base.asset_path` 选项。请使用 Assets Pipeline。

* Rails 4.0 弃用了 `ActionController::Base.page_cache_extension` 选项。请使用 `ActionController::Base.default_static_extension` 来取代。

* Rails 4.0 从 Action Pack 移除了 Action 与 Page 的 Cache。若要使用 `caches_action`、`caches_pages` 请加入 [actionpack-action_caching](https://github.com/rails/actionpack-action_caching) gem。

* Rails 4.0 移除了 XML 参数解析器。若要使用请加入 [actionpack-xml_parser](https://github.com/rails/actionpack-xml_parser)。

* Rails 4.0 更改了缺省的 memcached 用户端，从 [memcache-client](https://github.com/mperham/memcache-client) 换成了 [dalli](https://github.com/mperham/dalli)，升级只需加入 `gem 'dalli'` 至 `Gemfile`。

* Rails 4.0 弃用了 Controller 的 `dom_id` 与 `dom_class` 方法（View 依然能用）。要用的话请在 Controller `include` `ActionView::RecordIdentifier`。

* Rails 4.0 弃用了 `link_to` 的 `:confirm` 选项，应改写为 `data: { confirm: 'Are you sure?' }`，`link_to_if`、`link_to_unless` 同样受影响。

* Rails 4.0 修改了 `assert_generates`、`assert_recognizes` 以及 `assert_routing 的工作方式。这些 assertions 会抛出 `Assertion` 而不是 `ActionController::RoutingError` 错误。

* 在 Rails 4.0，如果定义了重复名称的路由时，会抛出 `ArgumentError`。请见下面两例（重复的 `example_path`）：

```ruby
  get 'one' => 'test#example', as: :example
  get 'two' => 'test#example', as: :example
```

```ruby
  resources :examples
  get 'clashing/:id' => 'test#example', as: :example
```

第一个例子可直接换名字来解决。第二个例子可使用 `resources` 方法提供的 `only` 与 `except` 选项来限制生成出的路由，详见 [Routing Guide](/guides/edge-translation/routing-zh_TW.md#restricting-the-routes-created)

* Rails 4.0 更改了 route 有 unicode 字符的生成方式。现在 route 里可直接使用 unicode 字符，先前需要 `escape` 的作法不再需要了：

```ruby
get Rack::Utils.escape('こんにちは'), controller: 'welcome', action: 'index'
```

改为

```ruby
get 'こんにちは', controller: 'welcome', action: 'index'
```

* Rails 4.0 要求使用 `match` 的 route 必须指定 HTTP 动词:

```ruby
  # Rails 3.x
  match '/' => 'root#index'

  # 改成
  match '/' => 'root#index', via: :get

  # 或
  get '/' => 'root#index'
```

* Rails 4.0 移除了 `ActionDispatch::BestStandardsSupport` 中间件。因为 `<!DOCTYPE html>` 如[此文](http://msdn.microsoft.com/en-us/library/jj676915(v=vs.85).aspx)所述，已触发了标准模式。而 ChromeFrame header 被移到 `config.action_dispatch.default_headers` 了。

记得移除所有使用到 `ActionDispatch::BestStandardsSupport` middleware 的参照：

```ruby
# 会抛出异常
config.middleware.insert_before(Rack::Lock, ActionDispatch::BestStandardsSupport)
```

并移除环境设置中的 `config.action_dispatch.best_standards_support`。

* Rails 4.0 预编译不再自动从 `vendor/assets` 与 `lib/assets` 拷贝非 JS 或 CSS 的  assets。Rails 应用程序与 Engine 的开发者应将这些 assets 移到 `app/assets` 或设置 `config.assets.precompile`。

* Rails 4.0 当 action 不知道如何处理 request 格式时会抛出 `ActionController::UnknownFormat` 异常。缺省是 406 Not Acceptable，但你可以改成别的 status code，在 Rails 3 只能是 406。

* Rails 4.0 当 `ParamsParser` 无法解析 request params 时，会抛出通用的 `ActionDispatch::ParamsParser::ParseError` 异常。你可以 `rescue` 这个异常，而不是较为底层的 `MultiJson::DecodeError`。

* Rails 4.0，当 Engine 安装到有 URL 前缀的宿主（hosting application）时，`SCRIPT_NAME` 已经将 URL 前缀适当地设置好了。不再需要设置 `default_url_options[:script_name]` 来覆写 URL 前缀。

* Rails 4.0 弃用了 `ActionController::Integration` 请使用 `ActionDispatch::Integration`。
* Rails 4.0 弃用了 `ActionController::IntegrationTest` 请使用 `ActionDispatch::IntegrationTest`。
* Rails 4.0 弃用了 `ActionController::PerformanceTest` 请使用 `ActionDispatch::PerformanceTest`。
* Rails 4.0 弃用了 `ActionController::AbstractRequest` 请使用 `ActionDispatch::Request`。
* Rails 4.0 弃用了 `ActionController::Request` 请使用 `ActionDispatch::Request`。
* Rails 4.0 弃用了 `ActionController::AbstractResponse` 请使用 `ActionDispatch::Response`。
* Rails 4.0 弃用了 `ActionController::Response` 请使用 `ActionDispatch::Response`。
* Rails 4.0 弃用了 `ActionController::Routing` 请使用 `ActionDispatch::Routing`。

## 3.8 Active Support

Rails 4.0 移除了 `ERB::Util#json_escape` 的 `j` 别名。因为 `j` 已经被 `ActionView::Helpers::JavaScriptHelper#escape_javascript` 所使用。

## 3.9 Helpers 加载顺序

Rails 4.0 更改了 Helpers 的加载顺序。之前是将各目录的 Helpers 集合起来，并按字母排序加载。Rails 4.0 之后，Helpers 会按照目录原本加载的顺序，并在各自的目录里按字母依序加载。除非你特别使用了 `helpers_path` 参数，否则这个改动只会影响到从 Engine 加载 Helpers 的顺序。如果你正依赖加载的顺序，可以检查升级后这些 Helper 是否正常工作。如果想更改 Engine 加载的顺序，可以使用 `config.railties_order=` 方法。

## 3.10 Active Record Observer 与 Action Controller Sweeper

Active Record Observer 与 Action Controller Sweeper 被抽成独立的 Gem：[rails-observers](https://github.com/rails/rails-observers)。

## 3.11 sprockets-rails

* `assets:precompile:primary` 被移除了。请改用 `assets:precompile`。
* `config.assets.compress` 选项应改成 `config.assets.js_compressor`：

```ruby
config.assets.js_compressor = :uglifier
```

## 3.12 sass-rails

* `asset-url("rails.png", image)` 改成 `asset-url("rails.png")`
