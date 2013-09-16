# Active Record Migrations

Migration，遷移。Active Record 眾多功能之一，可以追蹤管理資料庫的 schema，而不是寫死。最棒的是 Migration 提供了簡潔的 Ruby DSL，供你管理資料庫的 table。


__學習目標__

* 產生 migration。

* 熟悉 Active Record 提供用來操作資料庫的方法。

* 撰寫 Rake task 來管理資料庫的 schema。

* 了解 Migration 與 schema.rb 的關係。


# 1. 概要

Migration 讓你...

* 增量管理資料庫 Schema。

* 不用寫 SQL。

* 修改資料庫/Schema 都有記錄，可跳到某個階段的狀態。

就跟打電動差不多，打到哪一關可以存檔，下次可從上次存檔的地方開始玩。

__資料庫的變化就是不同關卡。__

Schema 就跟你有什麼裝備一樣，每一關都不同，所以做完 Migration Schema 會有變化。

__Schema 記錄了資料庫有什麼表格，表格有什麼欄位。__

Active Record 會自動替你更新 Schema，確保你在對的關卡。

來看個範例 migration：


```ruby
class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
```

`create_table :products do |t|` 新增了一個叫做 `products` 的表格，有 `name` （類型是字串）、`description` （類型是 text）的欄位。主鍵（Primary key，`id`）會自動幫你添加（migration 裡看不到）。`timestamps` 給你每次的 migration 蓋上時間戳章，加上兩個欄位 `created_at` 及 `updated_at`。

__Active Record 自動替你加上主鍵及時間戳章。__

Migration 是前進下一關，那回到上一關叫做什麼？__Rollback，回滾。__

當我們回滾剛剛的 migration，Active Record 會自動幫你移除這個 table。有些資料庫支援 transaction （事務），改變 schema 的 migration 會包在事務裡
。不支援事務的資料庫，無法 rollback 到上一個版本，則你得自己手動 rollback。

注意：有些 query 不能在事務裡執行。如果你的資料庫支援的是 DDL 事務，可以用 `disable_ddl_transaction!` 停用它。

如果你做的事 Active Record 不知道如何 rollback，你可以自己寫，用 `reversible`：

```ruby
class ChangeProductsPrice < ActiveRecord::Migration
  def change
    reversible do |dir|
      change_table :products do |t|
        dir.up   { t.change :price, :string }
        dir.down { t.change :price, :integer }
      end
    end
  end
end
```

也可以用 `up`、`down` 來取代 `change`：

```ruby
class ChangeProductsPrice < ActiveRecord::Migration
  def up
    change_table :products do |t|
      t.change :price, :string
    end
  end

  def down
    change_table :products do |t|
      t.change :price, :integer
    end
  end
end
```

這裡的 `up` 就是 migrate；`down` 便是 rollback。

# 2. 新增 Migration

## 2.1 新增獨立的 Migration

__Migration 存在那裡？__

`db/migrate` 目錄下。

__Migration 檔名規則？__

`YYYYMMDDHHMMSS_migration_name.rb`，前面的 `YYYYMMDDHHMMSS` 是 UTC 形式的時間戳章，後面接的是該 Migration 的名稱（前例 `migration_name.rb`）。Migration 的類別是用駝峰形式（CamelCased）定義的，會對應到檔名。
舉個例子：

`20130916204300_create_products.rb` 會定義出 `CreateProducts` 這樣的類別名稱。

`20121027111111_add_details_to_products.rb` 會定義出 `AddDetailsToProducts` 這樣的類別名稱。

__Rails 根據時間戳章決定運行先後順序。__

__怎麼產生 Migration?__

```bash
$ rails generate migration AddPartNumberToProducts
```

會產生出空的 Migration：

```ruby
class AddPartNumberToProducts < ActiveRecord::Migration
  def change
  end
end
```

Migration 名稱有兩個常見的形式：`AddXXXToYYY`、`RemoveXXXFromYYY`，之後接一系列的欄位名稱＋類型。則會自動幫你產生 `add_column`：

```bash
$ rails generate migration AddPartNumberToProducts part_number:string
```

會產生

```ruby
class AddPartNumberToProducts < ActiveRecord::Migration
  def change
    add_column :products, :part_number, :string
  end
end
```

當你 rollback 的時候，Rails 會自動幫你 `remove_column`。

給欄位加上索引（index）也是很簡單的：

```bash
$ rails generate migration AddPartNumberToProducts part_number:string:index
```

會產生

```ruby
class AddPartNumberToProducts < ActiveRecord::Migration
  def change
    add_column :products, :part_number, :string
    add_index :products, :part_number
  end
end
```

同樣也可以移除某個欄位：

```bash
$ rails generate migration RemovePartNumberFromProducts part_number:string
```

會產生：

```ruby
class RemovePartNumberFromProducts < ActiveRecord::Migration
  def change
    remove_column :products, :part_number, :string
  end
end
```

一次可產生多個欄位：

```bash
$ rails generate migration AddDetailsToProducts part_number:string price:decimal
```

會產生：

```ruby
class AddDetailsToProducts < ActiveRecord::Migration
  def change
    add_column :products, :part_number, :string
    add_column :products, :price, :decimal
  end
end
```

剛剛已經講過兩個常見的 migration 命名形式：`AddXXXToYYY`、`RemoveXXXFromYYY`，還有 `CreateXXX` 這種：

```bash
$ rails generate migration CreateProducts name:string part_number:string
```

會新建 table 及欄位：

```ruby
class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :name
      t.string :part_number
    end
  end
end
```

不過 Rails 產生的 Migration 不是不能改的，可以按需更改。

欄位類型還有一種叫做 `references` （＝ `belongs_to`）：

```bash
$ rails generate migration AddUserRefToProducts user:references
```

會產生

```ruby
class AddUserRefToProducts < ActiveRecord::Migration
  def change
    add_reference :products, :user, index: true
  end
end
```

會針對 Product 表，產生一個 `user_id` 欄位並加上索引。

__產生 Join Table?__

```bash
rails g migration CreateJoinTableCustomerProduct customer product
```

會產生：

```ruby
class CreateJoinTableCustomerProduct < ActiveRecord::Migration
  def change
    create_join_table :customers, :products do |t|
      # t.index [:customer_id, :product_id]
      # t.index [:product_id, :customer_id]
    end
  end
end
```

## 2.2 Modle 產生器

看看 `rails generate model` 會產生出來的 migration 例子，比如：

```bash
$ rails generate model Product name:string description:text
```

會產生如下的 migration：

```ruby
class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
```


`rails generate model Product` 後面可接無限個欄位名及類型。

## 2.3 類型修飾符

類型後面還可加修飾符（modifiers），支持下列修飾符：

|修飾符|說明|
|:--|:--|
|`limit`      | 設定 `string/text/binary/integer` 欄位的最大值。|
|`precision`  | 定義 `decimal` 欄位的精度，含小數點可以有幾個數字。|
|`scale`      | 定義 `decimal` 欄位的位數，小數點可以有幾位。|
|`polymorphic`| 給 `belongs_to` association 加上 `type` 欄位。|

舉例來說

```bash
$ rails generate migration AddDetailsToProducts 'price:decimal{5,2}' supplier:references{polymorphic}
```

會產生如下的 Migration：

```ruby
class AddDetailsToProducts < ActiveRecord::Migration
  def change
    add_column :products, :price, precision: 5, scale: 2
    add_reference :products, :supplier, polymorphic: true, index: true
  end
end
```



