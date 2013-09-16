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

# 3. 撰寫 Migration

## 3.1 產生 Table

`create_table`，通常用 `rails generate model` 或是 `rails generate scaffold` 的時候會自動產生 Migration，裡面就帶有 `create_table`，比如 `rails g model product name:string`：

```ruby
create_table :products do |t|
  t.string :name
end
```

`create_table` 預設會產生主鍵（`id`），可以給主鍵換名字。用 `:primary_key`，或者是不要主鍵，可以傳入 `id: false`。要傳入資料庫相關的選項，可以用 `:options`

```ruby
create_table :products, options: "ENGINE=BLACKHOLE" do |t|
  t.string :name, null: false
end
```

會在產生出來的 SQL 語句，加上 `ENGINE=BLACKHOLE`。

更多可查閱 [create_table](http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-create_table) API。


### 3.2 產生 Join Table

`create_join_table` 會產生 HABTM (HasAndBelongsToMany) join table。常見的應用場景：

```ruby
create_join_table :products, :categories
```

會產生一個 `categories_products` 表，有著 `category_id` 與 `product_id` 欄位。這些欄位的預設選項是 `null: false`，可以在 `:column_options` 裡改為 `true`：

```ruby
create_join_table :products, :categories, column_options: {null: true}
```

可以更改 join table 的名字，使用 `table_name:` 選項：

```ruby
create_join_table :products, :categories, table_name: :categorization
```

便會產生出 `categorization` 表，一樣有 `category_id` 與 `product_id`。

`create_join_table` 也接受區塊，可以用來加索引、或是新增更多欄位：

```ruby
create_join_table :products, :categories do |t|
  t.index :product_id
  t.index :category_id
end
```

### 3.3 變更 Table

`change_table` 用來變更已存在的 table。

```ruby
change_table :products do |t|
  t.remove :description, :name
  t.string :part_number
  t.index :part_number
  t.rename :upccode, :upc_code
end
```

會移除 `description` 與 `name` 欄位。新增 `part_number` （字串）欄位，並打上索引。並將 `upccode` 欄位重新命名為 `upc_code`。

### 3.4 When Helpers aren't Enough

Active Record 提供的 Helper 無法完成你想做的事情時，可以使用 `execute` 方法來執行任何 SQL 語句：

```ruby
Products.connection.execute('UPDATE `products` SET `price`=`free` WHERE 1')
```

每個方法的更多細節與範例，請查閱 API 文件，特別是：

[`ActiveRecord::ConnectionAdapters::SchemaStatements`](http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html)
(which provides the methods available in the `change`, `up` and `down` methods)

[`ActiveRecord::ConnectionAdapters::TableDefinition`](http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/TableDefinition.html)
(which provides the methods available on the object yielded by `create_table`)

[`ActiveRecord::ConnectionAdapters::Table`](http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/Table.html)
(which provides the methods available on the object yielded by `change_table`).

### 3.5 使用 `change` 方法

撰寫 migration 主要用 `change`，大多數情況 Active Record 知道如何執行逆操作。下面是 Active Record 可以自動產生逆操作的方法：

* `add_column`
* `add_index`
* `add_reference`
* `add_timestamps`
* `create_table`
* `create_join_table`
* `drop_table` (must supply a block)
* `drop_join_table` (must supply a block)
* `remove_timestamps`
* `rename_column`
* `rename_index`
* `remove_reference`
* `rename_table`

`change_table` 也是可逆的，只要傳給 `change_table` 的區塊沒有呼叫 `change`、`change_default` 或是 `remove` 即可。

如果你想有更多的靈活性，可以使用 `reversible` 或是撰寫 `up`、`down` 方法。

### 3.6 使用 `reversible`

複雜的 migration Active Record 可能不知道怎麼變回來。這時候可以使用 `reversible`：

