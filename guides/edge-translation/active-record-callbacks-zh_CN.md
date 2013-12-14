# Active Record Callbacks

__特别要强调的翻译名词__

> Transactional 事务

本篇讲解 Active Record 对象的生命周期，如何添加 hook、Callbacks。

读完可能会学到...

* Active Record 对象的生命周期。
* 在生命周期里加入 Callback 方法。
* 将 Callback 常见行为包装成类别。

## 目录

- [1. 对象的生命周期](#1-对象的生命周期)
  - [1.1 Callbacks 概观](#11-callbacks-概观)
    - [注册 Callback](#注册-callback)
- [3. 可用的 Callbacks](#3-可用的-callbacks)
  - [3.1 创建对象](#31-创建对象)
  - [3.2 更新对象](#32-更新对象)
  - [3.3 销毁对象](#33-销毁对象)
  - [3.4 `after_initialize` and `after_find`](#34-after_initialize-and-after_find)
- [4. 执行 Callbacks](#4-执行-callbacks)
- [5. 略过 Callbacks](#5-略过-callbacks)
- [6. 终止执行](#6-终止执行)
- [7. Relational Callbacks](#7-relational-callbacks)
- [8. 条件式 Callbacks](#8-条件式-callbacks)
  - [8.1 `Symbol`](#81-symbol)
  - [8.2 `String`](#82-string)
  - [8.3 `Proc`](#83-proc)
  - [8.4 Multiple Conditions for Callbacks](#84-multiple-conditions-for-callbacks)
- [9. Callback 类别](#9-callback-类别)
- [10. 事务 Callbacks](#10-事务-callbacks)

# 1. 对象的生命周期

常见的 Active Record 对象操作流程里，我们创建、更新、销毁对象。

在这个生命周期里，可以 加入 hook （Callback）来控制应用程式的流程与数据。

Callbacks 则可以在对象操作前后添加逻辑。

## 1.1 Callbacks 概观

Callback 在生命周期某个时间点会调用的方法。有了 callback，可以在 Active Record 对象， __创建、储存、更新、删除、验证、加载__前，执行你想要的逻辑。

> created, saved, updated, deleted, validated, loaded

### 注册 Callback

要使用 Callback 要先注册。可用普通方法或是 macro 风格的类别方法来注册：

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

如果 Callback 逻辑很短只有一行，macro 风格的类别方法允许使用区块

```ruby
class User < ActiveRecord::Base
  validates :login, :email, presence: true

  before_create do
    self.name = login.capitalize if name.blank?
  end
end
```

也可针对特定方法注册 Callback，如 `create`：

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

通常 Callback 方法会声明为 `protected` 或 `private` 方法。声明成 `public` 方法有可能会在 Model 外被调用，违反了对象封装的精神。

# 3. 可用的 Callbacks

以下是 Active Record 可用的 Callbacks，依照__调用顺序排序__：

## 3.1 创建对象

* `before_validation`
* `after_validation`
* `before_save`
* `around_save`
* `before_create`
* `around_create`
* `after_create`
* `after_save`

## 3.2 更新对象

* `before_validation`
* `after_validation`
* `before_save`
* `around_save`
* `before_update`
* `around_update`
* `after_update`
* `after_save`

## 3.3 销毁对象

* `before_destroy`
* `around_destroy`
* `after_destroy`

__警告！__ `after_save` 在 `create` 与 `update` 都会执行，并总是在更为具体的 `after_create` 与 `after_update` 之后执行！

## 3.4 `after_initialize` and `after_find`

不管是 `new` 一个 Active Record 对象，还是从数据库里取出 record 时，都会调用 `after_initialize`，当你想覆写 Active Record 的 `initialize` 方法时，可以用 `after_initialize` 来取代。

从数据库取出 Active Record 对象时会调用 `after_find`，`after_find` 调用完才会调用 `after_initialize`。

`after_initialize` 与 `after_find` 没有对应的 `before_*`。

看个例子：


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

# 4. 执行 Callbacks

以下方法会触发 Callbakcs：

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

另外 `after_find` 由下列 Finder 方法触发：

* `all`
* `first`
* `find`
* `find_by`
* `find_by_*`
* `find_by_*!`
* `find_by_sql`
* `last`

`after_initialize` Callback 在每次 Active Record 对象 initialized 时触发。

这些 Finder 方法是 Active Record 给每个 attribute 动态产生的，参见 [Dynamic finders](/guides/edge-translation/active-record-querying-zh_TW.md#dynamic-finders) 一节。

# 5. 略过 Callbacks

可用下列方法来略过 Callback。

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

__小心使用这些方法，因为 Callback 可能有重要的业务逻辑。__

# 6. 终止执行

为 Model 注册新的 Callback 时，Callback 会加入执行队列里。这个队列包含了所有的验证、Callbacks、数据库操作。

整个 Callback 链被包在一个事务里。如果有任何的 _before_ Callback 方法返回 `false` 或抛出异常，执行链会被终止，并 ROLLBACK。`after_callback` 抛出异常才会终止执行链。

__警告！__ 即便 Callback 链已终止，任何非 `ActiveRecord::Rollback` 的异常会被 Rails 重复抛出。抛出非 `ActiveRecord::Rollback` 可能会导致通常会返回 `true` 或 `false` 的方法抛出异常，比如 `save`、`update`。

# 7. Relational Callbacks

Callback 也可穿透 Model 之间的关系。

举个例子：使用者有许多文章，使用者的文章应在删除使用者时一并删除。使用者删除后要显示 `"Posts also destroyed"`，平常可在 `User` Model 里加入 `after_destroy` Callback，但也可从 `Post` Model 下手：

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

# 8. 条件式 Callbacks

Callback 也可根据条件执行。透过 `:if`、`:unless` 选项，这俩选项接受 `Symbol`、`String`、`Proc` 或 `Array`。当 Callback 满足某条件才执行时，请用 `:if`；Callback 不满足某条件才执行时，请用 `:unless`。接下来分别看看 `:if` 与 `:unless` 分别在 `Symbol`、`String`、`Proc` 三种不同的使用情境下是如何工作的。

## 8.1 `Symbol`

> 谓词，返回真或假的条件式，比如 `:handsome?`。

传入 `Symbol` 代表，在 Callback 执行之前，会调用的谓词。使用 `:if` 时，若谓词返回 `false`，便不会执行该 Callback；使用 `:unless` 时，若谓词返回 `true`，便不会执行该 Callback。

```ruby
class Order < ActiveRecord::Base
  before_save :normalize_card_number, if: :paid_with_card?
end
```

## 8.2 `String`

传入的字串将会使用 `eval` 做求值，所以必须是合法的 Ruby 程式码。应该只在字串代表某个简短条件下使用：

```ruby
class Order < ActiveRecord::Base
  before_save :normalize_card_number, if: "paid_with_card?"
end
```

## 8.3 `Proc`

适合撰写简短验证方法的情况下使用，通常是单行：

```ruby
class Order < ActiveRecord::Base
  before_save :normalize_card_number,
    if: Proc.new { |order| order.paid_with_card? }
end
```

## 8.4 Multiple Conditions for Callbacks

`:if` 与 `:unless` 也可混用在同个 Callback：

```ruby
class Comment < ActiveRecord::Base
  after_create :send_email_to_author, if: :author_wants_emails?,
    unless: Proc.new { |comment| comment.post.ignore_comments? }
end
```

# 9. Callback 类别

有时某个 Callback 可能别的 Model 也可使用，这时可以包装成类别。

比如我们有个 `PictureFile` Model，每次再删除图片后，都要检查图片是否仍存在。我们可能有别的 Model 也会需要检查删除后档案是否存在，以下是将 `PictureFile` Model 的 `after_destroy` 包装成类别的例子。

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

注意到 `PictureFileCallbacks` 我们写的是实例方法，所以使用此 Callback 时需要 `new`，通常会宣告成类别方法：


```ruby
class PictureFileCallbacks
  def self.after_destroy(picture_file)
    if File.exists?(picture_file.filepath)
      File.delete(picture_file.filepath)
    end
  end
end
```

使用时便不用 `new` 了：

```ruby
class PictureFile < ActiveRecord::Base
  after_destroy PictureFileCallbacks
end
```

Callback 类别里可宣告多个 Callback 方法。

# 10. 事务 Callbacks

在数据库事务完成操作时，有两个 Callback 会被触发，分别是 `after_commit` 与 `after_rollback`。这俩与 `after_save` 类似，只是他们在数据库完成操作，比如 commit 或 roll back 后才触发，这在 Active Record Model 需要与外部系统交互时很有用。

举例来说，前面 `PictureFile` 的例子，需要在某个对应的 record 销毁后再删除图片。如果 `after_destroy` Callback 之后有抛出异常，则会 roll back（因为 Model 操作都包在事务里，），但此时图片却被删掉了。比如 `picture_file_2` `save!` 时抛出异常：

```ruby
PictureFile.transaction do
  picture_file_1.destroy
  picture_file_2.save!
end
```

使用 `after_commit` Callback 可以解决这个问题。

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

注意 `:on` 选项指定何时触发这个 Callback。没指定时对所有 action 都会触发。

`after_commit` 与 `after_rollback` 在创建、更新、销毁 Model 时一定会执行。如果 `after_commit` 或 `after_rollback` Callback 其中一个抛出异常时，异常会被忽略，来确保彼此不会互相干扰。也是因为如此，如果你的 Callback 会抛出异常，记得 `rescue` 并在 Callback 里处理好。
