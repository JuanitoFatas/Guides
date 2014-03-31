Active Record 驗證
=========================

本篇教您如何使用 Active Record 的驗證功能，在資料存入資料庫前，驗證物件的狀態。

讀完本篇後，您將學會：

* 如何使用 Active Record 內建的驗證 Helpers。
* 如何新建自己的驗證方法。
* 如何處理驗證時所產生的錯誤訊息。

--------------------------------------------------------------------------------

驗證綜覽
--------------------

以下是驗證的一個簡單例子：

```ruby
class Person < ActiveRecord::Base
  validates :name, presence: true
end

Person.create(name: "John Doe").valid? # => true
Person.create(name: nil).valid? # => false
```

如您所見，驗證讓我們知道 `Person` 必須要有 `name` 屬性才算有效。上例第二個建立的 `Person` 不會存至資料庫。

在深入了解之前，先談談驗證在應用程式裡扮演的角色。

### 為什麼要驗證？

驗證用來確保只有有效的資料才能存入資料庫。譬如，每個使用者需要填寫有效的 E-mail 與郵件地址。在 Model 層級驗證資料是最好的，只有通過驗證的資料方可存入資料庫。因為在 Model 層面驗證不考慮資料庫的種類、使用者無法跳過、容易測試與維護。Rails 使得資料驗證非常易用，提供了各種內建 Helpers 來滿足常見的需求，也允許新建自定的驗證方法。

在存入資料庫前有樹種驗證方法，包含了原生的資料庫約束、用戶端驗證、Controller 層級驗證。以下是各種方法的優缺點：

* 資料庫約束和 stored procedure 讓驗證機制只適用單一資料庫，不好測試，也更難維護。但若是其它應用程式也使用您的資料庫，有某些資料庫層級的約束可能有用。除此之外，資料庫層級的驗證可以安全地處理某些問題（像是在使用頻繁的資料表裡檢查唯一性），這倘若不在資料庫層級做，其它層級做起來可能很困難。
* 用戶端驗證很有用，但單獨使用時可靠性不高。若是用 JavaScript 實作，關掉 JavaScript 便可跳過驗證。但結合其它種驗證方式，用戶端驗證可提供使用者即時的反饋。
* Controller 層級驗證聽起來很誘人，但用起來很笨重，也很難測試與維護。不管怎麼說，盡量保持 Controller 輕巧短小，長遠下來看，應用程式會更好維護。

根據不同場合選擇驗證方式。Rails 團隊認為 Model 層級的驗證最符合多數應用場景。

### 驗證何時發生？

Active Record 物件有兩種：一種對應到資料庫的列、另一種沒有。當新建一個新的物件時，比如使用 `new` 方法，物件此時並不屬於資料庫。一旦對物件呼叫 `save`，則物件會存入對應的資料表裡。Active Record 使用 `new_record?` 這個實例方法來決定物件是否已存在資料庫。看看下面這個簡單的 Active Record 類別：

```ruby
class Person < ActiveRecord::Base
end
```

可以在 `rails console` 下試試這是怎麼工作的：

```ruby
$ rails console
>> p = Person.new(name: "John Doe")
=> #<Person id: nil, name: "John Doe", created_at: nil, updated_at: nil>
>> p.new_record?
=> true
>> p.save
=> true
>> p.new_record?
=> false
```

新建與儲存新紀錄（record），會對資料庫做 SQL 的 `INSERT` 操作。更新已存在的記錄則會做 `UPDATE`。驗證通常在這些 SQL 執行之前就發生了。如果驗證失敗，則物件會被標示為無效的，Active Record 便不會執行 `INSERT` 或是 `UPDATE`。這避免了存入無效的物件到資料庫。您可以指定在物件建立時、儲存時、更新時，各個階段要做何種資料驗證。

CAUTION: 有許多種方法可以改變資料庫裡物件的狀態。某些方法會觸發驗證、某些不會。這表示有可能會不小心將無效的物件存入資料庫。

以下方法會觸發驗證，只會在物件有效時，把物件存入資料庫：

* `create`
* `create!`
* `save`
* `save!`
* `update`
* `update!`

這些方法對應的 BANG 版本（比如 `save!`），會對無效的記錄拋出異常。非 BANG 方法則不會，`save` 與 `update` 僅回傳 `false`，`create` 僅回傳物件本身。