```ruby
class ExampleMigration < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.references :category
    end

    reversible do |dir|
      dir.up do
        #add a foreign key
        execute <<-SQL
          ALTER TABLE products
            ADD CONSTRAINT fk_products_categories
            FOREIGN KEY (category_id)
            REFERENCES categories(id)
        SQL
      end
      dir.down do
        execute <<-SQL
          ALTER TABLE products
            DROP FOREIGN KEY fk_products_categories
        SQL
      end
    end

    add_column :users, :home_page_url, :string
    rename_column :users, :email, :email_address
  end
```

使用 `reversible` 會確保執行順序的正確性。若你做了不可逆的操作，比如刪除資料。Active Record 會在執行 `down` 區塊時，raise 一個 `ActiveRecord::IrreversibleMigration`。


### 3.7 使用 `up`、`down` 方法

可以不用 `change` 撰寫 migration，使用經典的寫法 `up`、`down` 寫法。

`up` 撰寫 migrate、`down` 撰寫 rollback。兩個操作要可以互相抵消。舉例來說，`up` 建了一個 table，`down` 就要 drop 那個 table。

上面使用 `reversible` 可以用 `up`＋`down` 改寫：

```ruby
class ExampleMigration < ActiveRecord::Migration
  def up
    create_table :products do |t|
      t.references :category
    end

    # add a foreign key
    execute <<-SQL
      ALTER TABLE products
        ADD CONSTRAINT fk_products_categories
        FOREIGN KEY (category_id)
        REFERENCES categories(id)
    SQL

    add_column :users, :home_page_url, :string
    rename_column :users, :email, :email_address
  end

  def down
    rename_column :users, :email_address, :email
    remove_column :users, :home_page_url

    execute <<-SQL
      ALTER TABLE products
        DROP FOREIGN KEY fk_products_categories
    SQL

    drop_table :products
  end
end
```

如果 migration 是不可逆的操作，要在 `down` raise 一個 `ActiveRecord::IrreversibleMigration`。

### 3.8 取消之前的 Migration

用 `revert` 來取消先前的 migration：

```ruby
require_relative '2012121212_example_migration'

class FixupExampleMigration < ActiveRecord::Migration
  def change
    revert ExampleMigration

    create_table(:apples) do |t|
      t.string :variety
    end
  end
end
```

`revert` 方法也接受區塊，可以只取消部份的 migration。看看這個例子（取消 `ExampleMigration`）：

```ruby
class SerializeProductListMigration < ActiveRecord::Migration
  def change
    add_column :categories, :product_list

    reversible do |dir|
      dir.up do
        # transfer data from Products to Category#product_list
      end
      dir.down do
        # create Products from Category#product_list
      end
    end

    revert do
      # copy-pasted code from ExampleMigration
      create_table :products do |t|
        t.references :category
      end

      reversible do |dir|
        dir.up do
          #add a foreign key
          execute <<-SQL
            ALTER TABLE products
              ADD CONSTRAINT fk_products_categories
              FOREIGN KEY (category_id)
              REFERENCES categories(id)
          SQL
        end
        dir.down do
          execute <<-SQL
            ALTER TABLE products
              DROP FOREIGN KEY fk_products_categories
          SQL
        end
      end

      # The rest of the migration was ok
    end
  end
end
```

上面這個 migration 也可以不用 `revert` 寫成。

把 `create_table` 與 `reversible` 順序對換，`create_table` 換成 `drop_table`，最後對換 `up` `down`。

這其實就是 `revert` 做的事。

# 4. Running Migrations

Rails 提供了許多 Rake 任務用來執行 migration。

有點要注意的是，執行 `db:migrate` 也會執行 `db:schema:dump`，會幫你更新 `db/schema.rb` 來反映出當下的資料庫結構。

如果指定了 target 版本，Active Record 會執行版本之前所有的 migration。target 名稱是 migration 前面的 UTC 時間戳章（包含 20080906120000）：

```bash
$ rake db:migrate VERSION=20080906120000
```

```bash
rake db:rollback VERSION=20080906120000
```

會從最新的版本，執行 `down` 方法到 `20080906120000` 但不包含（`20080906120000`）

## 4.1 Rolling Back

A common task is to rollback the last migration. For example, if you made a
mistake in it and wish to correct it. Rather than tracking down the version
number associated with the previous migration you can run

