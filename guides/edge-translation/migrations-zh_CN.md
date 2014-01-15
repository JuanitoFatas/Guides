# Active Record Migrations

Migration，迁移。Active Record 众多功能之一，可以追踪管理数据库的 schema，而不是硬编码。最棒的是 Migration 提供了简洁的 Ruby DSL，让管理数据库的 table 更方便。

__学习目标__

* 产生 Migration。
* 熟悉 Active Record 提供用来操作数据库的方法。
* 撰写 Rake task 来管理数据库的 schema。
* 了解 Migration 与 schema.rb 的关系。

# 目录

- [1. 概要](#1-概要)
- [2. 新增 Migration](#2-新增-migration)
  - [2.1 新增独立的 Migration](#21-新增独立的-migration)
  - [2.2 Model 产生器](#22-model-产生器)
  - [2.3 类型修饰符](#23-类型修饰符)
- [3. 撰写 Migration](#3-撰写-migration)
  - [3.1 产生 Table](#31-产生-table)
    - [3.2 产生 Join Table](#32-产生-join-table)
    - [3.3 变更 Table](#33-变更-table)
    - [3.4 Helpers 不够用怎么办](#34-helpers-不够用怎么办)
    - [3.5 使用 `change` 方法](#35-使用-change-方法)
    - [3.6 使用 `reversible`](#36-使用-reversible)
    - [3.7 使用 `up`、`down` 方法](#37-使用-up、down-方法)
    - [3.8 取消之前的 Migration](#38-取消之前的-migration)
- [4. 运行 Migrations](#4-运行-migrations)
  - [4.1 回滚](#41-回滚)
  - [4.2 设定数据库](#42-设定数据库)
  - [4.3 重置数据库](#43-重置数据库)
  - [4.4 运行特定的 migration](#44-运行特定的-migration)
  - [4.5 在不同环境下运行 migration](#45-在不同环境下运行-migration)
  - [4.6 修改运行中 Migration 的输出](#46-修改运行中-migration-的输出)
- [5. 修改现有的 Migrations](#5-修改现有的-migrations)
- [6. 在 Migration 里使用 Model](#6-在-migration-里使用-model)
- [7. Schema Dumping 与你](#7-schema-dumping-与你)
  - [7.1 Schema 有什么用](#71-schema-有什么用)
  - [7.2 Schema Dump 的种类](#72-schema-dump-的种类)
  - [7.3 Schema Dumps 与版本管理](#73-schema-dumps-与版本管理)
- [8. Active Record 与 Referential Integrity](#8-active-record-与-referential-integrity)
- [9. Migrations 与 Seed Data](#9-migrations-与-seed-data)
- [延伸阅读](#延伸阅读)

# 1. 概要

Migration 让你...

* 增量管理数据库 Schema。

* 不用写 SQL。

* 修改数据库 / Schema 都有记录，可跳到数据库某个阶段的状态。

就跟打电动差不多，打到哪一关可以存档，下次可从上次存档的地方开始玩。

__数据库的变化就是不同关卡。__

Schema 就跟你有什么装备一样，每一关都不同，所以做完 Migration Schema 会有变化。

__Schema 记录了数据库有什么表格，表格有什么栏位。__

Active Record 会自动替你更新 Schema，确保你在对的关卡。

来看个示例 Migration：


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

`create_table :products do |t|` 新增了一个叫做 `products` 的表格，有 `name` （类型是字串）、`description` （类型是 `text`）的栏位。主键（Primary key，`id`）会自动帮你添加（Migration 里看不到）。`timestamps` 给你每次的 Migration 盖上时间戳章，加上两个栏位 `created_at` 及 `updated_at`。

__Active Record 自动替你加上主键及时间戳章。__

Migration 是前进下一关，那回到上一关叫做什么？ __Rollback，回滚。__

当我们回滚刚刚的 Migration，Active Record 会自动帮你移除这个 table。有些数据库支援 transaction （事务），改变 Schema 的 Migration 会包在事务里
。不支援事务的数据库，无法 Rollback 到上一个版本，则你得自己手动 Rollback。

注意：有些 Query 不能在事务里运行。如果你的数据库支援的是 DDL 事务，可以用 `disable_ddl_transaction!` 停用它。

如果 Active Record 不知道如何 Rollback，你可以自己用 `reversible` 处理：

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

也可以用 `up`、`down` 来取代 `change`：

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

这里的 `up` 就是 migrate；`down` 便是 rollback。

# 2. 新增 Migration

## 2.1 新增独立的 Migration

__Migration 存在那里？__

`db/migrate` 目录下。

__Migration 文件名规则？__

`YYYYMMDDHHMMSS_migration_name.rb`，前面的 `YYYYMMDDHHMMSS` 是 UTC 格式的时间戳章，后面接的是该 Migration 的名称（前例 `migration_name.rb`）。Migration 的类别是用驼峰形式（CamelCased）定义的，会对应到文件名。

举个例子：

`20130916204300_create_products.rb` 会定义出 `CreateProducts` 这样的类别名称。

`20121027111111_add_details_to_products.rb` 会定义出 `AddDetailsToProducts` 这样的类别名称。

__Rails 根据时间戳章决定运行先后顺序。__

__怎么产生 Migration?__

```bash
$ rails generate migration AddPartNumberToProducts
```

会产生出空的 Migration：

```ruby
class AddPartNumberToProducts < ActiveRecord::Migration
  def change
  end
end
```

Migration 名称有两个常见的形式：`AddXXXToYYY`、`RemoveXXXFromYYY`，之后接一系列的栏位名称＋类型。则会自动帮你产生 `add_column`：

```bash
$ rails generate migration AddPartNumberToProducts part_number:string
```

会产生

```ruby
class AddPartNumberToProducts < ActiveRecord::Migration
  def change
    add_column :products, :part_number, :string
  end
end
```

当你 rollback 的时候，Rails 会自动帮你 `remove_column`。

给栏位加上索引（index）也是很简单的：

```bash
$ rails generate migration AddPartNumberToProducts part_number:string:index
```

会产生

```ruby
class AddPartNumberToProducts < ActiveRecord::Migration
  def change
    add_column :products, :part_number, :string
    add_index :products, :part_number
  end
end
```

同样也可以移除某个栏位：

```bash
$ rails generate migration RemovePartNumberFromProducts part_number:string
```

会产生：

```ruby
class RemovePartNumberFromProducts < ActiveRecord::Migration
  def change
    remove_column :products, :part_number, :string
  end
end
```

一次可产生多个栏位：

```bash
$ rails generate migration AddDetailsToProducts part_number:string price:decimal
```

会产生：

```ruby
class AddDetailsToProducts < ActiveRecord::Migration
  def change
    add_column :products, :part_number, :string
    add_column :products, :price, :decimal
  end
end
```

刚刚已经讲过两个常见的 Migration 命名形式：`AddXXXToYYY`、`RemoveXXXFromYYY`，还有 `CreateXXX` 这种：

```bash
$ rails generate migration CreateProducts name:string part_number:string
```

会新建 table 及栏位：

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

不过 Rails 产生的 Migration 不是不能改的，可以按需更改。

栏位类型还有一种叫做 `references` （＝ `belongs_to`）：

```bash
$ rails generate migration AddUserRefToProducts user:references
```

会产生

```ruby
class AddUserRefToProducts < ActiveRecord::Migration
  def change
    add_reference :products, :user, index: true
  end
end
```

会针对 Product 表，产生一个 `user_id` 栏位并加上索引。

__产生 Join Table?__

```bash
rails g migration CreateJoinTableCustomerProduct customer product
```

会产生：

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

## 2.2 Model 产生器

看看 `rails generate model` 会产生出来的 Migration 例子，比如：

```bash
$ rails generate model Product name:string description:text
```

会产生如下的 Migration：

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


`rails generate model Product` 后面可接无限个栏位名及类型。

__Active Record 支援的栏位类型有哪些？__

> `:primary_key`, `:string`, `:text`, <br>
> `:integer`, `:float`, `:decimal`, <br>
> `:datetime`, `:timestamp`, `:time`, <br>
> `:date`, `:binary`, `:boolean`, `:references`

## 2.3 类型修饰符

类型后面还可加修饰符（modifiers），支持下列修饰符：

|修饰符         |说明                                           |
|:-------------|:---------------------------------------------|
|`:limit`      | 设定 `string/text/binary/integer` 栏位的最大值。|
|`:precision`  | 定义 `decimal` 栏位的精度，含小数点可以有几个数字。|
|`:scale`      | 定义 `decimal` 栏位的位数，小数点可以有几位。|
|`:polymorphic`| 给 `belongs_to` association 加上 `type` 栏位。|
|`:null`       | 栏位允不允许 `NULL` 值。|

举例来说

```bash
$ rails generate migration AddDetailsToProducts 'price:decimal{5,2}' supplier:references{polymorphic}
```

会产生如下的 Migration：

```ruby
class AddDetailsToProducts < ActiveRecord::Migration
  def change
    add_column :products, :price, precision: 5, scale: 2
    add_reference :products, :supplier, polymorphic: true, index: true
  end
end
```

# 3. 撰写 Migration

## 3.1 产生 Table

`create_table`，通常用 `rails generate model` 或是 `rails generate scaffold` 的时候会自动产生 Migration，里面就带有 `create_table`，比如 `rails g model product name:string`：

```ruby
create_table :products do |t|
  t.string :name
end
```

`create_table` 预设会产生主键（`id`），可以给主键换名字。用 `:primary_key`，或者是不要主键，可以传入 `id: false`。要传入数据库相关的选项，可以用 `:options`

```ruby
create_table :products, options: "ENGINE=BLACKHOLE" do |t|
  t.string :name, null: false
end
```

会在产生出来的 SQL 语句，加上 `ENGINE=BLACKHOLE`。

更多可查阅 [create_table](http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-create_table) API。


### 3.2 产生 Join Table

`create_join_table` 会产生 HABTM (HasAndBelongsToMany) join table。常见的应用场景：

```ruby
create_join_table :products, :categories
```

会产生一个 `categories_products` 表，有著 `category_id` 与 `product_id` 栏位。这些栏位的预设选项是 `null: false`，可以在 `:column_options` 里改为 `true`：

```ruby
create_join_table :products, :categories, column_options: {null: true}
```

可以更改 join table 的名字，使用 `table_name:` 选项：

```ruby
create_join_table :products, :categories, table_name: :categorization
```

便会产生出 `categorization` 表，一样有 `category_id` 与 `product_id`。

`create_join_table` 也接受区块，可以用来加索引、或是新增更多栏位：

```ruby
create_join_table :products, :categories do |t|
  t.index :product_id
  t.index :category_id
end
```

### 3.3 变更 Table

`change_table` 用来变更已存在的 table。

```ruby
change_table :products do |t|
  t.remove :description, :name
  t.string :part_number
  t.index :part_number
  t.rename :upccode, :upc_code
end
```

会移除 `description` 与 `name` 栏位。新增 `part_number` （字串）栏位，并打上索引。并将 `upccode` 栏位重新命名为 `upc_code`。

### 3.4 Helpers 不够用怎么办

Active Record 提供的 Helper 无法完成你想做的事情时，可以使用 `execute` 方法来运行任何 SQL 语句：

```ruby
Product.connection.execute('UPDATE `products` SET `price`=`free` WHERE 1')
```

每个方法的更多细节与示例，请查阅 API 文件，特别是：

[`ActiveRecord::ConnectionAdapters::SchemaStatements`](http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html)
(which provides the methods available in the `change`, `up` and `down` methods)

[`ActiveRecord::ConnectionAdapters::TableDefinition`](http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/TableDefinition.html)
(which provides the methods available on the object yielded by `create_table`)

[`ActiveRecord::ConnectionAdapters::Table`](http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/Table.html)
(which provides the methods available on the object yielded by `change_table`).

### 3.5 使用 `change` 方法

撰写 Migration 主要用 `change`，大多数情况 Active Record 知道如何运行逆操作。下面是 Active Record 可以自动产生逆操作的方法：

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

`change_table` 也是可逆的，只要传给 `change_table` 的区块没有调用 `change`、`change_default` 或是 `remove` 即可。

如果你想有更多的灵活性，可以使用 `reversible` 或是撰写 `up`、`down` 方法。

### 3.6 使用 `reversible`

复杂的 Migration Active Record 可能不知道怎么变回来。这时候可以使用 `reversible`：

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

使用 `reversible` 会确保运行顺序的正确性。若你做了不可逆的操作，比如删除数据。Active Record 会在运行 `down` 区块时，raise 一个 `ActiveRecord::IrreversibleMigration`。


### 3.7 使用 `up`、`down` 方法

可以不用 `change` 撰写 Migration，使用经典的 `up`、`down` 写法。

`up` 撰写 migrate、`down` 撰写 rollback。两个操作要可以互相抵消。举例来说，`up` 建了一个 table，`down` 就要 `drop` 那个 table。

上面使用 `reversible` 可以用 `up`＋`down` 改写：

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

如果 Migration 是不可逆的操作，要在 `down` raise 一个 `ActiveRecord::IrreversibleMigration`。

### 3.8 取消之前的 Migration

用 `revert` 来取消先前的 Migration：

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

`revert` 方法也接受区块，可以只取消部份的 Migration。看看这个例子（取消 `ExampleMigration`）：

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

上面这个 Migration 也可以不用 `revert` 写成。

把 `create_table` 与 `reversible` 顺序对换，`create_table` 换成 `drop_table`，最后对换 `up` `down`。

这其实就是 `revert` 做的事。

# 4. 运行 Migrations

Rails 提供了许多 Rake 任务用来运行 Migration。

有点要注意的是，运行 `db:migrate` 也会运行 `db:schema:dump`，会帮你更新 `db/schema.rb` 来反映出当下的数据库结构。

如果指定了 target 版本，Active Record 会运行版本之前所有的 Migration。target 名称是 Migration 前面的 UTC 时间戳章（包含 20080906120000）：

```bash
$ rake db:migrate VERSION=20080906120000
```

```bash
$ rake db:rollback VERSION=20080906120000
```

会从最新的版本，运行 `down` 方法到 `20080906120000` 但不包含（`20080906120000`）

## 4.1 回滚

最常见的就是回滚上一个 task。假设你犯了个错误，并想修正。可以：

```bash
$ rake db:rollback
```

会回退一个 Migration。可以指定要回退几步，使用 `STEP` 参数

```bash
$ rake db:rollback STEP=3
```

会取消前 3 次 migrations。



`db:migrate:redo` 用来回退、接著再一次 `rake db:migrate`，同样接受 `STEP` 参数：

```bash
$ rake db:migrate:redo STEP=3
```

这些操作用 `db:migrate` 都办得到，只是方便你使用而已。

## 4.2 设定数据库

The `rake db:setup` 会新建数据库、载入 schema、并用种子数据来初始化数据库。

## 4.3 重置数据库

`rake db:reset` 会将数据库 drop 掉，并重新恢复。

`rake db:reset` ＝ `rake db:drop db:setup`。

__注意！__ 这跟运行所有的 Migration 不一样。这只会用 `schema.rb` 里的内容来操作。如果 Migration 不能回退， `rake db:reset` 也是派不上用场的！了解更多参考 [schema dumping and you](#7-schema-dumping-与你)。

## 4.4 运行特定的 migration

用 `db:migrate:up` 或 `db:migrate:down` tasks，并指定版本：

```bash
$ rake db:migrate:up VERSION=20080906120000
```

会运行在 `20080906120000` 版本之前的 Migration 里面的 `change`、`up` 方法。若已经迁移过了，则 Active Record 不会运行。

## 4.5 在不同环境下运行 migration

默认 `rake db:migrate` 会在 `development` 环境下运行。可以通过指定 `RAILS_ENV` 来指定运行的环境，比如在 `test` 环境下：

```bash
$ rake db:migrate RAILS_ENV=test
```

## 4.6 修改运行中 Migration 的输出

Migration 通常会告诉你他们干了什么，并花了多长时间。建立 table 及加 index 的输出可能像是这样：

```bash
==  CreateProducts: migrating =================================================
-- create_table(:products)
   -> 0.0028s
==  CreateProducts: migrated (0.0028s) ========================================
```

Migration 提供了几个方法让你控制输出讯息：

| 方法                  | 目的
| :-------------------- | :-------
| suppress_messages    | 接受区块作为参数，区块内指名的代码不会产生输出。
| say                  | 接受一个讯息字串，并输出该字串。第二个参数可以用来指定要不要缩排。
| say_with_time        | 同上，但会附上区块的运行时间。若区块返回整数，会假定该整数是受影响的 row 的数量。

举例来说：

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

产生输出如下：

```bash
==  CreateProducts: migrating =================================================
-- Created a table
   -> and an index!
-- Waiting for a while
   -> 10.0013s
   -> 250 rows
==  CreateProducts: migrated (10.0054s) =======================================
```

如果想 Active Record 完全不要输出讯息，运行 `rake db:migrate VERBOSE=false`。

# 5. 修改现有的 Migrations

有时候 Migration 可能会写错。修正过来之后，要先运行 `rake db:rollback`，再运行 `rake db:migrate`。

编辑现有的 Migration 不太好，因为会增加一起开发的人更多工作量。尤其是 Migration 已经上 production，应该要写个新的 Migration，来达成你想完成的事情。

`revert` 方法用来写新的 Migration 取消先前的 Migration 很有用。

# 6. 在 Migration 里使用 Model

在 migration 新增或更新数据的时候，常常会需要用到 model，让你可以取出现有的数据。但有些事情要注意：

举例来说，

一、用了尚未存在的数据库栏位。

二、用了即将新增的数据库栏位。

下面举个例子，祝英台跟梁山伯协同开发，手上是两份相同的代码，里面有一个 `Product` model：

梁山伯去度假了。

祝英台给 `products` table 新增了一个 Migration，加了新栏位，并初始化这个栏位。

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

也给新栏位加了验证措施：

```ruby
# app/models/product.rb

class Product < ActiveRecord::Base
  validates :flag, inclusion: { in: [true, false] }
end
```

祝英台加入第二个验证，并加入另一个栏位到 `products` table，并初始化：

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

又给 `Product` model 的新栏位加了验证：

```ruby
# app/models/product.rb

class Product < ActiveRecord::Base
  validates :flag, inclusion: { in: [true, false] }
  validates :fuzz, presence: true
end
```

Migrations 在祝英台的电脑上都没有问题。

梁山伯放假回来之后：

* 先更新代码 - 包含了最新的 Migrations 及 Product model。
* 接著运行 `rake db:migrate`

Migration 突然失败了，因为当运行第一个 Migration 时，model 试图去验证第二次新增的栏位，而这些栏位数据库里还没有：

```
rake aborted!
An error has occurred, this and all later migrations canceled:

undefined method `fuzz' for #<Product:0x000001049b14a0>
```

一个解决办法是在 Migration 里建一个 local model。这可以骗过 Rails，便不会触发验证。

使用 local model 时，在更新数据库数据之前，记得要调用 `Product.reset_column_information` 来刷新 Active Record 对 `Product` model 的 cache。

如果祝英台早知道这么做，就不会有问题啦：

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

可能有比上面的例子更糟的情况。

举例来说，想想看，要是祝英台新增了一个 Migration，选择性地对某些 product 更新 `description` 栏位。她运行 Migration，提交代码，并开始做下个功能：添加 `fuzz` 到 products 表。

她为这个新功能，又新增了两个 Migration，一个加入新栏位，另一个根据 product 的属性选择性更新 `fuzz` 栏位。

这些 Migration 在祝英台的计算机上运行没有问题。但当梁山伯放假回来，运行 `rake db:migrate`，梁山伯碰到奇妙的 bug：`description` 有预设值，还新增了 `fuzz` 栏位，且所有的 products 的 `fuzz` 都是 `nil`。

解决办法是再次使用 `Product.reset_column_information`，确保 Active Record 在对这些 record 处理之前，知道整个 table 的结构。

# 7. Schema Dumping 与你

## 7.1 Schema 有什么用

Migrations，是可以变化的，要确定数据库的 schema，还是看 `db/schema.rb` 最可靠，或是由 Active Record 产生的 SQL 文件。`db/schema.rb` 与 SQL 都是用来表示数据库目前的状态，不要修改这两个文件。

依靠 Migration 来布署新的 app 是不可靠而且容易出错的。最简单的办法是把 `db/schema.rb` 加载到数据库里。

举例来说吧，这便是测试数据库如何产生的过程：dump 目前的开发数据库，dump 成 `db/schema.rb` 或是 `db/structure.sql`，并载入至测试数据库。

若想了解 Active Record object 有什么属性，直接看 Schema 文件是很有用的。因为属性总是透过 Migration 添加，要追踪这些 Migration 不容易，但最后的结果都总结在 schema 文件里。

[annotate_models](https://github.com/ctran/annotate_models) Gem 自动替你在每个 model 最上方，添加或更新注解，描述每个 model 属性的注解。

## 7.2 Schema Dump 的种类

两种方式来 dump schema。可在 `config/application.rb` 来设定：

`config.active_record.schema_format`，可以是 `:sql` 或 `:ruby`。

如果选择用 `:ruby`，则 schema 会储存在 `db/schema.rb`。打开这个文件，你会看到像是下面的 Migration：

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

许多情况下，这便是数据库里有的东西。这个文件是检查数据库之后，用 `create_table`、`add_index` 这些 helper 来表示数据库的结构。由于这独立于数据库，可以加载到任何 Active Record 所支援的数据库。如果你的 app 要运行许多数据库的时候，这点非常有用。

但有好有坏：`db/schema.rb` 不能表达数据库特有的功能，像是 foreign key constraints、triggers、或是 stored procedures。在 Migration 可以运行任何 SQL 语句，但 schema dumper 不能从这些 SQL 语句里重建出数据库。如果要运行自订的 SQL，记得将 schema 格式设定为 `:sql`。

与其使用 Active Record 提供的 schema dumper，可以用数据库专门的工具。透过 `db:structure:dump` 任务来导出 `db/structure.sql`。举例来说，PostgreSQL 使用 `pg_dump`。MySQL 只不过是多张表的 `SHOW CREATE TABLE` 的结果。

载入这些 schema ，不过是运行里面的 SQL 语句。定义上来说，这可以完美拷贝一份数据库的结构。但使用 `:sql` schema 格式，便不能从一种 RDBMS 数据库，切换到另一种 RDBMS 数据库了。

## 7.3 Schema Dumps 与版本管理

因为 schema dumps 是数据库 schema 最完整的来源，强烈建议你将 schema 用版本管理来追踪。

# 8. Active Record 与 Referential Integrity

Active Record 认为事情要在 model 里处理好，不是在数据库。也是因为这个原因，像是 trigger 或 foreign key constraints 这种牵涉到数据库的事情不常使用

`validates :foreign_key, uniqueness: true` 是整合数据的一种方法。`:dependet` 选项让 model 可以自动 destroy 与其关联的数据。有人认为这种操作不能保证 referential integrity，要在数据库解决才是。

虽然 Active Record 没有直接提供任何工具来解决这件事，但你可以用 `execute` 方法来运行 SQL 语句，也可以使用像是 [foreigner](https://github.com/matthuhiggins/foreigner) 这种 Gem。Foreigner 给  Active Record 加入 foreign key 的支援（包含在 `db/schema.rb` dumping foreign key。）

# 9. Migrations 与 Seed Data

有些人使用 Migration 来加数据到数据库：

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

但 Rails 有 “seeds” 这个功能，应该这么用才对。在 `db/seeds.rb` 填入 Ruby 代码，运行 `rake db:seed` 即可：

```ruby
5.times do |i|
  Product.create(name: "Product ##{i}", description: "A product.")
end
```

这个办法比用 Migration 来建立数据到空的数据库好。

# 延伸阅读

[Active Record Migrations — Ruby on Rails Guides](http://edgeguides.rubyonrails.org/migrations.html)

[Ruby on Rails 实战圣经 | Migrations（数据库迁移）](http://ihower.tw/rails3/migrations.html)
