# Ruby on Rails 升級指南

__特別要強調的翻譯名詞__

> application 應用程式
> deprecated 棄用的、不宜使用的、過時的：即將在下一版移除的功能。
> middleware 中間件
> route 路由
> raise 拋出
> exception 異常
> association 關聯

本篇講解升級至新版 Rails 所需的步驟。同時也提供各版本的升級指導。

# 1. 一般建議

升級前先想好為何要升級：需要新功能？舊代碼越來越難維護？有多少時間？有能力解決升級的兼容問題嗎？等等。

## 1.1 測試覆蓋度

最好的方式來確保應用程式升級後仍然正常工作，便是有全面的測試覆蓋度。若沒有撰寫測試，將會花上許多時間，來處理升級帶來的新變化。在升級前，先確保測試覆蓋得夠廣吧！

## 1.2 Ruby 版本

Rails 通常與最新的 Ruby 一起前進：

* Rails 3 以上需要高於 1.8.7 版本的 Ruby。
* Rails 3.2.x 是最後支持 Ruby 1.8.7 的版本。
* Rails 4 推薦使用 Ruby 2.0。

講個秘訣：Ruby 1.8.7 p248 與 p249 有 marshaling bugs，會讓 Rails 無預警的 crash。REE 從 1.8.7-2010.02 之後的版本已經修正了這個問題。關於 Ruby 1.9，不要使用 1.9.1，有 segfaults 的問題，1.9 就用 1.9.3 吧。

定案：

* __強烈推薦使用 Ruby 2.0.0-p353__
* Ruby 1.9.3-p484