```bash
$ rake db:rollback
```

This will rollback the latest migration, either by reverting the `change`
method or by running the `down` method. If you need to undo
several migrations you can provide a `STEP` parameter:

```bash
$ rake db:rollback STEP=3
```

will revert the last 3 migrations.

The `db:migrate:redo` task is a shortcut for doing a rollback and then migrating
back up again. As with the `db:rollback` task, you can use the `STEP` parameter
if you need to go more than one version back, for example

```bash
$ rake db:migrate:redo STEP=3
```

Neither of these Rake tasks do anything you could not do with `db:migrate`. They
are simply more convenient, since you do not need to explicitly specify the
version to migrate to.

## 4.2 Setup the Database

The `rake db:setup` task will create the database, load the schema and initialize
it with the seed data.

## 4.3 Resetting the Database

The `rake db:reset` task will drop the database and set it up again. This is
functionally equivalent to `rake db:drop db:setup`.

NOTE: This is not the same as running all the migrations. It will only use the
contents of the current schema.rb file. If a migration can't be rolled back,
'rake db:reset' may not help you. To find out more about dumping the schema see
'[schema dumping and you](#schema-dumping-and-you).'

## 4.4 Running Specific Migrations

If you need to run a specific migration up or down, the `db:migrate:up` and
`db:migrate:down` tasks will do that. Just specify the appropriate version and
the corresponding migration will have its `change`, `up` or `down` method
invoked, for example,

```bash
$ rake db:migrate:up VERSION=20080906120000
```

will run the 20080906120000 migration by running the `change` method (or the
`up` method). This task will
first check whether the migration is already performed and will do nothing if
Active Record believes that it has already been run.

## 4.5 Running Migrations in Different Environments

By default running `rake db:migrate` will run in the `development` environment.
To run migrations against another environment you can specify it using the
`RAILS_ENV` environment variable while running the command. For example to run
migrations against the `test` environment you could run:

```bash
$ rake db:migrate RAILS_ENV=test
```

## 4.6 Changing the Output of Running Migrations

By default migrations tell you exactly what they're doing and how long it took.
A migration creating a table and adding an index might produce output like this

```bash
==  CreateProducts: migrating =================================================
-- create_table(:products)
   -> 0.0028s
==  CreateProducts: migrated (0.0028s) ========================================
```

Several methods are provided in migrations that allow you to control all this:

| Method               | Purpose
| -------------------- | -------
| suppress_messages    | Takes a block as an argument and suppresses any output generated by the block.
| say                  | Takes a message argument and outputs it as is. A second boolean argument can be passed to specify whether to indent or not.
| say_with_time        | Outputs text along with how long it took to run its block. If the block returns an integer it assumes it is the number of rows affected.

For example, this migration

```ruby
class CreateProducts < ActiveRecord::Migration
  def change
    suppress_messages do
      create_table :products do |t|
        t.string :name
        t.text :description
        t.timestamps
      end
    end

    say "Created a table"

    suppress_messages {add_index :products, :name}
    say "and an index!", true

    say_with_time 'Waiting for a while' do
      sleep 10
      250
    end
  end
end
```

generates the following output

```bash
==  CreateProducts: migrating =================================================
-- Created a table
   -> and an index!
-- Waiting for a while
   -> 10.0013s
   -> 250 rows
==  CreateProducts: migrated (10.0054s) =======================================
```

If you want Active Record to not output anything, then running `rake db:migrate
VERBOSE=false` will suppress all output.

# 5. 修改現有的 Migrations

有時候 migration 可能會寫錯。修正過來之後，要先執行 `rake db:rollback`，再執行 `rake db:migrate`。

編輯現有的 migration 不太好，因為會增加一起開發的人更多工作量。尤其是 migration 已經上 production，應該要寫個新的 migration，來達成你想完成的事情。

`revert` 方法用來寫新的 migration 取消先前的 migration 很有用。

# 6. 在 Migration 裡使用 Model

