Ruby on Rails 4.1 發佈記
===============================

Rails 4.1 精華摘要：

* Action View 從 Action Pack 抽離出來。

本篇僅涵蓋主要的變動。要了解關於已修復的 bug、變動等，請參考 Rails GitHub 主頁上的 CHANGELOG 或是 Rails 所有的 [Commits](https://github.com/rails/rails/commits/master)。

-------------------------------------------------------------------------------

升級至 Rails 4.1
----------------------

若是升級現有的應用程式，最好有好的測試覆蓋度。首先應先升級至 4.0，再升上 4.1。升級需要注意的事項在此篇[升級 Rails](/guides/edge-translation/upgrading-ruby-on-rails-zh_TW.md) 可以找到。

主要功能
--------------


文件
-------------


Railties
--------

請參考 [Changelog](https://github.com/rails/rails/blob/4-1-stable/railties/CHANGELOG.md) 來了解更多細節。

### 移除

*   Removed `update:application_controller` rake task.

*   Removed deprecated `Rails.application.railties.engines`.

*   Removed deprecated threadsafe! from Rails Config.

*   Remove deprecated `ActiveRecord::Generators::ActiveModel#update_attributes` in
    favor of `ActiveRecord::Generators::ActiveModel#update`

*   Remove deprecated `config.whiny_nils` option

*   Removed deprecated rake tasks for running tests: `rake test:uncommitted` and
    `rake test:recent`.

### 值得一提的變動

* `BACKTRACE` environment variable to show unfiltered backtraces for test
  failures. ([Commit](https://github.com/rails/rails/commit/84eac5dab8b0fe9ee20b51250e52ad7bfea36553))

* Expose MiddlewareStack#unshift to environment configuration. ([Pull Request](https://github.com/rails/rails/pull/12479))


Action Mailer
-------------

請參考 [Changelog](https://github.com/rails/rails/blob/4-1-stable/actionmailer/CHANGELOG.md) 來了解更多細節。

### 值得一提的變動

*   Instrument the generation of Action Mailer messages. The time it takes to
    generate a message is written to the log. ([Pull Request](https://github.com/rails/rails/pull/12556))


Active Model
------------

請參考 [Changelog](https://github.com/rails/rails/blob/4-1-stable/activemodel/CHANGELOG.md) 來了解更多細節。

### 棄用

* Deprecate `Validator#setup`. This should be done manually now in the
  validator's constructor. ([Commit](https://github.com/rails/rails/commit/7d84c3a2f7ede0e8d04540e9c0640de7378e9b3a))

### 值得一提的變動

* Added new API methods `reset_changes` and `changes_applied` to
  `ActiveModel::Dirty` that control changes state.

Active Support
--------------

請參考 [Changelog](https://github.com/rails/rails/blob/4-1-stable/activesupport/CHANGELOG.md) 來了解更多細節。

### 移除

* Remove deprecated `String#encoding_aware?` core extensions (`core_ext/string/encoding`).

* Remove deprecated `Module#local_constant_names` in favor of `Module#local_constants`.

* Remove deprecated `DateTime.local_offset` in favor of `DateTime.civil_from_fromat`.

* Remove deprecated `Logger` core extensions (`core_ext/logger.rb`).

* Remove deprecated `Time#time_with_datetime_fallback`, `Time#utc_time` and
  `Time#local_time` in favor of `Time#utc` and `Time#local`.

* Remove deprecated `Hash#diff` with no replacement.

* Remove deprecated `Date#to_time_in_current_zone` in favor of `Date#in_time_zone`.

* Remove deprecated `Proc#bind` with no replacement.

* Remove deprecated `Array#uniq_by` and `Array#uniq_by!`, use native
  `Array#uniq` and `Array#uniq!` instead.

* Remove deprecated `ActiveSupport::BasicObject`, use
  `ActiveSupport::ProxyObject` instead.

* Remove deprecated `BufferedLogger`, use `ActiveSupport::Logger` instead.

* Remove deprecated `assert_present` and `assert_blank` methods, use `assert
  object.blank?` and `assert object.present?` instead.

### 棄用

* Deprecated `Numeric#{ago,until,since,from_now}`, the user is expected to
  explicitly convert the value into an AS::Duration, i.e. `5.ago` => `5.seconds.ago`
  ([Pull Request](https://github.com/rails/rails/pull/12389))

### 值得一提的變動

* Add `ActiveSupport::Testing::TimeHelpers#travel` and `#travel_to`. These
methods change current time to the given time or time difference by stubbing
`Time.now` and
`Date.today`. ([Pull Request](https://github.com/rails/rails/pull/12824))

* Added `Numeric#in_milliseconds`, like `1.hour.in_milliseconds`, so we can feed
  them to JavaScript functions like
  `getTime()`. ([Commit](https://github.com/rails/rails/commit/423249504a2b468d7a273cbe6accf4f21cb0e643))

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

請參考 [Changelog](https://github.com/rails/rails/blob/4-1-stable/actionpack/CHANGELOG.md) 來了解更多細節。

### 移除

*   Remove deprecated Rails application fallback for integration testing, set
    `ActionDispatch.test_app` instead.

*   Remove deprecated `page_cache_extension` config.

*   Remove deprecated constants from Action Controller:

        ActionController::AbstractRequest  => ActionDispatch::Request
        ActionController::Request          => ActionDispatch::Request
        ActionController::AbstractResponse => ActionDispatch::Response
        ActionController::Response         => ActionDispatch::Response
        ActionController::Routing          => ActionDispatch::Routing
        ActionController::Integration      => ActionDispatch::Integration
        ActionController::IntegrationTest  => ActionDispatch::IntegrationTest

### 值得一提的變動

* Take a hash with options inside array in
  `#url_for`. ([Pull Request](https://github.com/rails/rails/pull/9599))

* Add `session#fetch` method fetch behaves similarly to
  [Hash#fetch](http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-fetch),
  with the exception that the returned value is always saved into the
  session. ([Pull Request](https://github.com/rails/rails/pull/12692))

* Separate Action View completely from Action
  Pack. ([Pull Request](https://github.com/rails/rails/pull/11032))


Active Record
-------------

請參考 [Changelog](https://github.com/rails/rails/blob/4-1-stable/activerecord/CHANGELOG.md) 來了解更多細節。

### 移除

* Remove deprecated nil-passing to the following `SchemaCache` methods:
  `primary_keys`, `tables`, `columns` and `columns_hash`.

* Remove deprecated block filter from `ActiveRecord::Migrator#migrate`.

* Remove deprecated String constructor from `ActiveRecord::Migrator`.

* Remove deprecated `scope` use without passing a callable object.

* Remove deprecated `transaction_joinable=` in favor of `begin_transaction`
  with `:joinable` option.

* Remove deprecated `decrement_open_transactions`.

* Remove deprecated `increment_open_transactions`.

* Remove deprecated `PostgreSQLAdapter#outside_transaction?`
  method. You can use `#transaction_open?` instead.

* Remove deprecated `ActiveRecord::Fixtures.find_table_name` in favor of
  `ActiveRecord::Fixtures.default_fixture_model_name`.

* Removed deprecated `columns_for_remove` from `SchemaStatements`.

* Remove deprecated `SchemaStatements#distinct`.

* Move deprecated `ActiveRecord::TestCase` into the rails test
  suite. The class is no longer public and is only used for internal
  Rails tests.

* Removed support for deprecated option `:restrict` for `:dependent`
  in associations.

* Removed support for deprecated `delete_sql` in associations.

* Removed support for deprecated `insert_sql` in associations.

* Removed support for deprecated `finder_sql` in associations.

* Removed support for deprecated `counter_sql` in associations.

* Removed deprecated method `type_cast_code` from Column.

* Removed deprecated options `delete_sql` and `insert_sql` from HABTM
  association.

* Removed deprecated options `finder_sql` and `counter_sql` from
  collection association.

* Remove deprecated `ActiveRecord::Base#connection` method.
  Make sure to access it via the class.

* Remove deprecation warning for `auto_explain_threshold_in_seconds`.

* Remove deprecated `:distinct` option from `Relation#count`.

* Removed deprecated methods `partial_updates`, `partial_updates?` and
  `partial_updates=`.

* Removed deprecated method `scoped`

* Removed deprecated method `default_scopes?`

* Remove implicit join references that were deprecated in 4.0.

* Remove `activerecord-deprecated_finders` as a dependency

* Usage of `implicit_readonly` is being removed`. Please use `readonly` method
  explicitly to mark records as
  `readonly. ([Pull Request](https://github.com/rails/rails/pull/10769))

### 棄用

* Deprecate `quoted_locking_column` method, which isn't used anywhere.

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
  `stringify_keys`. ([Pull Request](https://github.com/rails/rails/pull/9860))

* `CollectionAssociation#first`/`#last` (e.g. `has_many`) use a `LIMIT`ed
  query to fetch results rather than loading the entire
  collection. ([Pull Request](https://github.com/rails/rails/pull/12137))

* `inspect` on Active Record model classes does not initiate a new
  connection. This means that calling `inspect`, when the database is missing,
  will no longer raise an exception. ([Pull Request](https://github.com/rails/rails/pull/11014))

* Remove column restrictions for `count`, let the database raise if the SQL is
  invalid. ([Pull Request](https://github.com/rails/rails/pull/10710))

* Rails now automatically detects inverse associations. If you do not set the
  `:inverse_of` option on the association, then Active Record will guess the
  inverse association based on heuristics. ([Pull Request](https://github.com/rails/rails/pull/10886))

* Handle aliased attributes in ActiveRecord::Relation. When using symbol keys,
  ActiveRecord will now translate aliased attribute names to the actual column
  name used in the database. ([Pull Request](https://github.com/rails/rails/pull/7839))

致謝
-------

許多人花了寶貴的時間貢獻至 Rails 專案，使 Rails 成為更穩定、更強韌的網路框架，參見[完整的 Rails 貢獻者清單](http://contributors.rubyonrails.org/)，並感謝所有的貢獻者！
