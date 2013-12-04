Ruby on Rails 4.1 發佈記
===============================

__特別要強調的翻譯名詞__

> application 應用程式

> removed 移除（4.1 已經拿掉，不能用了）

> deprecated 棄用的、不宜使用的、過時的：即將在下一版移除的功能

> Config 配置

PR#12389 代表 Rails Repository 上 12389 號 Pull Request。

----

## Rails 4.1 精華摘要：

* Variants [Commit][variants]
* Spring [Commit][spring]
* Action View 從 Action Pack 抽離出來。

本篇僅涵蓋主要的變動。要了解關於已修復的 bug、變動等，請參考 Rails GitHub 主頁上的 [CHANGELOG][changelog] 或是 Rails 所有的 [Commits](https://github.com/rails/rails/commits/master)。

-------------------------------------------------------------------------------

升級至 Rails 4.1
----------------------

若是升級現有的應用程式，最好有好的測試覆蓋度。首先應先升級至 4.0，再升上 4.1。升級需要注意的事項在此篇[升級 Rails](/guides/edge-translation/upgrading-ruby-on-rails-zh_TW.md) 可以找到。

主要功能
--------------

### Variants

  針對手機、平板、桌上型電腦及瀏覽器，常需要 render 不同格式的模版：html、json、xml。
  Variant 簡化了這件事。

  Request variant 是一種特殊的 request 格式，像是 `:tablet`、`:phone` 或 `:desktop`。

  可在 `before_action` 裡設定 Variant

  ```ruby
  request.variant = :tablet if request.user_agent =~ /iPad/
  ```

  在 Controller `action` 裡，回應特殊格式跟處理別的格式相同：

  ```ruby
  respond_to do |format|
    format.html do |html|
      html.tablet # 會 render app/views/projects/show.html+tablet.erb
      html.phone { extra_setup; render ... }
    end
  end
  ```

  給每個 format 與 variant 提供模版：

  ```
  app/views/projects/show.html.erb
  app/views/projects/show.html+tablet.erb
  app/views/projects/show.html+phone.erb
  ```

### Spring

新版 Rails 4.1 應用程式出廠內建 "springified" 的 binstubs。
這表示 `bin/rails`、`bin/rake` 會自動預載 Spring 的環境。

**執行 rake 任務：**

```
bin/rake routes
```

**運行測試：**

```
bin/rake test
bin/rake test test/models
bin/rake test test/models/user_test.rb
```

**執行 console：**

```
bin/rails console
```

**查看 Spring**

```
$ spring status
Spring is running:

 1182 spring server | my_app | started 29 mins ago
 3656 spring app    | my_app | started 23 secs ago | test mode
 3746 spring app    | my_app | started 10 secs ago | development mode
```

請至 [Spring README](https://github.com/jonleighton/spring/blob/master/README.md)
來了解所有可用的功能。

文件
-------------


Railties
--------

請參考 [Changelog](https://github.com/rails/rails/blob/4-1-stable/railties/CHANGELOG.md) 來了解更多細節。

### 移除

__不再支援的功能，也就是沒得用了！__

*   移除了 `update:application_controller` rake task。

*   移除了 `Rails.application.railties.engines`。

*   Rails 移除了 `config.threadsafe!` 配置。

*   移除了 `ActiveRecord::Generators::ActiveModel#update_attributes`，
    請改用 `ActiveRecord::Generators::ActiveModel#update`。

*   移除了 `config.whiny_nils` 配置。

*   移除了用來跑測試的兩個 task：`rake test:uncommitted` 與 `rake test:recent`。

### 值得一提的變動

* `BACKTRACE` environment variable to show unfiltered backtraces for test
  failures. ([Commit](https://github.com/rails/rails/commit/84eac5dab8b0fe9ee20b51250e52ad7bfea36553))

* Expose `MiddlewareStack#unshift` to environment configuration. ([Pull Request #12479](https://github.com/rails/rails/pull/12479))

Action Mailer
-------------

請參考 [Changelog](https://github.com/rails/rails/blob/4-1-stable/actionmailer/CHANGELOG.md) 來了解更多細節。

### 值得一提的變動

*  Action Mailer 產生 mail 的時間會寫到 log 裡。參見 [Pull Request #12556](https://github.com/rails/rails/pull/12556)。

Active Model
------------

請參考 [Changelog][AM-CHANGELOG] 來了解更多細節。

### 棄用

* 棄用了 `Validator#setup`. This should be done manually now in the
  validator's constructor. ([Commit](https://github.com/rails/rails/commit/7d84c3a2f7ede0e8d04540e9c0640de7378e9b3a))

### 值得一提的變動

* `ActiveModel::Dirty` 加入新的 API：`reset_changes` and `changes_applied`，來控制改變的狀態。

Active Support
--------------

請參考 [Changelog](https://github.com/rails/rails/blob/4-1-stable/activesupport/CHANGELOG.md) 來了解更多細節。

### 移除



* 移除了 `String#encoding_aware?`（`core_ext/string/encoding`）.

* 移除了 `Module#local_constant_names` 請改用 `Module#local_constants`。

* 移除了 `DateTime.local_offset` 請改用 `DateTime.civil_from_fromat`。

* 移除了 `Logger` （`core_ext/logger.rb`）。

* 移除了 `Time#time_with_datetime_fallback`、`Time#utc_time` 與
  `Time#local_time`，請改用 `Time#utc` and `Time#local`。

* 移除了 `Hash#diff`。

* 移除了 `Date#to_time_in_current_zone` 請改用 `Date#in_time_zone`。

* 移除了 `Proc#bind`。

* 移除了 `Array#uniq_by` 與 `Array#uniq_by!`, 請改用 Ruby 原生的
  `Array#uniq` 與 `Array#uniq!`。

* 移除了 `ActiveSupport::BasicObject`, use
  `ActiveSupport::ProxyObject` instead。

* 移除了 `BufferedLogger`, 請改用 `ActiveSupport::Logger`。

* 移除了 `assert_present` 與 `assert_blank` methods，請改用 `assert
  object.blank?` 與 `assert object.present?`。

### 棄用

__Deprecated，下一版會移除的功能。__

* 棄用了 `Numeric#{ago,until,since,from_now}`，要明確的將數值轉成 `AS::Duration`。比如 `5.ago` 請改成 `5.seconds.ago`。 [PR#12389](https://github.com/rails/rails/pull/12389)

### 值得一提的變動

* 新增 `ActiveSupport::Testing::TimeHelpers#travel` 與 `#travel_to`。這兩個方法透過 stubbing `Time.now` 與 `Date.today`，可做時光旅行。參考 [PR#12824](https://github.com/rails/rails/pull/12824)。

* 新增 `Numeric#in_milliseconds`，像是 1 小時有幾毫秒：`1.hour.in_milliseconds`。可以將時間轉成毫秒餵給 JavaScript 的 `getTime()` 函數。參考 [Commit](https://github.com/rails/rails/commit/423249504a2b468d7a273cbe6accf4f21cb0e643)。

* Add `Date#middle_of_day`, `DateTime#middle_of_day` and `Time#middle_of_day`
  methods. Also added `midday`, `noon`, `at_midday`, `at_noon` and
  `at_middle_of_day` as
  aliases. ([Pull Request](https://github.com/rails/rails/pull/10879))

* Add `String#remove(pattern)` as a short-hand for the common pattern of
  `String#gsub(pattern,'')`. ([Commit](https://github.com/rails/rails/commit/5da23a3f921f0a4a3139495d2779ab0d3bd4cb5f))

* Remove 'cow' => 'kine' irregular inflection from default
  inflections. ([Commit](https://github.com/rails/rails/commit/c300dca9963bda78b8f358dbcb59cabcdc5e1dc9))

Action Pack
-----------

請參考 [Changelog][AP-CHANGELOG] 來了解更多細節。

### 移除

*   移除了 Rails application fallback for integration testing, set
    `ActionDispatch.test_app` instead.

*   移除了 `config.page_cache_extension` 配置。

*   更改 Action Controller 下列常數的名稱

        ActionController::AbstractRequest  => ActionDispatch::Request
        ActionController::Request          => ActionDispatch::Request
        ActionController::AbstractResponse => ActionDispatch::Response
        ActionController::Response         => ActionDispatch::Response
        ActionController::Routing          => ActionDispatch::Routing
        ActionController::Integration      => ActionDispatch::Integration
        ActionController::IntegrationTest  => ActionDispatch::IntegrationTest

### 值得一提的變動

* `#url_for` takes a hash with options inside an
  array. 參見 [PR#9599](https://github.com/rails/rails/pull/9599)。

* Add `session#fetch` method fetch behaves similarly to
  [Hash#fetch](http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-fetch),
  with the exception that the returned value is always saved into the
  session. ([Pull Request](https://github.com/rails/rails/pull/12692))

* 將 Action View 從 Action Pack 裡拿掉。 [PR#11032](https://github.com/rails/rails/pull/11032)。


Active Record
-------------

請參考 [Changelog][AR-CHANGELOG] 來了解更多細節。

### 移除

* 移除了 nil-passing to the following `SchemaCache` methods。
  `primary_keys`, `tables`, `columns` and `columns_hash`.

* 從 `ActiveRecord::Migrator#migrate` 移除了 block filter。

* 從 `ActiveRecord::Migrator` 移除了 String constructor。

* 移除了 scope 沒傳 callable object 的用法。

* 移除了 `transaction_joinable=` in favor of `begin_transaction。
  with `:joinable` option.

* 移除了 `decrement_open_transactions`。

* 移除了 `increment_open_transactions`。

* 移除了 `PostgreSQLAdapter#outside_transaction?`，可用 `#transaction_open?` 來取代。

* 移除了 `ActiveRecord::Fixtures.find_table_name` 請改用 `ActiveRecord::Fixtures.default_fixture_model_name`。

* 從 `SchemaStatements` 移除了 `columns_for_remove`。

* 移除了 `SchemaStatements#distinct`。

* 將棄用的 `ActiveRecord::TestCase` 移到 Rails test 裡。

* Removed support for deprecated option `:restrict` for `:dependent`
  in associations.

* Removed support for deprecated `:delete_sql`, `:insert_sql`, `:finder_sql`
  and `:counter_sql` options in associations.

* 從 Column 移除了 `type_cast_code` 方法。

* 移除了 `ActiveRecord::Base#connection` 實體方法，請透過 Class 來使用。

* 移除了 `auto_explain_threshold_in_seconds` 的警告。

* Remove deprecated `:distinct` option from `Relation#count`.

* Removed deprecated methods `partial_updates`, `partial_updates?` and
  `partial_updates=`.

* 移除了 `scoped`。

* 移除了 `default_scopes?`。

* Remove implicit join references that were deprecated in 4.0.

* 移掉 `activerecord-deprecated_finders` gem 的相依性。

* Removed usage of `implicit_readonly`. Please use `readonly` method
  explicitly to mark records as
  `readonly`. ([Pull Request](https://github.com/rails/rails/pull/10769))

### 棄用

* 棄用了任何地方都沒用到的 `quoted_locking_column` 方法。

* Deprecate the delegation of Array bang methods for associations.
  To use them, instead first call `#to_a` on the association to access the
  array to be acted
  on. ([Pull Request](https://github.com/rails/rails/pull/12129))

* Deprecate `ConnectionAdapters::SchemaStatements#distinct`,
  as it is no longer used by internals. ([Pull Request](https://github.com/rails/rails/pull/10556))

### 值得一提的變動

* Added `ActiveRecord::Base.to_param` for convenient "pretty" URLs derived from
  a model's attribute or
  method. ([Pull Request](https://github.com/rails/rails/pull/12891))

* Added `ActiveRecord::Base.no_touching`, which allows ignoring touch on
  models. ([Pull Request](https://github.com/rails/rails/pull/12772))

* Unify boolean type casting for `MysqlAdapter` and `Mysql2Adapter`.
  `type_cast` will return `1` for `true` and `0` for `false`. ([Pull Request](https://github.com/rails/rails/pull/12425))

* `.unscope` now removes conditions specified in
  `default_scope`. ([Commit](https://github.com/rails/rails/commit/94924dc32baf78f13e289172534c2e71c9c8cade))

* Added `ActiveRecord::QueryMethods#rewhere` which will overwrite an existing,
  named where condition. ([Commit](https://github.com/rails/rails/commit/f950b2699f97749ef706c6939a84dfc85f0b05f2))

* Extend `ActiveRecord::Base#cache_key` to take an optional list of timestamp
  attributes of which the highest will be used. ([Commit](https://github.com/rails/rails/commit/e94e97ca796c0759d8fcb8f946a3bbc60252d329))

* Added `ActiveRecord::Base#enum` for declaring enum attributes where the values
  map to integers in the database, but can be queried by
  name. ([Commit](https://github.com/rails/rails/commit/db41eb8a6ea88b854bf5cd11070ea4245e1639c5))

* Type cast json values on write, so that the value is consistent with reading
  from the database. ([Pull Request](https://github.com/rails/rails/pull/12643))

* Type cast hstore values on write, so that the value is consistent
  with reading from the database. ([Commit](https://github.com/rails/rails/commit/5ac2341fab689344991b2a4817bd2bc8b3edac9d))

* Make `next_migration_number` accessible for third party
  generators. ([Pull Request](https://github.com/rails/rails/pull/12407))

* Calling `update_attributes` will now throw an `ArgumentError` whenever it
  gets a `nil` argument. More specifically, it will throw an error if the
  argument that it gets passed does not respond to to
  `stringify_keys`. [PR#9860](https://github.com/rails/rails/pull/9860)。

* `CollectionAssociation#first`/`#last` (e.g. `has_many`) use a `LIMIT`ed
  query to fetch results rather than loading the entire
  collection. [PR#12137](https://github.com/rails/rails/pull/12137)。

* `inspect` on Active Record model classes does not initiate a new
  connection. This means that calling `inspect`, when the database is missing,
  will no longer raise an exception. [PR#11014](https://github.com/rails/rails/pull/11014)。

* Remove column restrictions for `count`, let the database raise if the SQL is
  invalid. [PR#10710](https://github.com/rails/rails/pull/10710)。

* Rails now automatically detects inverse associations. If you do not set the
  `:inverse_of` option on the association, then Active Record will guess the
  inverse association based on heuristics. [PR#10886](https://github.com/rails/rails/pull/10886)。

* Handle aliased attributes in ActiveRecord::Relation. When using symbol keys,
  ActiveRecord will now translate aliased attribute names to the actual column
  name used in the database. [PR#7839](https://github.com/rails/rails/pull/7839)。

致謝
-------

許多人花了寶貴的時間貢獻至 Rails 專案，使 Rails 成為更穩定、更強韌的網路框架，參考[完整的 Rails 貢獻者清單](http://contributors.rubyonrails.org/)，並感謝所有的貢獻者！

[AR-CHANGELOG]: https://github.com/rails/rails/blob/4-1-stable/activerecord/CHANGELOG.md
[AP-CHANGELOG]: https://github.com/rails/rails/blob/4-1-stable/actionpack/CHANGELOG.md
[AM-CHANGELOG]: https://github.com/rails/rails/blob/4-1-stable/activemodel/CHANGELOG.md
[variants]: https://github.com/rails/rails/commit/2d3a6a0cb8df0360dd588a4d2fb260dd07cc9bcf
[spring]: https://github.com/jonleighton/rails/commit/df50e3064abc3099adc524f381ffced0dab84869