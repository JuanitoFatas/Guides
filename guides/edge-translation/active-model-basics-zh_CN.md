# Active Model 基础

__特别要强调的翻译名词__

> Module 模块

> Attribute 属性

本篇教你如何开始使用 Model。 Active Model 允许 Action Pack Helpers 与不是 Active Record 的 Model 类别来做交互。Active Model 也允许你在 Rails 框架之外自己造 ORM。

## 目录

- [1. 简介](#1-简介)
  - [1.1 AttributeMethods 模块](#11-attributemethods-模块)
  - [1.2 Callbacks 模块](#12-callbacks-模块)
  - [1.3 Conversion 模块](#13-conversion-模块)
  - [1.4 Dirty 模块](#14-dirty-模块)
    - [1.4.1 查询对象的变化](#141-查询对象的变化)
    - [1.4.2 基于属性的 accessor 方法](#142-基于属性的-accessor-方法)
  - [1.5 Validations 模块](#15-validations-模块)

# 1. 简介

Active Model 是一个函式库，由许多用来与 Action Pack 互动的模块组成。以下简单介绍几个 Active Model 的模块。

## 1.1 AttributeMethods 模块

用来给方法加上前缀或后缀。

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

## 1.2 Callbacks 模块

Active Record 风格的 Callbacks。让我们可以在运行期定义 Callbacks。定义 Callback 后便有 `before_*`、`after_*` 与 `around_*` 方法可用。

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

## 1.3 Conversion 模块

如果一个类别有定义 `persisted?` 与 `id` 方法，则你可引入 `Conversion` 模块，并对此类别的对象呼叫 Rails 的 conversion 方法（`to_model`、`to_key`、`to_param`）。

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

## 1.4 Dirty 模块

对象有一个或多个改动，却未储存，则称对象变 dirty 了。这让我们可以检查对象是否有改动。以下是 `Person` 类别，有 `first_name` 与 `last_name` 这两个属性：

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

### 1.4.1 查询对象的变化

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

### 1.4.2 基于属性的 accessor 方法

检查 `first_name` 这个属性是否有改动，`first_name_changed?`：

```ruby
# attr_name_changed?
person.first_name # => "First Name"
person.first_name_changed? # => true
```

检查属性上一次的数值：

```ruby
# attr_name_was accessor
person.first_name_was # => "First Name"
```

检查属性上次与当前的值，有变化返回 Array，没变化返回 `nil`：

```ruby
# attr_name_change
person.first_name_change # => [nil, "First Name"]
person.last_name_change # => nil
```

## 1.5 Validations 模块

给类别加入 Active Record 风格的验证功能：

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