### 略過驗證

以下這些方法會略過驗證，不考慮資料有效無效便將物件存入資料庫。應謹慎使用。

* `decrement!`
* `decrement_counter`
* `increment!`
* `increment_counter`
* `toggle!`
* `touch`
* `update_all`
* `update_attribute`
* `update_column`
* `update_columns`
* `update_counters`

注意 `save` 也能夠略過驗證，傳入 `validate: false` 作為參數即可。這個技巧要小心使用。

* `save(validate: false)`

### `valid?` 與 `invalid?`

檢查物件是否有效，Rails 使用的是 `valid?` 方法。您也可以直接呼叫此方法，來觸發驗證。物件若沒有錯誤會回傳 `true`，反之回傳 `false`。前面已經見過了：

```ruby
class Person < ActiveRecord::Base
  validates :name, presence: true
end

Person.create(name: "John Doe").valid? # => true
Person.create(name: nil).valid? # => false
```

Active Record 做完驗證後，所有找到的錯誤都可透過 `errors.messages` 這個實例方法來存取，會回傳錯誤集合。就定義來說，物件做完驗證後，錯誤集合為空才是有效的。

注意到用 `new` 實例化出來的物件，即便有錯誤也不會說，因為 `new` 是不會觸發任何驗證的。

```ruby
class Person < ActiveRecord::Base
  validates :name, presence: true
end

>> p = Person.new
# => #<Person id: nil, name: nil>
>> p.errors.messages
# => {}

>> p.valid?
# => false
>> p.errors.messages
# => {name:["can't be blank"]}

>> p = Person.create
# => #<Person id: nil, name: nil>
>> p.errors.messages
# => {name:["can't be blank"]}

>> p.save
# => false

>> p.save!
# => ActiveRecord::RecordInvalid: Validation failed: Name can't be blank

>> Person.create!
# => ActiveRecord::RecordInvalid: Validation failed: Name can't be blank
```

`invalid?` 是 `valid?` 的反相。物件找到任何錯誤回傳 `true`，反之回傳 `false`。

### `errors[]`

要檢查物件的特定屬性是否有效，可以使用 `errors[:attribute]`，會以陣列形式返回該屬性的所有錯誤，沒有錯誤則返回空陣列。

這個方法只有在驗證後呼叫才有用，因為它只是檢查 `errors` 集合，而不會觸發驗證。`errors[:attribute]` 與 `ActiveRecord::Base#invalid?` 方法不同，因為它不是檢查整個物件的有效性，只是檢查物件單一屬性是否有錯誤。

```ruby
class Person < ActiveRecord::Base
  validates :name, presence: true
end

>> Person.new.errors[:name].any? # => false
>> Person.create.errors[:name].any? # => true
```

在[處理驗證錯誤]一節會更深入講解驗證錯誤。現在讓我們看看 Rails 內建的驗證 Helpers 有那些。

驗證 Helpers
------------------

Active Record 提供了許多預先定義的驗證 Helpers 供您直接在類別定義中使用。這些 Helpers 提供了常見的驗證規則。每當驗證失敗時，驗證訊息會新增到物件的 `errors` 集合，這個訊息與出錯的屬性是相關聯的。


每個 Helper 皆接受任意數量的屬性名稱，所以一行程式碼，便可給多個屬性加入同樣的驗證。

所有的 Helpers 皆接受 `:on` 與 `:message` 選項，分別用來指定何時做驗證、出錯時的錯誤訊息。每個驗證 Helpers 都有預設的錯誤訊息。這些訊息在沒有指定 `:message` 選項時很有用。讓我們看看每一個可用的 Helpers。

### `acceptance`

這個方法在表單送出時，檢查 UI 的 checkbox 是否有打勾。這對於使用者需要接受服務條款、隱私權政策等相關的場景下很有用。這個驗證僅針對網頁應用程式，且不需要存入資料庫（如果沒有為 `acceptance` 開一個欄位，Helper 自己會使用一個虛擬屬性）。

```ruby
class Person < ActiveRecord::Base
  validates :terms_of_service, acceptance: true
end
```

這個 Helper 預設的錯誤訊息是 _"must be accepted"_。

