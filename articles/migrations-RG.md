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

`create_table :products do |t|` 新增了一個叫做 `products` 的表格，有 `name` （類型是字串）、`description` (類型是 text) 的欄位。主鍵（Primary key，`id`）會自動幫你添加（migration 裡看不到）。`timestamps` 給你每次的 migration 蓋上時間戳章，加上兩個欄位 `created_at` 及 `updated_at`。

__Active Record 自動替你加上主鍵及時間戳章。__

Migration 是前進下一關，那回到上一關叫做什麼？ &arr; __Rollback，回滾。__

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