> [Ruby 1.8.7（官方已經不維護了）](https://www.ruby-lang.org/zh_tw/news/2013/06/30/we-retire-1-8-7/)

# 2. 從 Rails 4.0 升級到 Rails 4.1

**本小節正在施工中**

### CSRF protection from remote `<script>` tags

Or, "whaaat my tests are failing!!!?"

Cross-site request forgery (CSRF) protection now covers GET requests with
JavaScript responses, too. That prevents a third-party site from referencing
your JavaScript URL and attempting to run it to extract sensitive data.

This means that your functional and integration tests that use

```ruby
get :index, format: :js
```

will now trigger CSRF protection. Switch to

```ruby
xhr :get, :index, format: :js
```

to explicitly test an XmlHttpRequest.

If you really mean to load JavaScript from remote `<script>` tags, skip CSRF
protection on that action.

### Spring

If you want to use Spring as your application preloader you need to:

1. Add `gem 'spring', group: :development` to your `Gemfile`.
2. Install spring using `bundle install`.
3. Springify your binstubs with `bundle exec spring binstub --all`.

NOTE: User defined rake tasks will run in the `development` environment by
default. If you want them to run in other environments consult the
[Spring README](https://github.com/rails/spring#rake).

### `config/secrets.yml`

If you want to use the new `secrets.yml` convention to store your application's
secrets, you need to:

1. Create a `secrets.yml` file in your `config` folder with the following content:

    ```yaml
    development:
      secret_key_base:

    test:
      secret_key_base:

    production:
      secret_key_base:
    ```

2. Copy the existing `secret_key_base` from the `secret_token.rb` initializer to
   `secrets.yml` under the `production` section.

3. Remove the `secret_token.rb` initializer.

4. Use `rake secret` to generate new keys for the `development` and `test` sections.

5. Restart your server.

## 2.1 Changes to test helper

If your test helper contains a call to ActiveRecord::Migration.check_pending! this can be removed. The check is now done automatically when you require 'test_help', although leaving this line in your helper is not harmful in any way.

## 2.2 處理 JSON 的變化

Rails 4.1 有些關於 JSON 處理的重要變化。

### 2.2.1 移除 MultiJSON

MultiJSON has reached its [end-of-life](https://github.com/rails/rails/pull/10576)
and has been removed from Rails.

If your application currently depend on MultiJSON directly, you have a few options:

1. Add 'multi_json' to your Gemfile. Note that this might cease to work in the future

2. Migrate away from MultiJSON by using `obj.to_json`, and `JSON.parse(str)` instead.

WARNING: Do not simply replace `MultiJson.dump` and `MultiJson.load` with
`JSON.dump` and `JSON.load`. These JSON gem APIs are meant for serializing and
deserializing arbitrary Ruby objects and are generally [unsafe](http://www.ruby-doc.org/stdlib-2.0.0/libdoc/json/rdoc/JSON.html#method-i-load).

### 2.2.2 JSON gem compatibility

Historically, Rails had some compatibility issues with the JSON gem. Using
`JSON.generate` and `JSON.dump` inside a Rails application could produce
unexpected errors.

Rails 4.1 fixed these issues by isolating its own encoder from the JSON gem. The
JSON gem APIs will function as normal, but they will not have access to any
Rails-specific features. For example:

```ruby
class FooBar
  def as_json(options = nil)
    { foo: 'bar' }
  end
end

>> FooBar.new.to_json # => "{\"foo\":\"bar\"}"
>> JSON.generate(FooBar.new, quirks_mode: true) # => "\"#<FooBar:0x007fa80a481610>\""
```

### 2.2.3 New JSON encoder

The JSON encoder in Rails 4.1 has been rewritten to take advantage of the JSON
gem. For most applications, this should be a transparent change. However, as
part of the rewrite, the following features have been removed from the encoder:

1. Circular data structure detection
2. Support for the `encode_json` hook
3. Option to encode `BigDecimal` objects as numbers instead of strings

If you application depends on one of these features, you can get them back by
adding the [`activesupport-json_encoder`](https://github.com/rails/activesupport-json_encoder)
gem to your Gemfile.

## 2.3 Usage of `return` within inline callback blocks

Previously, Rails allowed inline callback blocks to use `return` this way:

```ruby
class ReadOnlyModel < ActiveRecord::Base
  before_save { return false } # BAD
end
```

This behaviour was never intentionally supported. Due to a change in the internals
of `ActiveSupport::Callbacks`, this is no longer allowed in Rails 4.1. Using a
`return` statement in an inline callback block causes a `LocalJumpError` to
be raised when the callback is executed.

Inline callback blocks using `return` can be refactored to evaluate to the
returned value:

```ruby
class ReadOnlyModel < ActiveRecord::Base
  before_save { false } # GOOD
end
```

Alternatively, if `return` is preferred it is recommended to explicitly define
a method:

```ruby
class ReadOnlyModel < ActiveRecord::Base
  before_save :before_save_callback # GOOD

  private
    def before_save_callback
      return false
    end
end
```

This change applies to most places in Rails where callbacks are used, including
Active Record and Active Model callbacks, as well as filters in Action
Controller (e.g. `before_action`).

See [this pull request](https://github.com/rails/rails/pull/13271) for more
details.


## 2.4 Methods defined in Active Record fixtures

Rails 4.1 evaluates each fixture's ERB in a separate context, so helper methods
defined in a fixture will not be available in other fixtures.

Helper methods that are used in multiple fixtures should be defined on modules
included in the newly introduced `ActiveRecord::FixtureSet.context_class`, in
`test_helper.rb`.

```ruby
class FixtureFileHelpers
  def file_sha(path)
    Digest::SHA2.hexdigest(File.read(Rails.root.join('test/fixtures', path)))
  end
end
ActiveRecord::FixtureSet.context_class.send :include, FixtureFileHelpers
```

# 3. 從 Rails 3.2 升級到 Rails 4.0

若你是 3.2 以前的版本，先升到 3.2 再試著升到 Rails 4.0。

以下是針對從 Rails 3.2 升級至 Rails 4.0 的說明。

## 3.1 HTTP PATCH

> 這裡的路由作動詞解。

Rails 4 更新操作的主要 HTTP 動詞換成了 `PATCH`。當你在 `config/routes.rb` 以 _RESTful_ 形式宣告某個 resource 時，`PUT` 仍會路由到 `update` action，只是多了個 `PATCH`，同樣路由到 `update` action。

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

若不是公有的 API，並且你有決定權換 HTTP 動詞，那就把它從 `PUT` 改成 `PATCH` 吧。

在 Rails 4 對 `/users/:id` 做 `PUT` 請求，會被導向 `update`。所以要是 API 接受 `PUT` 請求，那沒問題。Router 同時也會將來自 `/users/:id` 的 `PATCH` 請求導向 `update` action。

```ruby
resources :users do
  patch :update_name, on: :member
end
```

若此 action 正被公有的 API 使用，且你無權更改 HTTP 動詞時，可更新 form，使用 `PUT` 動詞：

```erb
<%= form_for [ :update_name, @user ], method: :put do |f| %>
```

至於為什麼要改成 `PATCH`，參考[這篇文章](http://weblog.rubyonrails.org/2012/2/26/edge-rails-patch-is-the-new-primary-http-method-for-updates/)。

### 3.1.1 關於 media types 的說明

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

## 3.2 Gemfile

Rails 4.0 移除了 Gemfile 裡的 `assets` group。升級至 4.0 時要移除這個 group，同時需要更新 `config/application.rb`：

```ruby
# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)
```

## 3.3 vendor/plugins

Rails 4.0 不再支援從 `vendor/plugins` 載入 plugins。__必須__將任何 plugins 包成 Gems ，再加入至 Gemfile。若你不想包成 Gem，則可將 plugin 移到 `lib/my_plugin/*`，並使用適當的 initializer：`config/initializer/my_plugin.rb`。

## 3.4 Active Record

* Rails 4.0 移除了 Active Record 的 identity map，因為這會產生[某些關聯的不一致性](https://github.com/rails/rails/commit/302c912bf6bcd0fa200d964ec2dc4a44abe328a6)。也就是說 `config.active_record.identity_map` ，這個設定不再有作用。

* Collection association 裡的 `delete` 方法現在可接受 `Fixnum` 或 `String` 參數作為 record id，跟 `destroy` 類似。先前會拋出 `ActiveRecord::AssociationTypeMismatch`。從 Rails 4.0 起，`delete` 會自動在刪除前，找到匹配的 `id`。

* Rails 4.0 當 column 或 table 重命名時，相關的 index 也會重新命名。也就是不用寫 rename index 的 migration 了。

* Rails 4.0 將 `serialized_attributes` 及 `attr_readonly` 改為類別方法。即先前 `self.serialized_attributes` 改為 `self.class.serialized_attributes`。

* Rails 4.0 引入 Strong Parameters 機制，故移除了 `attr_accessible` 與 `attr_protected` （抽離成 [Protected Attributes gem](https://github.com/rails/protected_attributes)）。

* 若你沒有使用 Protected Attributes，可以把任何與 `whitelist_attributes` 或 `mass_assignment_sanitizer` 有關的選項移除。

* Rails 4.0 要求 scope 必須是可呼叫的物件（Proc 或 lambda）：

```ruby
scope :active, where(active: true)

# 變成
scope :active, -> { where active: true }
```

* Rails 4.0 棄用了 `ActiveRecord::Fixtures`，請使用 `ActiveRecord::FixtureSet`。

* Rails 4.0 棄用了 `ActiveRecord::TestCase`，請使用 `ActiveSupport::TestCase`。

* Rails 4.0 棄用了舊式，以 hash 為基礎的 Finder API。這表示新的 Finder API 不再接受 “finder options”。

* 棄用了除了 `find_by_...`、`find_by_...!` 這兩個以外的動態 Finder 方法，以下是如何修正：

  | Rails 3 | Rails 4 |
  |-----|-----|
  | `find_all_by_...` | 改成 `where(...)` |
  | `find_last_by_...`          | 改成 `where(...).last` |
  | `scoped_by_...`             | 改成 `where(...)` |
  | `find_or_initialize_by_...` | 改成 `find_or_initialize_by(...)` |
  | `find_or_create_by_...`     | 改成 `find_or_create_by(...)` |

* 注意！ `where(...)` 返回 relation，而不像舊式 Finder 方法會返回陣列，需要返回陣列請用 `to_a`。

* 注意！這些對應的方法，不會與先前的 Finder 方法，產生出相同的 SQL 語句。

* 要重新啟用舊式的 Finder 方法，可以使用 [activerecord-deprecated_finders gem](https://github.com/rails/activerecord-deprecated_finders)。

## 3.5 Active Resource

Rails 4.0 將 Active Resource 抽成獨立的 Gem。若你仍需要此功能，將 [Active Resource gem](https://github.com/rails/activeresource) 加到 Gemfile。

## 3.6 Active Model

* Rails 4.0 更改了 `ActiveModel::Validations::ConfirmationValidator` 錯誤附加的方式。以前 confirmation 驗證錯誤發生時，錯誤會加到 `attribute` 上，現在則會附加到 `:#{attribute}_confirmation`。

* Rails 4.0 將 `ActiveModel::Serializers::JSON.include_root_in_json` 的預設值改為 `false`，現在 Active Model Serializers 與 Active Record 物件預設有著相同的行為。這表示你可以移除或註解掉這一行：

`config/initializers/wrap_parameters.rb`:

```ruby
# Disable root element in JSON by default.
# ActiveSupport.on_load(:active_record) do
#   self.include_root_in_json = false
# end
```

## 3.7 Action Pack

* Rails 4.0 引入了 `ActiveSupport::KeyGenerator`，用來產生及檢查已簽署的 cookie。請在 `config/initializers/secret_token.rb` 加入新的 `secret_key_base`：

```ruby
# config/initializers/secret_token.rb
Myapp::Application.config.secret_token = 'existing secret token'
Myapp::Application.config.secret_key_base = 'new secret key base'
```

請注意！要等到使用者都使用你的 Rails 4.x app，並確保你不會降級到 Rails 3.x，才設定 `secret_key_base`。因為 cookie 簽署的算法並不向下相容。忽略 deprecation warning 使用 `secret_token` 也是沒問題的，只要你知道你自己在做什麼就好。

如果有外部應用程式或是 JavaScript，需要能夠讀 Rails app 簽署的 session cookies，在你還沒有解決這些問題之前，不要設定 `secret_key_base`。

* 有設定 `secret_key_base` 的話，Rails 4.0 會加密以 cookie-based session 的內容。Rails 3.x 有簽署，但未加密。簽署的 cookie 是安全的，因為他們是經由你的 app 產生與簽署。然而 cookie 的內容仍可被使用者看到，因此加密內容排除了此風險，且沒有降低多少的效能。

請閱讀 [Pull Request #9978](https://github.com/rails/rails/pull/9978) 來了解更多有關 session cookie 加密的細節。

* Rails 4.0 移除了 `ActionController::Base.asset_path` 選項。請使用 Assets Pipeline。

* Rails 4.0 棄用了 `ActionController::Base.page_cache_extension` 選項。請使用 `ActionController::Base.default_static_extension` 來取代。

* Rails 4.0 從 Action Pack 移除了 Action 與 Page 的 Cache。若要使用 `caches_action`、`caches_pages` 請加入 [actionpack-action_caching](https://github.com/rails/actionpack-action_caching) gem。

* Rails 4.0 移除了 XML 參數解析器。若要使用請加入 [actionpack-xml_parser](https://github.com/rails/actionpack-xml_parser)。

* Rails 4.0 更改了預設 memcached client，從 [memcache-client](https://github.com/mperham/memcache-client) 換成了 [dalli](https://github.com/mperham/dalli)，升級只需加入 `gem 'dalli'` 至 `Gemfile`。

* Rails 4.0 棄用了 Controller 的 `dom_id` 與 `dom_class` 方法（View 依然能用）。要用的話請在 Controller `include` `ActionView::RecordIdentifier`。

* Rails 4.0 棄用了 `link_to` 的 `:confirm` 選項，應改寫為 `data: { confirm: 'Are you sure?' }`，`link_to_if`、`link_to_unless` 同樣受影響。

* Rails 4.0 修改了 `assert_generates`、`assert_recognizes` 以及 `assert_routing 的工作方式。這些 assertions 會拋出 `Assertion` 而不是 `ActionController::RoutingError` 錯誤。

* 在 Rails 4.0，如果定義了重複名稱的路由時，會拋出 `ArgumentError`。請見下面兩例（重複的 `example_path`）：

```ruby
  get 'one' => 'test#example', as: :example
  get 'two' => 'test#example', as: :example
```

```ruby
  resources :examples
  get 'clashing/:id' => 'test#example', as: :example
```

第一個例子可直接換名字來解決。第二個例子可使用 `resources` 方法提供的 `only` 與 `except` 選項來限制產生出的路由，詳見 [Routing Guide](/guides/edge-translation/routing-zh_TW.md#restricting-the-routes-created)

* Rails 4.0 更改了 route 有 unicode 字元的產生方式。現在 route 裡可直接使用 unicode 字元，先前需要 `escape` 的作法不再需要了：

```ruby
get Rack::Utils.escape('こんにちは'), controller: 'welcome', action: 'index'
```

改為

```ruby
get 'こんにちは', controller: 'welcome', action: 'index'
```

* Rails 4.0 要求使用 `match` 的 route 必須指定 HTTP 動詞:

```ruby
  # Rails 3.x
  match '/' => 'root#index'

  # 改成
  match '/' => 'root#index', via: :get

  # 或
  get '/' => 'root#index'
```

* Rails 4.0 移除了 `ActionDispatch::BestStandardsSupport` 中間件。因為 `<!DOCTYPE html>` 如[此文](http://msdn.microsoft.com/en-us/library/jj676915(v=vs.85).aspx)所述，已觸發了標準模式。而 ChromeFrame header 被移到 `config.action_dispatch.default_headers` 了。

記得移除所有使用到 `ActionDispatch::BestStandardsSupport` middleware 的參照：

```ruby
# 會拋出異常
config.middleware.insert_before(Rack::Lock, ActionDispatch::BestStandardsSupport)
```

並移除環境設定中的 `config.action_dispatch.best_standards_support`。

* Rails 4.0 預編譯不再自動從 `vendor/assets` 與 `lib/assets` 拷貝非 JS 或 CSS 的  assets。Rails 應用程式與 Engine 的開發者應將這些 assets 移到 `app/assets` 或設定 `config.assets.precompile`。

* Rails 4.0 當 action 不知道如何處理 request 格式時會拋出 `ActionController::UnknownFormat` 異常。預設是 406 Not Acceptable，但你可以改成別的 status code，在 Rails 3 只能是 406。

* Rails 4.0 當 `ParamsParser` 無法解析 request params 時，會拋出通用的 `ActionDispatch::ParamsParser::ParseError` 異常。你可以 `rescue` 這個異常，而不是較為底層的 `MultiJson::DecodeError`。

* Rails 4.0，當 Engine 安裝到有 URL 前綴的宿主（hosting application）時，`SCRIPT_NAME` 已經將 URL 前綴適當地設定好了。不再需要設定 `default_url_options[:script_name]` 來覆寫 URL 前綴。

* Rails 4.0 棄用了 `ActionController::Integration` 請使用 `ActionDispatch::Integration`。
* Rails 4.0 棄用了 `ActionController::IntegrationTest` 請使用 `ActionDispatch::IntegrationTest`。
* Rails 4.0 棄用了 `ActionController::PerformanceTest` 請使用 `ActionDispatch::PerformanceTest`。
* Rails 4.0 棄用了 `ActionController::AbstractRequest` 請使用 `ActionDispatch::Request`。
* Rails 4.0 棄用了 `ActionController::Request` 請使用 `ActionDispatch::Request`。
* Rails 4.0 棄用了 `ActionController::AbstractResponse` 請使用 `ActionDispatch::Response`。
* Rails 4.0 棄用了 `ActionController::Response` 請使用 `ActionDispatch::Response`。
* Rails 4.0 棄用了 `ActionController::Routing` 請使用 `ActionDispatch::Routing`。

## 3.8 Active Support

Rails 4.0 移除了 `ERB::Util#json_escape` 的 `j` 別名。因為 `j` 已經被 `ActionView::Helpers::JavaScriptHelper#escape_javascript` 所使用。

## 3.9 Helpers 加載順序

Rails 4.0 更改了 Helpers 的加載順序。之前是將各目錄的 Helpers 集合起來，並按字母排序加載。Rails 4.0 之後，Helpers 會按照目錄原本加載的順序，並在各自的目錄裡按字母依序加載。除非你特別使用了 `helpers_path` 參數，否則這個改動只會影響到從 Engine 加載 Helpers 的順序。如果你正依賴加載的順序，可以檢查升級後這些 Helper 是否正常工作。如果想更改 Engine 加載的順序，可以使用 `config.railties_order=` 方法。

## 3.10 Active Record Observer 與 Action Controller Sweeper

Active Record Observer 與 Action Controller Sweeper 被抽成獨立的 Gem：[rails-observers](https://github.com/rails/rails-observers)。

## 3.11 sprockets-rails

* `assets:precompile:primary` 被移除了。請改用 `assets:precompile`。
* `config.assets.compress` 選項應改成 `config.assets.js_compressor`：

```ruby
config.assets.js_compressor = :uglifier
```

## 3.12 sass-rails

* `asset-url("rails.png", image)` 改成 `asset-url("rails.png")`

# 4. 從 Rails 3.1 升級到 Rails 3.2

若你的應用程式為 3.1.x 之前的版本，先升級至 3.1，再試著升級至 3.2。

下面幫助你從 Rails 3.1 升級至 Rails 3.2.15（Rails 3.2.x 的最後版本）。

## 4.1 Gemfile

修改 `Gemfile`。

```ruby
gem 'rails', '3.2.15'

group :assets do
  gem 'sass-rails',   '~> 3.2.6'
  gem 'coffee-rails', '~> 3.2.2'
  gem 'uglifier',     '>= 1.2.3'
end
```

## 4.2 config/environments/development.rb

There are a couple of new configuration settings that you should add to your development environment:

```ruby
# Raise exception on mass assignment protection for Active Record models
config.active_record.mass_assignment_sanitizer = :strict

# Log the query plan for queries taking more than this (works
# with SQLite, MySQL, and PostgreSQL)
config.active_record.auto_explain_threshold_in_seconds = 0.5
```

## 4.3 config/environments/test.rb

The `mass_assignment_sanitizer` configuration setting should also be be added to `config/environments/test.rb`:

```ruby
# Raise exception on mass assignment protection for Active Record models
config.active_record.mass_assignment_sanitizer = :strict
```

## 4.4 vendor/plugins

Rails 3.2 deprecates `vendor/plugins` and Rails 4.0 will remove them completely. While it's not strictly necessary as part of a Rails 3.2 upgrade, you can start replacing any plugins by extracting them to gems and adding them to your Gemfile. If you choose not to make them gems, you can move them into, say, `lib/my_plugin/*` and add an appropriate initializer in `config/initializers/my_plugin.rb`.

## 4.5 Active Record

Option `:dependent => :restrict` has been removed from `belongs_to`. If you want to prevent deleting the object if there are any associated objects, you can set `:dependent => :destroy` and return `false` after checking for existence of association from any of the associated object's destroy callbacks.

# 5. 從 Rails 3.0 升級到 Rails 3.1

If your application is currently on any version of Rails older than 3.0.x, you should upgrade to Rails 3.0 before attempting an update to Rails 3.1.

The following changes are meant for upgrading your application to Rails 3.1.11, the latest 3.1.x version of Rails.

## 5.1 Gemfile

Make the following changes to your `Gemfile`.

```ruby
gem 'rails', '3.1.12'
gem 'mysql2'

# Needed for the new asset pipeline
group :assets do
  gem 'sass-rails',   "~> 3.1.7"
  gem 'coffee-rails', "~> 3.1.1"
  gem 'uglifier',     ">= 1.0.3"
end

# jQuery is the default JavaScript library in Rails 3.1
gem 'jquery-rails'
```

## 5.2 config/application.rb

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

## 5.3 config/environments/development.rb

Remove the RJS setting `config.action_view.debug_rjs = true`.

Add these settings if you enable the asset pipeline:

```ruby
# Do not compress assets
config.assets.compress = false

# Expands the lines which load the assets
config.assets.debug = true
```

## 5.4 config/environments/production.rb

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

## 5.5 config/environments/test.rb

You can help test performance with these additions to your test environment:

```ruby
# Configure static asset server for tests with Cache-Control for performance
config.serve_static_assets = true
config.static_cache_control = 'public, max-age=3600'
```

## 5.6 config/initializers/wrap_parameters.rb

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

## 5.7 config/initializers/session_store.rb

You need to change your session key to something new, or remove all sessions:

```ruby
# in config/initializers/session_store.rb
AppName::Application.config.session_store :cookie_store, key: 'SOMETHINGNEW'
```

or

```bash
$ rake db:sessions:clear
```

## 5.8 Remove :cache and :concat options in asset helpers references in views

* With the Asset Pipeline the :cache and :concat options aren't used anymore, delete these options from your views.
