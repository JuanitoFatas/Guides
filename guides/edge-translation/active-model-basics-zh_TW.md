# Active Model 基礎

__特別要強調的翻譯名詞__

> Module 模組

> Attribute 屬性

本篇教你如何開始使用 Model。 Active Model 允許 Action Pack Helpers 與不是 Active Record 的 Model 類別來做互動。Active Model 也允許你在 Rails 框架之外自己造 ORM。

## 目錄

- [1. 簡介](#1-簡介)
  - [1.1 AttributeMethods 模組](#11-attributemethods-模組)
  - [1.2 Callbacks 模組](#12-callbacks-模組)
  - [1.3 Conversion 模組](#13-conversion-模組)
  - [1.4 Dirty 模組](#14-dirty-模組)
    - [1.4.1 查詢物件的變化](#141-查詢物件的變化)
    - [1.4.2 基於屬性的 accessor 方法](#142-基於屬性的-accessor-方法)
  - [1.5 Validations 模組](#15-validations-模組)

# 1. 簡介

Active Model 是一個函式庫，由許多用來與 Action Pack 互動的模組組成。以下簡單介紹幾個 Active Model 的模組。

## 1.1 AttributeMethods 模組

用來給方法加上前綴或後綴。

```ruby
class Person
  include ActiveModel::AttributeMethods

  attribute_method_prefix 'reset_'
  attribute_method_suffix '_highest?'
  define_attribute_methods 'age'

  attr_accessor :age

  private
    def reset_attribute(attribute)
      send("#{attribute}=", 0)
    end

    def attribute_highest?(attribute)
      send(attribute) > 100
    end
end

person = Person.new
person.age = 110
person.age_highest?  # true
person.reset_age     # 0
person.age_highest?  # false
```

## 1.2 Callbacks 模組

Active Record 風格的 Callbacks。讓我們可以在運行期定義 Callbacks。定義 Callback 後便有 `before_*`、`after_*` 與 `around_*` 方法可用。

```ruby
class Person
  extend ActiveModel::Callbacks

  define_model_callbacks :update

  before_update :reset_me

  def update
    run_callbacks(:update) do
      # This method is called when update is called on an object.
    end
  end

  def reset_me
    # This method is called when update is called on an object as a before_update callback is defined.
  end
end
```

## 1.3 Conversion 模組

如果一個類別有定義 `persisted?` 與 `id` 方法，則你可引入 `Conversion` 模組，並對此類別的物件呼叫 Rails 的 conversion 方法（`to_model`、`to_key`、`to_param`）。

```ruby
class Person
  include ActiveModel::Conversion

  def persisted?
    false
  end

  def id
    nil
  end
end

person = Person.new
person.to_model == person  # => true
person.to_key              # => nil
person.to_param            # => nil
```

## 1.4 Dirty 模組

物件有一個或多個改動，卻未儲存，則稱物件變 dirty 了。這讓我們可以檢查物件是否有變動。以下是 `Person` 類別，有 `first_name` 與 `last_name` 這兩個屬性：

```ruby
require 'active_model'

class Person
  include ActiveModel::Dirty
  define_attribute_methods :first_name, :last_name

  def first_name
    @first_name
  end

  def first_name=(value)
    first_name_will_change!
    @first_name = value
  end

  def last_name
    @last_name
  end

  def last_name=(value)
    last_name_will_change!
    @last_name = value
  end

  def save
    # do save work...
    changes_applied
  end
end
```

### 1.4.1 查詢物件的變化

```ruby
person = Person.new
person.changed? # => false

person.first_name = "First Name"
person.first_name # => "First Name"

# returns if any attribute has changed.
person.changed? # => true

# returns a list of attributes that have changed before saving.
person.changed # => ["first_name"]

# returns a hash of the attributes that have changed with their original values.
person.changed_attributes # => {"first_name"=>nil}

# returns a hash of changes, with the attribute names as the keys, and the values will be an array of the old and new value for that field.
person.changes # => {"first_name"=>[nil, "First Name"]}
```

### 1.4.2 基於屬性的 accessor 方法

檢查 `first_name` 這個屬性是否有變動，`first_name_changed?`：

```ruby
# attr_name_changed?
person.first_name # => "First Name"
person.first_name_changed? # => true
```

檢查屬性上一次的數值：

```ruby
# attr_name_was accessor
person.first_name_was # => "First Name"
```

檢查屬性上次與當前的值，有變化回傳 Array，沒變化回傳 `nil`：

```ruby
# attr_name_change
person.first_name_change # => [nil, "First Name"]
person.last_name_change # => nil
```

## 1.5 Validations 模組

給類別加入 Active Record 風格的驗證功能：

```ruby
class Person
  include ActiveModel::Validations

  attr_accessor :name, :email, :token

  validates :name, presence: true
  validates_format_of :email, with: /\A([^\s]+)((?:[-a-z0-9]\.)[a-z]{2,})\z/i
  validates! :token, presence: true
end

person = Person.new(token: "2b1f325")
person.valid?                        # => false
person.name = 'vishnu'
person.email = 'me'
person.valid?                        # => false
person.email = 'me@vishnuatrai.com'
person.valid?                        # => true
person.token = nil
person.valid?                        # => raises ActiveModel::StrictValidationFailed
```
