# Rails I18n 指南

__特別要強調的翻譯名詞__

> application 應用程式

> locale 語系

Rails 內建 Ruby I18n 供你翻譯應用程式，提供多語支援服務。多語轉換的資料格式採用方便的 YAML 格式，非常容易使用。

讀完本篇可能會學到...

  * 如何在 Rails 使用 I18n
  * 多種在 RESTful 應用程式裡正確使用 I18n 的方式
  * 用 I18n 翻譯 Active Record 的錯誤訊息或 Action Mailer Email 主旨。
  * 其他幫助你翻譯的工具

## I18n?

為什麼叫做 I18n？因為 Internationalization， __I__ 跟 __n__ 之間剛好有 18 個字母。

## I18n 可以幹嘛?

日期、時間格式轉換、翻譯 Active Record model 名稱、靜態文字、提示訊息(flash message）…等。

## I18n 的工作原理

所有的靜態文字，都有國際化處理。

## Ruby I18n gem

分為兩部分：

1. Public API

2. default backend（實作這些方法）

## Public `I18n` API

最重要的兩個方法

```ruby
I18n.translate # 翻譯文字
I18n.localize # 轉換時間
```

縮寫為：

```ruby
I18n.t 'store.title'
I18n.l Time.now

t 'store.title'
l Time.now
```

另提供下列 attributes：

```ruby
I18n.load_path         # 查看所有的語系檔案
I18n.locale            # 取得或設定當前的 locale
I18n.default_locale    # 取得或設定 default_locale
I18n.exception_handler # 用別的 exception_handler
I18n.backend           # 用別的後端Use a different backend
```

## config/application.rb

裡面可設定 locale

```ruby
# The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
# config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
# config.i18n.default_locale = :de
```

## config/initializers/locale.rb

locale 設定檔存放處。

```ruby
# in config/initializers/locale.rb

# 告訴 I18n 去哪找翻譯文件
I18n.load_path += Dir[Rails.root.join('lib', 'locale', '*.{rb,yml}')]

# 設定預設語系
I18n.default_locale = :pt
```

## 加載目錄

`config/locales` 目錄下的 `.rb` 或 `.yml` 都會自動被加到 translation load path (`I18n.load_path`)。

## 千萬不要把 locale 存在 session 或 cookie 裡

## 設定/傳遞 locale 參數

### 設定語系

_ApplicationController_

```ruby
before_action :set_locale

def set_locale
  I18n.locale = params[:locale] || I18n.default_locale
end
```

#### 用法：

```
http://example.com/books?locale=pt. (This is, for example, Google's approach.) So http://localhost:3000?locale=pt will load the Portuguese localization, whereas http://localhost:3000?locale=de would load the German localization
```

## 從 Domain name 設定 locale

### Top-level domain 的作法

www.example.com => 載入英文

www.example.es => 載入西班牙文

_ApplicationController_

```ruby
before_action :set_locale

def set_locale
  I18n.locale = extract_locale_from_tld || I18n.default_locale
end

# Get locale from top-level domain or return nil if such locale is not available
# You have to put something like:
#   127.0.0.1 application.com
#   127.0.0.1 application.it
#   127.0.0.1 application.pl
# in your /etc/hosts file to try this out locally
def extract_locale_from_tld
  parsed_locale = request.host.split('.').last
  I18n.available_locales.include?(parsed_locale.to_sym) ? parsed_locale : nil
end
```

### 二級域名的作法：

```ruby
# Get locale code from request subdomain (like http://it.application.local:3000)
# You have to put something like:
#   127.0.0.1 gr.application.local
# in your /etc/hosts file to try this out locally
def extract_locale_from_subdomain
  parsed_locale = request.subdomains.first
  I18n.available_locales.include?(parsed_locale.to_sym) ? parsed_locale : nil
end
```

### 語言切換選單的作法

```ruby
link_to("Deutsch", "#{APP_CONFIG[:deutsch_website_url]}#{request.env['REQUEST_URI']}")
```

### default_url_options

"centralizing dynamic decisions about the URLs" in its `ApplicationController#default_url_options`.

_ApplicationController_:

```ruby
# app/controllers/application_controller.rb
def default_url_options(options={})
  logger.debug "default_url_options is passed options: #{options.inspect}\n"
  { locale: I18n.locale }
end
```

`url_for` 有關的方法，比如 `root_path` 或是 `root_url`，以及 resource 的路由，現在都會自動在查詢字串裡(query string)包含 locale 的資訊了：

    http://localhost:3001/?locale=ja.

### www.example.com/nl/boooks 這種怎麼做?

www.example.com/nl/boooks
www.example.com/en/boooks

```ruby
# config/routes.rb
scope "/:locale" do
  resources :books
end
```

這樣做的好處是：

http://localhost:3001/books

不會引發錯誤。

但，

http://localhost:3001/nl

要特別處理：

```ruby
# config/routes.rb
get '/:locale' => 'dashboard#index'
```

#### 處理這種情況的 gem:

[svenfuchs/routing-filter](https://github.com/svenfuchs/routing-filter/tree/master)

[raul/translate_routes](https://github.com/raul/translate_routes/tree/master)

## 從用戶端提供資訊設定 Locale

這種方法適合網路 app 或是服務，不適合網站。

### 用戶端提供資訊來源

#### Accept-Language

Accept-Language HTTP header （用 curl）。

```ruby
def set_locale
  logger.debug "* Accept-Language: #{request.env['HTTP_ACCEPT_LANGUAGE']}"
  I18n.locale = extract_locale_from_accept_language_header
  logger.debug "* Locale set to '#{I18n.locale}'"
end

private
  def extract_locale_from_accept_language_header
    request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first
  end
```

##### 支援此方法的 Gem

[iain/http_accept_language](https://github.com/iain/http_accept_language/tree/master)

[rack-contrib/lib/rack/contrib/locale.rb at master · rack/rack-contrib](https://github.com/rack/rack-contrib/blob/master/lib/rack/contrib/locale.rb)

#### GeoIP Lite Country

根據用戶端的 IP 來決定城市/地域/城市這些資訊。

#### 使用者資料

讓使用者選語系，存到資料庫裡。

## Localized Views

app/views/books/index.html.erb

同目錄下有

index.es.html.erb 時，

Rails 會在 locale 設定為 `:es` 時渲染這個檔案。

## Locale 檔案的擺放位置

### config/locales 範例

```
|-defaults
|---es.rb
|---en.rb
|-models
|---book
|-----es.rb
|-----en.rb
|-views
|---defaults
|-----es.rb
|-----en.rb
|---books
|-----es.rb
|-----en.rb
|---users
|-----es.rb
|-----en.rb
|---navigation
|-----es.rb
|-----en.rb
```

Rails 預設不會載入 Nested 字典，要自己告訴 Rails:

```ruby
# config/application.rb
config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]
```

## I18n API 特色綜覽

深入探討特色如下：

* 搜尋翻譯
* 翻譯中做 interpolation
* 複數化翻譯
* 使用 HTML safe 的翻譯
* 本地化日期、數字、貨幣等。

### 搜尋翻譯

#### 最基本的尋找、Scope 以及 Nested Keys

__用字串或符號尋找。__

```ruby
I18n.t :message
I18n.t 'message'
```

`t` 方法接受一個 `:scope` 選項，可指定一個翻譯的命名空間：

```ruby
I18n.t :record_invalid, scope: [:activerecord, :errors, :messages]
```

上面那行會在

Active Record error messages 裡面找 `:record_invalid` 的對應翻譯。

也可這麼寫：

```ruby
I18n.translate "activerecord.errors.messages.record_invalid"
```

下列的方法呼叫全部相等：

```ruby
I18n.t 'activerecord.errors.messages.record_invalid'
I18n.t 'errors.messages.record_invalid', scope: :active_record
I18n.t :record_invalid, scope: 'activerecord.errors.messages'
I18n.t :record_invalid, scope: [:activerecord, :errors, :messages]
```

#### 添加預設值

找不到翻譯時會返回預設值：

```ruby
I18n.t :missing, default: 'Not here'
# => 'Not here'
```

先試找 `:missing`, 找不到接著找 `:also_missing`，兩個都沒找到返回 `'Not here'`。

```ruby
I18n.t :missing, default: [:also_missing, 'Not here']
# => 'Not here'
```

#### 一次找多個

```ruby
I18n.t [:odd, :even], scope: 'errors.messages'
# => ["must be odd", "must be even"]
```

獲得 Active Record error 訊息（hash 形式）：

```ruby
I18n.t 'activerecord.errors.messages'
# => {:inclusion=>"is not included in the list", :exclusion=> ... }
```

#### Lazy 查找

假設字典為：

```
es:
  books:
    index:
      title: "Título"
```

要在 `app/views/books/index.html.erb` 找到 `books.index.title`，這麼寫就可以了：

```ruby
<%= t '.title' %>
```

__注意有個點__

## 翻譯中插值

```ruby
I18n.backend.store_translations :en, thanks: 'Thanks %{name}!'
I18n.translate :thanks, name: 'Jeremy'
# => 'Thanks Jeremy!'
```

> If a translation uses :default or :scope as an interpolation variable, an I18n::ReservedInterpolationKey exception is raised. If a translation expects an interpolation variable, but this has not been passed to #translate, an I18n::MissingInterpolationArgument exception is raised.

## 複數化

英文單複數很簡單，其他語言有特殊的規則。

```ruby
I18n.backend.store_translations :en, inbox: {
  one: 'one message',
  other: '%{count} messages'
}
I18n.translate :inbox, count: 2
# => '2 messages'

I18n.translate :inbox, count: 1
# => 'one message'
```

沒有找到對應的複數形式，會返回 `18n::InvalidPluralizationData` exception。

## 設定與傳遞 locale

可以用 `I18n.locale` 設定：

```ruby
I18n.locale = :de
I18n.t :foo
I18n.l Time.now
```

也可明確的傳遞 locale:

```ruby
I18n.t :foo, locale: :de
I18n.l Time.now, locale: :de
```

`I18n.locale` 預設為 `I18n.default_locale` = `:en`

## 使用安全的 HTML 翻譯

```
# config/locales/en.yml
en:
  welcome: <b>welcome!</b>
  hello_html: <b>hello!</b>
  title:
    html: <b>title!</b>
```

```html
# app/views/home/index.html.erb
<div><%= t('welcome') %></div>
<div><%= raw t('welcome') %></div>
<div><%= t('hello_html') %></div>
<div><%= t('title.html') %></div>
```
![](http://edgeguides.rubyonrails.org/images/i18n/demo_html_safe.png)

## 儲存自己客製化的翻譯

可用兩種形式：Ruby 或 YAML 存。

```ruby
{
  pt: {
    foo: {
      bar: "baz"
    }
  }
}
```

對應的 YAML:

```yaml
pt:
  foo:
    bar: baz
```

locale 是 `pt`，`:foo` 是命名空間，`:bar` 是 `baz` 的翻譯。

__實際的例子：__

```yaml
en:
  date:
    formats:
      default: "%Y-%m-%d"
      short: "%b %d"
      long: "%B %d, %Y"
```

```ruby
I18n.t 'date.formats.short'
I18n.t 'formats.short', scope: :date
I18n.t :short, scope: 'date.formats'
I18n.t :short, scope: [:date, :formats]
```

推薦使用 YAML，非常特殊的格式再用 Ruby 的語法。

## 翻譯 Active Record Model

可用這兩個方法來找 model 與 attribute 的名字：

```ruby
Model.model_name.human
Model.human_attribute_name(attribute)
```

舉例：

```
en:
  activerecord:
    models:
      user: Dude
    attributes:
      user:
        login: "Handle"
      # 會把使用者的 attribute "login" 翻成 "Handle"
```

`User.model_name.human` 會返回 `"Dude"`，`User.human_attribute_name("login")` 會返回 `"Handle"`。

也可以設定 model 名稱的複數形式：

```
en:
  activerecord:
    models:
      user:
        one: Dude
        other: Dudes
```

```ruby
User.model_name.human(count: 2)
# => "Dudes"
```

### Error Message Scopes

預設只考慮單繼承的 table。可以讓你翻譯 models, attributes, 以及 validation 的訊息。

假設有 model 如下：

```ruby
class User < ActiveRecord::Base
  validates :name, presence: true
end
```

這個錯誤訊息的 key 是 `:blank`，Active Record 會在以下的命名空間尋找 `:blank`：

```ruby
activerecord.errors.models.[model_name].attributes.[attribute_name]
activerecord.errors.models.[model_name]
activerecord.errors.messages
errors.attributes.[attribute_name]
errors.messages
```

即在這些地方尋找：

```ruby
activerecord.errors.models.user.attributes.name.blank
activerecord.errors.models.user.blank
activerecord.errors.messages.blank
errors.attributes.name.blank
errors.messages.blank
```

表有繼承關係時，會往繼承鏈上找。

假設有 Admin model：

```ruby
class Admin < User
  validates :name, presence: true
end
```

則 Active Record 會依此順序尋找：

```ruby
activerecord.errors.models.admin.attributes.name.blank
activerecord.errors.models.admin.blank
activerecord.errors.models.user.attributes.name.blank
activerecord.errors.models.user.blank
activerecord.errors.messages.blank
errors.attributes.name.blank
errors.messages.blank
```

### 插值至錯誤訊息

舉例，錯誤訊息 `"can not be blank"` 可以換成 `"Please fill in your %{attribute}"`

Validation 關係對照表：

| validation   | with option               | message                   | interpolation |
| ------------ | ------------------------- | ------------------------- | ------------- |
| confirmation | -                         | :confirmation             | -             |
| acceptance   | -                         | :accepted                 | -             |
| presence     | -                         | :blank                    | -             |
| absence      | -                         | :present                  | -             |
| length       | :within, :in              | :too_short                | count         |
| length       | :within, :in              | :too_long                 | count         |
| length       | :is                       | :wrong_length             | count         |
| length       | :minimum                  | :too_short                | count         |
| length       | :maximum                  | :too_long                 | count         |
| uniqueness   | -                         | :taken                    | -             |
| format       | -                         | :invalid                  | -             |
| inclusion    | -                         | :inclusion                | -             |
| exclusion    | -                         | :exclusion                | -             |
| associated   | -                         | :invalid                  | -             |
| numericality | -                         | :not_a_number             | -             |
| numericality | :greater_than             | :greater_than             | count         |
| numericality | :greater_than_or_equal_to | :greater_than_or_equal_to | count         |
| numericality | :equal_to                 | :equal_to                 | count         |
| numericality | :less_than                | :less_than                | count         |
| numericality | :less_than_or_equal_to    | :less_than_or_equal_to    | count         |
| numericality | :only_integer    | :not_an_integer    | -         |
| numericality | :odd                      | :odd                      | -             |
| numericality | :even                     | :even                     | -             |

### 給 Helper 翻譯 Active Record error message

Rails 內建以下翻譯：

```ruby
en:
  activerecord:
    errors:
      template:
        header:
          one:   "1 error prohibited this %{model} from being saved"
          other: "%{count} errors prohibited this %{model} from being saved"
        body:    "There were problems with the following fields:"
```

得安裝 [DynamicForm](https://github.com/joelmoss/dynamic_form) 才可使用這 Helper。

## 翻譯 Action Mailer 的 subject

如果沒有給 `mail` 方法傳入 subject，ActionMailer 會試著在翻譯裡尋找。用來尋找的 key 的 pattern 為：

    <mailer_scope>.<action_name>.subject

```ruby
# user_mailer.rb
class UserMailer < ActionMailer::Base
  def welcome(user)
    #...
  end
end
```

```ruby
en:
  user_mailer:
    welcome:
      subject: "Welcome to Rails Guides!"
```

## 其它提供 I18n 的內建方法總覽

#### Action View Helper 方法

* `distance_of_time_in_words` 把時間翻成秒、分、小時。
參見 [datetime.distance_in_words](https://github.com/rails/rails/blob/master/actionview/lib/action_view/locale/en.yml#L4)。

* `datetime_select`、`select_month` 。參考 [date.month_names](https://github.com/rails/rails/blob/master/activesupport/lib/active_support/locale/en.yml#L15)。

`datetime_select` 參考 [date.order](https://github.com/rails/rails/blob/master/activesupport/lib/active_support/locale/en.yml#L18)

[datetime.prompts](https://github.com/rails/rails/blob/master/actionview/lib/action_view/locale/en.yml#L39)

* `number_to_currency`、`number_with_precision`、`number_to_percentage`、`number_with_delimiter`、`number_to_human_size`。參見 [number](https://github.com/rails/rails/blob/master/activesupport/lib/active_support/locale/en.yml#L37)。

#### Active Model 方法

* `model_name.human`、`human_attribute_name` 參考 [activerecord.models](https://github.com/rails/rails/blob/master/activerecord/lib/active_record/locale/en.yml#L36)。支持與 STI 一起使用。

* `ActiveModel::Errors#generate_message` 用了 `model_name.human` 與 `human_attribute_name` 。

* `ActiveModel::Errors#full_messages` prepends the attribute name to the error message using a separator that will be looked up from [errors.format](https://github.com/rails/rails/blob/master/activemodel/lib/active_model/locale/en.yml#L4) (and which defaults to `"%{attribute} %{message}"`).

#### Active Support 方法

* `Array#to_sentence` uses format settings as given in the [support.array](https://github.com/rails/rails/blob/master/activesupport/lib/active_support/locale/en.yml#L33) scope.

## 客製化你的 I18n

### 使用不同的 Backends

For several reasons the Simple backend shipped with Active Support only does the "simplest thing that could possibly work" _for Ruby on Rails_[^3] ... which means that it is only guaranteed to work for English and, as a side effect, languages that are very similar to English. Also, the simple backend is only capable of reading translations but can not dynamically store them to any format.

That does not mean you're stuck with these limitations, though. The Ruby I18n gem makes it very easy to exchange the Simple backend implementation with something else that fits better for your needs. E.g. you could exchange it with Globalize's Static backend:

```ruby
I18n.backend = Globalize::Backend::Static.new
```

You can also use the Chain backend to chain multiple backends together. This is useful when you want to use standard translations with a Simple backend but store custom application translations in a database or other backends. For example, you could use the Active Record backend and fall back to the (default) Simple backend:

```ruby
I18n.backend = I18n::Backend::Chain.new(I18n::Backend::ActiveRecord.new, I18n.backend)
```

### 使用不同的 Exception Handlers

The I18n API defines the following exceptions that will be raised by backends when the corresponding unexpected conditions occur:

```ruby
MissingTranslationData       # no translation was found for the requested key
InvalidLocale                # the locale set to I18n.locale is invalid (e.g. nil)
InvalidPluralizationData     # a count option was passed but the translation data is not suitable for pluralization
MissingInterpolationArgument # the translation expects an interpolation argument that has not been passed
ReservedInterpolationKey     # the translation contains a reserved interpolation variable name (i.e. one of: scope, default)
UnknownFileType              # the backend does not know how to handle a file type that was added to I18n.load_path
```

The I18n API will catch all of these exceptions when they are thrown in the backend and pass them to the default_exception_handler method. This method will re-raise all exceptions except for `MissingTranslationData` exceptions. When a `MissingTranslationData` exception has been caught, it will return the exception's error message string containing the missing key/scope.

The reason for this is that during development you'd usually want your views to still render even though a translation is missing.

In other contexts you might want to change this behavior, though. E.g. the default exception handling does not allow to catch missing translations during automated tests easily. For this purpose a different exception handler can be specified. The specified exception handler must be a method on the I18n module or a class with `#call` method:

```ruby
module I18n
  class JustRaiseExceptionHandler < ExceptionHandler
    def call(exception, locale, key, options)
      if exception.is_a?(MissingTranslation)
        raise exception.to_exception
      else
        super
      end
    end
  end
end

I18n.exception_handler = I18n::JustRaiseExceptionHandler.new
```

This would re-raise only the `MissingTranslationData` exception, passing all other input to the default exception handler.

However, if you are using `I18n::Backend::Pluralization` this handler will also raise `I18n::MissingTranslationData: translation missing: en.i18n.plural.rule` exception that should normally be ignored to fall back to the default pluralization rule for English locale. To avoid this you may use additional check for translation key:

```ruby
if exception.is_a?(MissingTranslation) && key.to_s != 'i18n.plural.rule'
  raise exception.to_exception
else
  super
end
```

Another example where the default behavior is less desirable is the Rails TranslationHelper which provides the method `#t` (as well as `#translate`). When a `MissingTranslationData` exception occurs in this context, the helper wraps the message into a span with the CSS class `translation_missing`.

To do so, the helper forces `I18n#translate` to raise exceptions no matter what exception handler is defined by setting the `:raise` option:

```ruby
I18n.t :foo, raise: true # always re-raises exceptions from the backend
```

## 給 Rails I18n 貢獻

### 當你有新成果時，記得到這公告：

[Mailing List](http://groups.google.com/group/rails-i18n!)

### 你的語言沒有預設的 locale?

複製一份現有的 locale，改好發 Pull Request 到這：[Rails-i18n](https://github.com/svenfuchs/rails-i18n/)

其它資源
---------

* [rails-i18n.org](http://rails-i18n.org) - Homepage of the rails-i18n project. You can find lots of useful resources on the [wiki](http://rails-i18n.org/wiki).
* [Google group: rails-i18n](http://groups.google.com/group/rails-i18n) - The project's mailing list.
* [GitHub: rails-i18n](https://github.com/svenfuchs/rails-i18n/tree/master) - Code repository for the rails-i18n project. Most importantly you can find lots of [example translations](https://github.com/svenfuchs/rails-i18n/tree/master/rails/locale) for Rails that should work for your application in most cases.
* [GitHub: i18n](https://github.com/svenfuchs/i18n/tree/master) - Code repository for the i18n gem.
* [Lighthouse: rails-i18n](http://i18n.lighthouseapp.com/projects/14948-rails-i18n/overview) - Issue tracker for the rails-i18n project.
* [Lighthouse: i18n](http://i18n.lighthouseapp.com/projects/14947-ruby-i18n/overview) - Issue tracker for the i18n gem.