在 migration 新增或更新資料的時候，常常會需要用到 model，讓你可以取出現有的資料。但有些事情要注意：

舉例來說，

一、用了尚未存在的資料庫欄位

二、

For example, problems occur when the model uses database columns which are (1)
not currently in the database and (2) will be created by this or a subsequent
migration.

Consider this example, where Alice and Bob are working on the same code base
which contains a `Product` model:

Bob 去度假了。

Alice 給 `products` table 新增了一個 migration，加了新欄位，並初始化這個欄位。

```ruby
# db/migrate/20100513121110_add_flag_to_product.rb

class AddFlagToProduct < ActiveRecord::Migration
  def change
    add_column :products, :flag, :boolean
    reversible do |dir|
      dir.up { Product.update_all flag: false }
    end
  end
end
```

也給新欄位加了驗證措施：

```ruby
# app/models/product.rb

class Product < ActiveRecord::Base
  validates :flag, inclusion: { in: [true, false] }
end
```

Alice 加入第二個驗證，並加入另一個欄位到 `products` table，並初始化：

```ruby
# db/migrate/20100515121110_add_fuzz_to_product.rb

class AddFuzzToProduct < ActiveRecord::Migration
  def change
    add_column :products, :fuzz, :string
    reversible do |dir|
      dir.up { Product.update_all fuzz: 'fuzzy' }
    end
  end
end
```

She also adds a validation to the `Product` model for the new column:

```ruby
# app/models/product.rb

class Product < ActiveRecord::Base
  validates :flag, inclusion: { in: [true, false] }
  validates :fuzz, presence: true
end
```

Both migrations work for Alice.

Bob comes back from vacation and:

*   Updates the source - which contains both migrations and the latest version
    of the Product model.
*   Runs outstanding migrations with `rake db:migrate`, which
    includes the one that updates the `Product` model.

The migration crashes because when the model attempts to save, it tries to
validate the second added column, which is not in the database when the _first_
migration runs:

```
rake aborted!
An error has occurred, this and all later migrations canceled:

undefined method `fuzz' for #<Product:0x000001049b14a0>
```

A fix for this is to create a local model within the migration. This keeps
Rails from running the validations, so that the migrations run to completion.

When using a local model, it's a good idea to call
`Product.reset_column_information` to refresh the Active Record cache for the
`Product` model prior to updating data in the database.

If Alice had done this instead, there would have been no problem:

```ruby
# db/migrate/20100513121110_add_flag_to_product.rb

class AddFlagToProduct < ActiveRecord::Migration
  class Product < ActiveRecord::Base
  end

  def change
    add_column :products, :flag, :boolean
    Product.reset_column_information
    reversible do |dir|
      dir.up { Product.update_all flag: false }
    end
  end
end
```

```ruby
# db/migrate/20100515121110_add_fuzz_to_product.rb

class AddFuzzToProduct < ActiveRecord::Migration
  class Product < ActiveRecord::Base
  end

  def change
    add_column :products, :fuzz, :string
    Product.reset_column_information
    reversible do |dir|
      dir.up { Product.update_all fuzz: 'fuzzy' }
    end
  end