這個方法接受一個 `:accept` 選項，用來決定什麼值代表“接受”。預設是 “1”，改成別的也很簡單。

```ruby
class Person < ActiveRecord::Base
  validates :terms_of_service, acceptance: { accept: 'yes' }
end
```

### `validates_associated`

當 Model 與其它 Model 有關聯，且與之關聯的 Model 也需要驗證時，用這個方法來處理。在儲存物件時，會對相關聯的物件呼叫 `valid?`。

```ruby
class Library < ActiveRecord::Base
  has_many :books
  validates_associated :books
end
```

所有的關聯類型皆適用此方法。

CAUTION: 不要在關聯的兩邊都使用 `validates_associated`。它們會互相呼叫陷入無窮迴圈。

`validates_associated` 預設錯誤訊息是 _"is invalid"_。注意到每個關聯的物件會有自己的 `errors` 集合。錯誤不會集中到呼叫該方法的 Model。

### `confirmation`

當有兩個 text field 內容需要完全相同時，使用這個方法。比如可能想要確認 E-mail 或密碼兩次輸入是否相同。這個驗證會新建一個虛擬屬性，名字是該欄位（field）的名稱，後面加上 `_confirmation`。

```ruby
class Person < ActiveRecord::Base
  validates :email, confirmation: true
end
```

在 View 模版（template）裡，可以這麼用：

```erb
<%= text_field :person, :email %>
<%= text_field :person, :email_confirmation %>
```

只有 `email_confirmation` 不為 `nil` 時，才會做驗證。需要確認的話，記得要給 `email_confirmation` 屬性加上存在性（presence）驗證（稍後介紹 `presence`）：

```ruby
class Person < ActiveRecord::Base
  validates :email, confirmation: true
  validates :email_confirmation, presence: true
end
```

`confirmation` 預設錯誤訊息是  _"doesn't match confirmation"_。

### `exclusion`

這個方法驗證屬性是否“不屬於”某個給定的集合。集合可以是任何 `Enumerable` 的物件。

```ruby
class Account < ActiveRecord::Base
  validates :subdomain, exclusion: { in: %w(www us ca jp),
    message: "%{value} is reserved." }
end
```

`exclusion` 有 `:in` 選項，接受一組數值，決定屬性“不可接受”的值。`:in` 別名為 `:within`。上例使用了 `:message` 選項來示範如何在錯誤訊息裡印出屬性的值。

`exclusion` 預設錯誤訊息是  _"is reserved"_。

### `format`

這個方法驗證屬性的值是否匹配一個透過 `:with` 給定的正規表達式。

```ruby
class Product < ActiveRecord::Base
  validates :legacy_code, format: { with: /\A[a-zA-Z]+\z/,
    message: "only allows letters" }
end
```

`format` 預設錯誤訊息是  _"is invalid"_.

### `inclusion`

這個方法驗證屬性是否“屬於”某個給定的集合。集合可以是任何 `Enumerable` 的物件。

```ruby
class Coffee < ActiveRecord::Base
  validates :size, inclusion: { in: %w(small medium large),
    message: "%{value} is not a valid size" }
end
```

`inclusion` 有 `:in` 選項，接受一組數值，決定屬性“可接受”的值。`:in` 的別名為 `:within`。上例使用了 `:message` 選項來示範如何在錯誤訊息裡印出屬性的值。

`inclusion` 預設錯誤訊息是 _"is not included in the list"_。

### `length`

這個方法驗證屬性值的長度。有多種選項來限制長度（如下所示）：

```ruby
class Person < ActiveRecord::Base
  validates :name, length: { minimum: 2 }
  validates :bio, length: { maximum: 500 }
  validates :password, length: { in: 6..20 }
  validates :registration_number, length: { is: 6 }
end
```

長度限制選項有：

* `:minimum` - 屬性值的長度的最小值。
* `:maximum` - 屬性值的長度的最大值。
* `:in` (or `:within`) - 屬性值的長度所屬的區間。這個選項的值必須是一個範圍。
* `:is` - T屬性值的長度必須等於。

預設錯誤訊息取決於用的是那種長度驗證方法。可以使用 `:wrong_length`、`too_long`、`too_short` 選項，以及 `%{count}` 來客製化訊息。使用 `:message` 也是可以的。

