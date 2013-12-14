# Active Record Callbacks

__特別要強調的翻譯名詞__

> Transactional 事務

本篇講解 Active Record 物件的生命週期，如何添加 hook、Callbacks。

讀完可能會學到...

* Active Record 物件的生命週期。
* 在生命週期裡加入 Callback 方法。
* 將 Callback 常見行為包裝成類別。

## 目錄

- [1. 物件的生命週期](#1-物件的生命週期)
  - [1.1 Callbacks 概觀](#11-callbacks-概觀)
    - [註冊 Callback](#註冊-callback)
- [3. 可用的 Callbacks](#3-可用的-callbacks)
  - [3.1 新建物件](#31-新建物件)
  - [3.2 更新物件](#32-更新物件)
  - [3.3 摧毀物件](#33-摧毀物件)
  - [3.4 `after_initialize` and `after_find`](#34-after_initialize-and-after_find)
- [4. 執行 Callbacks](#4-執行-callbacks)
- [5. 略過 Callbacks](#5-略過-callbacks)
- [6. 終止執行](#6-終止執行)
- [7. Relational Callbacks](#7-relational-callbacks)
- [8. 條件式 Callbacks](#8-條件式-callbacks)
  - [8.1 `Symbol`](#81-symbol)
  - [8.2 `String`](#82-string)
  - [8.3 `Proc`](#83-proc)
  - [8.4 Multiple Conditions for Callbacks](#84-multiple-conditions-for-callbacks)
- [9. Callback 類別](#9-callback-類別)
- [10. 事務 Callbacks](#10-事務-callbacks)

# 1. 物件的生命週期

常見的 Active Record 物件操作流程裡，我們新建、更新、毀滅物件。

在這個生命週期裡，可以 加入 hook （Callback）來控制應用程式的流程與資料。

Callbacks 則可以在物件操作前後添加邏輯。

## 1.1 Callbacks 概觀

Callback 在生命週期某個時間點會呼叫的方法。有了 callback，可以在 Active Record 物件， __新建、儲存、更新、刪除、驗證、加載__前，執行你想要的邏輯。

> created, saved, updated, deleted, validated, loaded

### 註冊 Callback

要使用 Callback 要先註冊。可用普通方法或是 macro 風格的類別方法來註冊：

```ruby
class User < ActiveRecord::Base
  validates :login, :email, presence: true

  before_validation :ensure_login_has_a_value

  protected
    def ensure_login_has_a_value
      if login.nil?
        self.login = email unless email.blank?
      end
    end
end
```

如果 Callback 邏輯很短只有一行，macro 風格的類別方法允許使用區塊

```ruby
class User < ActiveRecord::Base
  validates :login, :email, presence: true

  before_create do
    self.name = login.capitalize if name.blank?
  end
end
```

也可針對特定方法註冊 Callback，如 `create`：

```ruby
class User < ActiveRecord::Base
  before_validation :normalize_name, on: :create

  # :on takes an array as well
  after_validation :set_location, on: [ :create, :update ]

  protected
    def normalize_name
      self.name = self.name.downcase.titleize
    end

    def set_location
      self.location = LocationService.query(self)
    end
end
```

通常 Callback 方法會聲明為 `protected` 或 `private` 方法。聲明成 `public` 方法有可能會在 Model 外被呼叫，違反了物件封裝的精神。

# 3. 可用的 Callbacks

以下是 Active Record 可用的 Callbacks，依照__呼叫順序排序__：

## 3.1 新建物件

* `before_validation`
* `after_validation`
* `before_save`
* `around_save`
* `before_create`
* `around_create`
* `after_create`
* `after_save`

## 3.2 更新物件

* `before_validation`
* `after_validation`
* `before_save`
* `around_save`
* `before_update`
* `around_update`
* `after_update`
* `after_save`

## 3.3 摧毀物件

* `before_destroy`
* `around_destroy`
* `after_destroy`

__警告！__ `after_save` 在 `create` 與 `update` 都會執行，並總是在更為具體的 `after_create` 與 `after_update` 之後執行！

## 3.4 `after_initialize` and `after_find`

不管是 `new` 一個 Active Record 物件，還是從資料庫裡取出 record 時，都會呼叫 `after_initialize`，當你想覆寫 Active Record 的 `initialize` 方法時，可以用 `after_initialize` 來取代。

從資料庫取出 Active Record 物件時會呼叫 `after_find`，`after_find` 呼叫完才會呼叫 `after_initialize`。

`after_initialize` 與 `after_find` 沒有對應的 `before_*`。

看個例子：


```ruby
class User < ActiveRecord::Base
  after_initialize do |user|
    puts "You have initialized an object!"
  end

  after_find do |user|
    puts "You have found an object!"
  end
end

>> User.new
You have initialized an object!
=> #<User id: nil>

>> User.first
You have found an object!
You have initialized an object!
=> #<User id: 1>
```

### `after_touch`

The `after_touch` callback will be called whenever an Active Record object is touched.

```ruby
class User < ActiveRecord::Base
  after_touch do |user|
    puts "You have touched an object"
  end
end

>> u = User.create(name: 'Kuldeep')
=> #<User id: 1, name: "Kuldeep", created_at: "2013-11-25 12:17:49", updated_at: "2013-11-25 12:17:49">

>> u.touch
You have touched an object
=> true
```

It can be used along with `belongs_to`:

```ruby
class Employee < ActiveRecord::Base
  belongs_to :company, touch: true
  after_touch do
    puts 'An Employee was touched'
  end
end

class Company < ActiveRecord::Base
  has_many :employees
  after_touch :log_when_employees_or_company_touched

  private
  def log_when_employees_or_company_touched
    puts 'Employee/Company was touched'
  end
end

>> @employee = Employee.last
=> #<Employee id: 1, company_id: 1, created_at: "2013-11-25 17:04:22", updated_at: "2013-11-25 17:05:05">

# triggers @employee.company.touch
>> @employee.touch
Employee/Company was touched
An Employee was touched
=> true
```

# 4. 執行 Callbacks

以下方法會觸發 Callbakcs：

* `create`
* `create!`
* `decrement!`
* `destroy`
* `destroy!`
* `destroy_all`
* `increment!`
* `save`
* `save!`
* `save(validate: false)`
* `toggle!`
* `touch`
* `update_attribute`
* `update`
* `update!`
* `valid?`

另外 `after_find` 由下列 Finder 方法觸發：

* `all`
* `first`
* `find`
* `find_by`
* `find_by_*`
* `find_by_*!`
* `find_by_sql`
* `last`

`after_initialize` Callback 在每次 Active Record 物件 initialized 時觸發。

這些 Finder 方法是 Active Record 給每個 attribute 動態產生的，參見 [Dynamic finders](/guides/edge-translation/active-record-querying-zh_TW.md#dynamic-finders) 一節。

# 5. 略過 Callbacks

可用下列方法來略過 Callback。

* `decrement`
* `decrement_counter`
* `delete`
* `delete_all`
* `increment`
* `increment_counter`
* `toggle`
* `update_column`
* `update_columns`
* `update_all`
* `update_counters`

__小心使用這些方法，因為 Callback 可能有重要的業務邏輯。__

# 6. 終止執行

為 Model 註冊新的 Callback 時，Callback 會加入執行佇列裡。這個佇列包含了所有的驗證、Callbacks、資料庫操作。

整個 Callback 鏈被包在一個事務裡。如果有任何的 _before_ Callback 方法回傳 `false` 或拋出異常，執行鏈會被終止，並 ROLLBACK。`after_callback` 拋出異常才會終止執行鏈。

__警告！__ 即便 Callback 鏈已終止，任何非 `ActiveRecord::Rollback` 的異常會被 Rails 重複拋出。拋出非 `ActiveRecord::Rollback` 可能會導致通常會回傳 `true` 或 `false` 的方法拋出異常，比如 `save`、`update`。

# 7. Relational Callbacks

Callback 也可穿透 Model 之間的關係。

舉個例子：使用者有許多文章，使用者的文章應在刪除使用者時一併刪除。使用者刪除後要顯示 `"Posts also destroyed"`，平常可在 `User` Model 裡加入 `after_destroy` Callback，但也可從 `Post` Model 下手：

```ruby
class User < ActiveRecord::Base
  has_many :posts, dependent: :destroy
end

class Post < ActiveRecord::Base
  after_destroy :log_destroy_action

  def log_destroy_action
    puts 'Posts also destroyed'
  end
end

>> user = User.first
=> #<User id: 1>
>> user.posts.create!
=> #<Post id: 1, user_id: 1>
>> user.destroy
Post destroyed
=> #<User id: 1>
```

# 8. 條件式 Callbacks

Callback 也可根據條件執行。透過 `:if`、`:unless` 選項，這倆選項接受 `Symbol`、`String`、`Proc` 或 `Array`。當 Callback 滿足某條件才執行時，請用 `:if`；Callback 不滿足某條件才執行時，請用 `:unless`。接下來分別看看 `:if` 與 `:unless` 分別在 `Symbol`、`String`、`Proc` 三種不同的使用情境下是如何工作的。

## 8.1 `Symbol`

> 謂詞，回傳真或假的條件式，比如 `:handsome?`。

傳入 `Symbol` 代表，在 Callback 執行之前，會呼叫的謂詞。使用 `:if` 時，若謂詞回傳 `false`，便不會執行該 Callback；使用 `:unless` 時，若謂詞回傳 `true`，便不會執行該 Callback。

```ruby
class Order < ActiveRecord::Base
  before_save :normalize_card_number, if: :paid_with_card?
end
```

## 8.2 `String`

傳入的字串將會使用 `eval` 做求值，所以必須是合法的 Ruby 程式碼。應該只在字串代表某個簡短條件下使用：

```ruby
class Order < ActiveRecord::Base
  before_save :normalize_card_number, if: "paid_with_card?"
end
```

## 8.3 `Proc`

適合撰寫簡短驗證方法的情況下使用，通常是單行：

```ruby
class Order < ActiveRecord::Base
  before_save :normalize_card_number,
    if: Proc.new { |order| order.paid_with_card? }
end
```

## 8.4 Multiple Conditions for Callbacks

`:if` 與 `:unless` 也可混用在同個 Callback：

```ruby
class Comment < ActiveRecord::Base
  after_create :send_email_to_author, if: :author_wants_emails?,
    unless: Proc.new { |comment| comment.post.ignore_comments? }
end
```

# 9. Callback 類別

有時某個 Callback 可能別的 Model 也可使用，這時可以包裝成類別。

比如我們有個 `PictureFile` Model，每次再刪除圖片後，都要檢查圖片是否仍存在。我們可能有別的 Model 也會需要檢查刪除後檔案是否存在，以下是將 `PictureFile` Model 的 `after_destroy` 包裝成類別的例子。

```ruby
class PictureFileCallbacks
  def after_destroy(picture_file)
    if File.exists?(picture_file.filepath)
      File.delete(picture_file.filepath)
    end
  end
end
```

如何用？

```ruby
class PictureFile < ActiveRecord::Base
  after_destroy PictureFileCallbacks.new
end
```

注意到 `PictureFileCallbacks` 我們寫的是 instance methods，所以使用此 Callback 時需要 `new`，通常會宣告成類別方法：


```ruby
class PictureFileCallbacks
  def self.after_destroy(picture_file)
    if File.exists?(picture_file.filepath)
      File.delete(picture_file.filepath)
    end
  end
end
```

使用時便不用 `new` 了：

```ruby
class PictureFile < ActiveRecord::Base
  after_destroy PictureFileCallbacks
end
```

Callback 類別裡可宣告多個 Callback 方法。

# 10. 事務 Callbacks

在資料庫事務完成操作時，有兩個 Callback 會被觸發，分別是 `after_commit` 與 `after_rollback`。這倆與 `after_save` 類似，只是他們在資料庫完成操作，比如 commit 或 roll back 後才觸發，這在 Active Record Model 需要與外部系統互動時很有用。

舉例來說，前面 `PictureFile` 的例子，需要在某個對應的 record 摧毀後再刪除圖片。如果 `after_destroy` Callback 之後有拋出異常，則會 roll back（因為 Model 操作都包在事務裡，），但此時圖片卻被刪掉了。比如 `picture_file_2` `save!` 時拋出異常：

```ruby
PictureFile.transaction do
  picture_file_1.destroy
  picture_file_2.save!
end
```

使用 `after_commit` Callback 可以解決這個問題。

```ruby
class PictureFile < ActiveRecord::Base
  after_commit :delete_picture_file_from_disk, on: [:destroy]

  def delete_picture_file_from_disk
    if File.exist?(filepath)
      File.delete(filepath)
    end
  end
end
```

注意 `:on` 選項指定何時觸發這個 Callback。沒指定時對所有 action 都會觸發。

`after_commit` 與 `after_rollback` 在新建、更新、摧毀 Model 時一定會執行。如果 `after_commit` 或 `after_rollback` Callback 其中一個拋出異常時，異常會被忽略，來確保彼此不會互相干擾。也是因為如此，如果你的 Callback 會拋出異常，記得 `rescue` 並在 Callback 裡處理好。