end
```

There are other ways in which the above example could have gone badly.

For example, imagine that Alice creates a migration that selectively
updates the `description` field on certain products. She runs the
migration, commits the code, and then begins working on the next feature,
which is to add a new column `fuzz` to the products table.

She creates two migrations for this new feature, one which adds the new
column, and a second which selectively updates the `fuzz` column based on
other product attributes.

These migrations run just fine, but when Bob comes back from his vacation
and calls `rake db:migrate` to run all the outstanding migrations, he gets a
subtle bug: The descriptions have defaults, and the `fuzz` column is present,
but `fuzz` is `nil` on all products.

The solution is again to use `Product.reset_column_information` before
referencing the Product model in a migration, ensuring the Active Record's
knowledge of the table structure is current before manipulating data in those
records.

# 7. Schema Dumping and You

## 7.1 Schema 有什麼用

Migrations, mighty as they may be, are not the authoritative source for your
database schema. That role falls to either `db/schema.rb` or an SQL file which
Active Record generates by examining the database. They are not designed to be
edited, they just represent the current state of the database.

There is no need (and it is error prone) to deploy a new instance of an app by
replaying the entire migration history. It is much simpler and faster to just
load into the database a description of the current schema.

For example, this is how the test database is created: the current development
database is dumped (either to `db/schema.rb` or `db/structure.sql`) and then
loaded into the test database.

Schema files are also useful if you want a quick look at what attributes an
Active Record object has. This information is not in the model's code and is
frequently spread across several migrations, but the information is nicely
summed up in the schema file. The
[annotate_models](https://github.com/ctran/annotate_models) gem automatically
adds and updates comments at the top of each model summarizing the schema if
you desire that functionality.

## 7.2 Schema Dump 的種類

There are two ways to dump the schema. This is set in `config/application.rb`
by the `config.active_record.schema_format` setting, which may be either `:sql`
or `:ruby`.

If `:ruby` is selected then the schema is stored in `db/schema.rb`. If you look
at this file you'll find that it looks an awful lot like one very big
migration:

```ruby
ActiveRecord::Schema.define(version: 20080906171750) do
  create_table "authors", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "products", force: true do |t|
    t.string   "name"
    t.text "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "part_number"
  end
end
```

In many ways this is exactly what it is. This file is created by inspecting the
database and expressing its structure using `create_table`, `add_index`, and so
on. Because this is database-independent, it could be loaded into any database
that Active Record supports. This could be very useful if you were to
distribute an application that is able to run against multiple databases.

There is however a trade-off: `db/schema.rb` cannot express database specific
items such as foreign key constraints, triggers, or stored procedures. While in
a migration you can execute custom SQL statements, the schema dumper cannot
reconstitute those statements from the database. If you are using features like
this, then you should set the schema format to `:sql`.

Instead of using Active Record's schema dumper, the database's structure will
be dumped using a tool specific to the database (via the `db:structure:dump`
Rake task) into `db/structure.sql`. For example, for PostgreSQL, the `pg_dump`
utility is used. For MySQL, this file will contain the output of `SHOW CREATE
TABLE` for the various tables.

Loading these schemas is simply a question of executing the SQL statements they
contain. By definition, this will create a perfect copy of the database's
structure. Using the `:sql` schema format will, however, prevent loading the
schema into a RDBMS other than the one used to create it.

## 7.3 Schema Dumps 與版本管理

Because schema dumps are the authoritative source for your database schema, it
is strongly recommended that you check them into source control.

# 8. Active Record 及 Referential Integrity

The Active Record way claims that intelligence belongs in your models, not in
the database. As such, features such as triggers or foreign key constraints,
which push some of that intelligence back into the database, are not heavily
used.

Validations such as `validates :foreign_key, uniqueness: true` are one way in
which models can enforce data integrity. The `:dependent` option on
associations allows models to automatically destroy child objects when the
parent is destroyed. Like anything which operates at the application level,
these cannot guarantee referential integrity and so some people augment them
with foreign key constraints in the database.

Although Active Record does not provide any tools for working directly with
such features, the `execute` method can be used to execute arbitrary SQL. You
can also use a gem like
[foreigner](https://github.com/matthuhiggins/foreigner) which adds foreign key
support to Active Record (including support for dumping foreign keys in
`db/schema.rb`).

# 9. Migrations 與 Seed Data

有些人使用 migration 來加資料到資料庫：

```ruby
class AddInitialProducts < ActiveRecord::Migration
  def up
    5.times do |i|
      Product.create(name: "Product ##{i}", description: "A product.")
    end
  end

  def down
    Product.delete_all
  end
end
```

但 Rails 有 “seeds” 這個功能，應該這麼用才對。在 `db/seeds.rb` 填入 Ruby 代碼，執行 `rake db:seed` 即可：

```ruby
5.times do |i|
  Product.create(name: "Product ##{i}", description: "A product.")
end
```

這個辦法比用 migration 來建立資料到空的資料庫好。