```ruby
class Person < ActiveRecord::Base
  validates :bio, length: { maximum: 1000,
    too_long: "%{count} characters is the maximum allowed" }
end
```

這個方法計算長度的預設單位是字元。但可以用 `:tokenizer` 選項來修改，比如取一個字為最小單位：

```ruby
class Essay < ActiveRecord::Base
  validates :content, length: {
    minimum: 300,
    maximum: 400,
    tokenizer: lambda { |str| str.scan(/\w+/) },
    too_short: "must have at least %{count} words",
    too_long: "must have at most %{count} words"
  }
end
```

注意到預設的錯誤訊息是複數。（例如，"is too short (minimum
is %{count} characters)"）。故當 `:minimum` 為 1 時，要提供一個自訂的訊息，或者是使用 `presence: true` 取代。當 `:in` 或 `:within` 下限小於 1 時，應該要提供一個自訂的訊息，或者是在驗證 `length` 之前，先驗證 `presence`。

### `numericality`

這個方法驗證屬性是不是純數字。預設會匹配帶有正負號（可選）的整數或浮點數。只允許整數可以透過將 `:only_integer` 為 `true`。

`:only_integer` 為 `true`，會使用下面的正規表達式來檢查屬性的值：

```ruby
/\A[+-]?\d+\Z/
```

否則會嘗試使用 `Float` 將值轉為數字。

WARNING. 注意上面的正規表達式允許最後有新行字元。

```ruby
class Player < ActiveRecord::Base
  validates :points, numericality: true
  validates :games_played, numericality: { only_integer: true }
end
```

除了 `only_integer` 之外，這個方法也接受下列選項，用來限制允許的數值：

* `:greater_than` - 屬性的值必須大於指定的值。預設錯誤訊息是 _"must be greater than %{count}"_。
* `:greater_than_or_equal_to` - 屬性的值必須大於指定的值。預設錯誤訊息是 _"must be greater than or equal to %{count}"_。
* `:equal_to` - 屬性的值必須等於指定的值。預設錯誤訊息是 _"must be equal to %{count}"_。
* `:less_than` - 屬性的值必須小於指定的值。預設錯誤訊息是 _"must be less than %{count}"_。
* `:less_than_or_equal_to` - 屬性的值必須小於等於指定的值。預設錯誤訊息是 _"must be less than or equal to %{count}"_。
* `:odd` - 若 `:odd` 設為 `true`，則屬性的值必須是奇數。預設錯誤訊息是 _"must be odd"_。
* `:even` - 若 `:even` 設為 `true`，則屬性的值必須是奇數。預設錯誤訊息是 _"must be even"_。

`numericality` 預設錯誤訊息是 _"is not a number"_。

### `presence`

這個方法驗證指定的屬性是否“存在”。使用 `blank?` 來檢查數值是否為 `nil` 或空字串（僅有空白的字串也是空字串）。

```ruby
class Person < ActiveRecord::Base
  validates :name, :login, :email, presence: true
end
```

想確保關聯物件是否存在，需要檢查關聯物件本身，而不是檢查對應的外鍵。

```ruby
class LineItem < ActiveRecord::Base
  belongs_to :order
  validates :order, presence: true
end
```

而在 `Order` 這一邊，要用 `inverse_of` 來檢查關聯的物件是否存在。

```ruby
class Order < ActiveRecord::Base
  has_many :line_items, inverse_of: :order
end
```

如透過 `has_one` 或 `has_many` 關係來驗證關聯的物件是否存在，則會對該物件呼叫 `blank?` 與 `marked_for_destruction?`，來確定存在性。

由於 `false.blank?` 為 `true`，如果想驗證布林欄位的存在性，應該要使用 `validates :field_name, inclusion: { in: [true, false] }`。

預設錯誤訊息是 _"can't be blank"_。

### `absence`

這個方法驗證是否“不存在”。使用 `present?` 來檢查數值是否為非 `nil` 或非空字串（僅有空白的字串也是空字串）。


```ruby
class Person < ActiveRecord::Base
  validates :name, :login, :email, absence: true
end
```

想確保關聯物件是否“不存在”，需要檢查關聯物件本身，而不是檢查對應的外鍵。

```ruby
class LineItem < ActiveRecord::Base
  belongs_to :order
  validates :order, absence: true
end
```

而在 `Order` 這一邊，要用 `inverse_of` 來檢查關聯的物件是否不存在。

```ruby
class Order < ActiveRecord::Base
  has_many :line_items, inverse_of: :order
end
```

If you validate the absence of an object associated via a `has_one` or
`has_many` relationship, it will check that the object is neither `present?` nor
`marked_for_destruction?`.

如透過 `has_one` 或 `has_many` 關係來驗證關聯的物件是否存在，則會對該物件呼叫 `present?` 與 `marked_for_destruction?`，來確定不存在性。

由於 `false.present?` 為 `false`，如果想驗證布林欄位的存在性，應該要使用 `validates :field_name, exclusion: { in: [true, false] }`。

預設錯誤訊息是 _"must be blank"_。

### `uniqueness`

這個方法在物件儲存前，驗證屬性值是否是唯一的。此方法只是在應用層面檢查，不對資料庫做約束。同時有兩個資料庫連接，便有可能建立出兩個相同的紀錄。要避免則是需要在資料庫加上 unique 索引，請參考 [MySQL 手冊](http://dev.mysql.com/doc/refman/5.6/en/multiple-column-indexes.html)來了解多欄索引該怎麼做。

```ruby
class Account < ActiveRecord::Base
  validates :email, uniqueness: true
end
```

這個驗證透過對 Model 的資料表執行一條 SQL 查詢語句，搜尋是否已經有同樣數值的紀錄存在。

`:scope` 選項可以用另一個屬性來限制唯一性：

```ruby
class Holiday < ActiveRecord::Base
  validates :name, uniqueness: { scope: :year,
    message: "should happen once per year" }
end
```

另有 `:case_sensitive` 選項可以用來定義是否要分大小寫。此選項預設開啟。

```ruby
class Person < ActiveRecord::Base
  validates :name, uniqueness: { case_sensitive: false }
end
```

WARNING: 注意某些資料庫預設搜尋是不分大小寫的。

預設錯誤訊息是 _"has already been taken"_.

### `validates_with`

This helper passes the record to a separate class for validation.

```ruby
class GoodnessValidator < ActiveModel::Validator
  def validate(record)
    if record.first_name == "Evil"
      record.errors[:base] << "This person is evil"
    end
  end
end

class Person < ActiveRecord::Base
  validates_with GoodnessValidator
end
```

NOTE: Errors added to `record.errors[:base]` relate to the state of the record
as a whole, and not to a specific attribute.

The `validates_with` helper takes a class, or a list of classes to use for
validation. There is no default error message for `validates_with`. You must
manually add errors to the record's errors collection in the validator class.

To implement the validate method, you must have a `record` parameter defined,
which is the record to be validated.

Like all other validations, `validates_with` takes the `:if`, `:unless` and
`:on` options. If you pass any other options, it will send those options to the
validator class as `options`:

```ruby
class GoodnessValidator < ActiveModel::Validator
  def validate(record)
    if options[:fields].any?{|field| record.send(field) == "Evil" }
      record.errors[:base] << "This person is evil"
    end
  end
end

class Person < ActiveRecord::Base
  validates_with GoodnessValidator, fields: [:first_name, :last_name]
end
```

Note that the validator will be initialized *only once* for the whole application
life cycle, and not on each validation run, so be careful about using instance
variables inside it.

If your validator is complex enough that you want instance variables, you can
easily use a plain old Ruby object instead:

```ruby
class Person < ActiveRecord::Base
  validate do |person|
    GoodnessValidator.new(person).validate
  end
end

class GoodnessValidator
  def initialize(person)
    @person = person
  end

  def validate
    if some_complex_condition_involving_ivars_and_private_methods?
      @person.errors[:base] << "This person is evil"
    end
  end

  # ...
end
```

### `validates_each`

This helper validates attributes against a block. It doesn't have a predefined
validation function. You should create one using a block, and every attribute
passed to `validates_each` will be tested against it. In the following example,
we don't want names and surnames to begin with lower case.

```ruby
class Person < ActiveRecord::Base
  validates_each :name, :surname do |record, attr, value|
    record.errors.add(attr, 'must start with upper case') if value =~ /\A[a-z]/
  end
end
```

The block receives the record, the attribute's name and the attribute's value.
You can do anything you like to check for valid data within the block. If your
validation fails, you should add an error message to the model, therefore
making it invalid.

常見驗證選項
-------------------------

These are common validation options:

### `:allow_nil`

The `:allow_nil` option skips the validation when the value being validated is
`nil`.

```ruby
class Coffee < ActiveRecord::Base
  validates :size, inclusion: { in: %w(small medium large),
    message: "%{value} is not a valid size" }, allow_nil: true
end
```

### `:allow_blank`

The `:allow_blank` option is similar to the `:allow_nil` option. This option
will let validation pass if the attribute's value is `blank?`, like `nil` or an
empty string for example.

```ruby
class Topic < ActiveRecord::Base
  validates :title, length: { is: 5 }, allow_blank: true
end

Topic.create(title: "").valid?  # => true
Topic.create(title: nil).valid? # => true
```

### `:message`

As you've already seen, the `:message` option lets you specify the message that
will be added to the `errors` collection when validation fails. When this
option is not used, Active Record will use the respective default error message
for each validation helper.

### `:on`

The `:on` option lets you specify when the validation should happen. The
default behavior for all the built-in validation helpers is to be run on save
(both when you're creating a new record and when you're updating it). If you
want to change it, you can use `on: :create` to run the validation only when a
new record is created or `on: :update` to run the validation only when a record
is updated.

```ruby
class Person < ActiveRecord::Base
  # it will be possible to update email with a duplicated value
  validates :email, uniqueness: true, on: :create

  # it will be possible to create the record with a non-numerical age
  validates :age, numericality: true, on: :update

  # the default (validates on both create and update)
  validates :name, presence: true
end
```

嚴格驗證
------------------

You can also specify validations to be strict and raise
`ActiveModel::StrictValidationFailed` when the object is invalid.

```ruby
class Person < ActiveRecord::Base
  validates :name, presence: { strict: true }
end

Person.new.valid?  # => ActiveModel::StrictValidationFailed: Name can't be blank
```

There is also an ability to pass custom exception to `:strict` option.

```ruby
class Person < ActiveRecord::Base
  validates :token, presence: true, uniqueness: true, strict: TokenGenerationException
end

Person.new.valid?  # => TokenGenerationException: Token can't be blank
```

條件式驗證
----------------------

Sometimes it will make sense to validate an object only when a given predicate
is satisfied. You can do that by using the `:if` and `:unless` options, which
can take a symbol, a string, a `Proc` or an `Array`. You may use the `:if`
option when you want to specify when the validation **should** happen. If you
want to specify when the validation **should not** happen, then you may use the
`:unless` option.

### Using a Symbol with `:if` and `:unless`

You can associate the `:if` and `:unless` options with a symbol corresponding
to the name of a method that will get called right before validation happens.
This is the most commonly used option.

```ruby
class Order < ActiveRecord::Base
  validates :card_number, presence: true, if: :paid_with_card?

  def paid_with_card?
    payment_type == "card"
  end
end
```

### Using a String with `:if` and `:unless`

You can also use a string that will be evaluated using `eval` and needs to
contain valid Ruby code. You should use this option only when the string
represents a really short condition.

```ruby
class Person < ActiveRecord::Base
  validates :surname, presence: true, if: "name.nil?"
end
```

### Using a Proc with `:if` and `:unless`

Finally, it's possible to associate `:if` and `:unless` with a `Proc` object
which will be called. Using a `Proc` object gives you the ability to write an
inline condition instead of a separate method. This option is best suited for
one-liners.

```ruby
class Account < ActiveRecord::Base
  validates :password, confirmation: true,
    unless: Proc.new { |a| a.password.blank? }
end
```

### Grouping Conditional validations

Sometimes it is useful to have multiple validations use one condition, it can
be easily achieved using `with_options`.

```ruby
class User < ActiveRecord::Base
  with_options if: :is_admin? do |admin|
    admin.validates :password, length: { minimum: 10 }
    admin.validates :email, presence: true
  end
end
```

All validations inside of `with_options` block will have automatically passed
the condition `if: :is_admin?`

### Combining Validation Conditions

On the other hand, when multiple conditions define whether or not a validation
should happen, an `Array` can be used. Moreover, you can apply both `:if` and
`:unless` to the same validation.

```ruby
class Computer < ActiveRecord::Base
  validates :mouse, presence: true,
                    if: ["market.retail?", :desktop?]
                    unless: Proc.new { |c| c.trackpad.present? }
end
```

The validation only runs when all the `:if` conditions and none of the
`:unless` conditions are evaluated to `true`.

Performing Custom Validations
-----------------------------

When the built-in validation helpers are not enough for your needs, you can
write your own validators or validation methods as you prefer.

### Custom Validators

Custom validators are classes that extend `ActiveModel::Validator`. These
classes must implement a `validate` method which takes a record as an argument
and performs the validation on it. The custom validator is called using the
`validates_with` method.

```ruby
class MyValidator < ActiveModel::Validator
  def validate(record)
    unless record.name.starts_with? 'X'
      record.errors[:name] << 'Need a name starting with X please!'
    end
  end
end

class Person
  include ActiveModel::Validations
  validates_with MyValidator
end
```

The easiest way to add custom validators for validating individual attributes
is with the convenient `ActiveModel::EachValidator`. In this case, the custom
validator class must implement a `validate_each` method which takes three
arguments: record, attribute and value which correspond to the instance, the
attribute to be validated and the value of the attribute in the passed
instance.

```ruby
class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless value =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
      record.errors[attribute] << (options[:message] || "is not an email")
    end
  end
end

class Person < ActiveRecord::Base
  validates :email, presence: true, email: true
end
```

As shown in the example, you can also combine standard validations with your
own custom validators.

### Custom Methods

You can also create methods that verify the state of your models and add
messages to the `errors` collection when they are invalid. You must then
register these methods by using the `validate` class method, passing in the
symbols for the validation methods' names.

You can pass more than one symbol for each class method and the respective
validations will be run in the same order as they were registered.

```ruby
class Invoice < ActiveRecord::Base
  validate :expiration_date_cannot_be_in_the_past,
    :discount_cannot_be_greater_than_total_value

  def expiration_date_cannot_be_in_the_past
    if expiration_date.present? && expiration_date < Date.today
      errors.add(:expiration_date, "can't be in the past")
    end
  end

  def discount_cannot_be_greater_than_total_value
    if discount > total_value
      errors.add(:discount, "can't be greater than total value")
    end
  end
end
```

By default such validations will run every time you call `valid?`. It is also
possible to control when to run these custom validations by giving an `:on`
option to the `validate` method, with either: `:create` or `:update`.

```ruby
class Invoice < ActiveRecord::Base
  validate :active_customer, on: :create

  def active_customer
    errors.add(:customer_id, "is not active") unless customer.active?
  end
end
```

Working with Validation Errors
------------------------------

In addition to the `valid?` and `invalid?` methods covered earlier, Rails provides a number of methods for working with the `errors` collection and inquiring about the validity of objects.

The following is a list of the most commonly used methods. Please refer to the `ActiveModel::Errors` documentation for a list of all the available methods.

### `errors`

Returns an instance of the class `ActiveModel::Errors` containing all errors. Each key is the attribute name and the value is an array of strings with all errors.

```ruby
class Person < ActiveRecord::Base
  validates :name, presence: true, length: { minimum: 3 }
end

person = Person.new
person.valid? # => false
person.errors.messages
 # => {:name=>["can't be blank", "is too short (minimum is 3 characters)"]}

person = Person.new(name: "John Doe")
person.valid? # => true
person.errors.messages # => {}
```

### `errors[]`

`errors[]` is used when you want to check the error messages for a specific attribute. It returns an array of strings with all error messages for the given attribute, each string with one error message. If there are no errors related to the attribute, it returns an empty array.

```ruby
class Person < ActiveRecord::Base
  validates :name, presence: true, length: { minimum: 3 }
end

person = Person.new(name: "John Doe")
person.valid? # => true
person.errors[:name] # => []

person = Person.new(name: "JD")
person.valid? # => false
person.errors[:name] # => ["is too short (minimum is 3 characters)"]

person = Person.new
person.valid? # => false
person.errors[:name]
 # => ["can't be blank", "is too short (minimum is 3 characters)"]
```

### `errors.add`

The `add` method lets you manually add messages that are related to particular attributes. You can use the `errors.full_messages` or `errors.to_a` methods to view the messages in the form they might be displayed to a user. Those particular messages get the attribute name prepended (and capitalized). `add` receives the name of the attribute you want to add the message to, and the message itself.

```ruby
class Person < ActiveRecord::Base
  def a_method_used_for_validation_purposes
    errors.add(:name, "cannot contain the characters !@#%*()_-+=")
  end
end

person = Person.create(name: "!@#")

person.errors[:name]
 # => ["cannot contain the characters !@#%*()_-+="]

person.errors.full_messages
 # => ["Name cannot contain the characters !@#%*()_-+="]
```

Another way to do this is using `[]=` setter

```ruby
  class Person < ActiveRecord::Base
    def a_method_used_for_validation_purposes
      errors[:name] = "cannot contain the characters !@#%*()_-+="
    end
  end

  person = Person.create(name: "!@#")

  person.errors[:name]
   # => ["cannot contain the characters !@#%*()_-+="]

  person.errors.to_a
   # => ["Name cannot contain the characters !@#%*()_-+="]
```

### `errors[:base]`

You can add error messages that are related to the object's state as a whole, instead of being related to a specific attribute. You can use this method when you want to say that the object is invalid, no matter the values of its attributes. Since `errors[:base]` is an array, you can simply add a string to it and it will be used as an error message.

```ruby
class Person < ActiveRecord::Base
  def a_method_used_for_validation_purposes
    errors[:base] << "This person is invalid because ..."
  end
end
```

### `errors.clear`

The `clear` method is used when you intentionally want to clear all the messages in the `errors` collection. Of course, calling `errors.clear` upon an invalid object won't actually make it valid: the `errors` collection will now be empty, but the next time you call `valid?` or any method that tries to save this object to the database, the validations will run again. If any of the validations fail, the `errors` collection will be filled again.

```ruby
class Person < ActiveRecord::Base
  validates :name, presence: true, length: { minimum: 3 }
end

person = Person.new
person.valid? # => false
person.errors[:name]
 # => ["can't be blank", "is too short (minimum is 3 characters)"]

person.errors.clear
person.errors.empty? # => true

p.save # => false

p.errors[:name]
# => ["can't be blank", "is too short (minimum is 3 characters)"]
```

### `errors.size`

The `size` method returns the total number of error messages for the object.

```ruby
class Person < ActiveRecord::Base
  validates :name, presence: true, length: { minimum: 3 }
end

person = Person.new
person.valid? # => false
person.errors.size # => 2

person = Person.new(name: "Andrea", email: "andrea@example.com")
person.valid? # => true
person.errors.size # => 0
```

Displaying Validation Errors in Views
-------------------------------------

Once you've created a model and added validations, if that model is created via
a web form, you probably want to display an error message when one of the
validations fail.

Because every application handles this kind of thing differently, Rails does
not include any view helpers to help you generate these messages directly.
However, due to the rich number of methods Rails gives you to interact with
validations in general, it's fairly easy to build your own. In addition, when
generating a scaffold, Rails will put some ERB into the `_form.html.erb` that
it generates that displays the full list of errors on that model.

Assuming we have a model that's been saved in an instance variable named
`@post`, it looks like this:

```ruby
<% if @post.errors.any? %>
  <div id="error_explanation">
    <h2><%= pluralize(@post.errors.count, "error") %> prohibited this post from being saved:</h2>

    <ul>
    <% @post.errors.full_messages.each do |msg| %>
      <li><%= msg %></li>
    <% end %>
    </ul>
  </div>
<% end %>
```

Furthermore, if you use the Rails form helpers to generate your forms, when
a validation error occurs on a field, it will generate an extra `<div>` around
the entry.

```
<div class="field_with_errors">
 <input id="post_title" name="post[title]" size="30" type="text" value="">
</div>
```

可以給這個 div 加上任何樣式。Rails 產生的 Scaffold，預設的 CSS 樣式為：

```
.field_with_errors {
  padding: 2px;
  background-color: red;
  display: table;
}
```

這表示任何有錯誤的欄位會有 2px 的紅框。
