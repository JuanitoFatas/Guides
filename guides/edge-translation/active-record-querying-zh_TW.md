# Active Record Query Interface

__特別要強調的翻譯名詞__

|原文|翻譯|原文|翻譯|
|:--|:--|:--|:--|
|Query|查詢語句|Interface|介面|
|Attributes|屬性|Record|記錄|
|Primary Key|主鍵|Object|物件|
|Raise|拋出|Exception|異常|

----

本篇詳細介紹各種用 Active Record 從資料庫取出資料的方法。

讀完本篇可能會學到.....

* 如何使用各式各樣的方法與條件來取出資料庫記錄。
* 如何排序、取出某幾個屬性、分組、其它用來找出記錄的方法。
* 如何使用 Eager load 來減少資料庫查詢的次數。
* 如何使用動態的 finder 方法。
* 如何檢查特定記錄是否存在。
* 如何對 Active Record Model 做各式計算。
* 如何對 Active Record Relation 使用 `EXPLAIN`。

--------------------------------------------------------------------------------

手寫純 SQL 速度快，但 Rails 提供了許多便利的方法，萬不得以再用 SQL。

本篇之後的例子都會用下列的 Model 來講解：

```ruby
class Client < ActiveRecord::Base
  has_one  :address
  has_many :orders
  has_and_belongs_to_many :roles
end
```

```ruby
class Address < ActiveRecord::Base
  belongs_to :client
end
```

```ruby
class Order < ActiveRecord::Base
  belongs_to :client, counter_cache: true
end
```

```ruby
class Role < ActiveRecord::Base
  has_and_belongs_to_many :clients
end
```

__注意！除非特別說明，否則上列 Model 都用 `id` 作為主鍵。__

用 Active Record 的好處是，不管資料庫用哪一套，Active Record 的方法保持一致。

## 取出資料

Active Record 提供了下列方法，供你從資料庫裡取出資料，這些方法在 Rails 裡叫做 “finder 方法”。每個方法允許你傳參數，來組合出不同的查詢語句。

* `bind`
* `create_with`
* `distinct`
* `eager_load`
* `extending`
* `from`
* `group`
* `having`
* `includes`
* `joins`
* `limit`
* `lock`
* `none`
* `offset`
* `order`
* `preload`
* `readonly`
* `references`
* `reorder`
* `reverse_order`
* `select`
* `uniq`
* `where`

__上列方法皆會回傳一個 `ActiveRecord::Relation` 實例。__

`Model.find(options)` 的主要功能可以總結為：

* 將傳入的參數轉換成對應的 sql 語句。
* 執行 SQL 語句，取回對應的結果。
* 給結果實例化出對應的 Ruby 物件。
* 執行 `after_find` Callbacks。

### 取出單一物件

Active Record 提供數種方式來取出一個物件。

#### 透過主鍵

使用 `Model.find(primary_key)`，可以取出與傳入主鍵對應的物件：

```ruby
# 找出主鍵為 10 的 client。
client = Client.find(10)
# => #<Client id: 10, first_name: "Ryan">
```

對應的 SQL：

```sql
SELECT * FROM clients WHERE (clients.id = 10) LIMIT 1
```

如果沒找到符合條件的 record，會拋出 `ActiveRecord::RecordNotFound` 異常。

#### `take`

`Model.take` 從資料庫取出一筆記錄，但不排序：

```ruby
client = Client.take
# => #<Client id: 1, first_name: "Lifo">
```

對應的 SQL：

```sql
SELECT * FROM clients LIMIT 1
```

資料庫如果沒 record，`Model.take` 會回傳 `nil`。

#### `first`

`Model.first` 用主鍵取出第一筆資料：

```ruby
client = Client.first
# => #<Client id: 1, first_name: "Lifo">
```

對應的 SQL：

```sql
SELECT * FROM clients ORDER BY clients.id ASC LIMIT 1
```

如果沒找到符合條件的 record，`Model.first` 會回傳 `nil`。

#### `last`

`Model.last` 用主鍵取出最後一筆資料：

```ruby
client = Client.last
# => #<Client id: 221, first_name: "Russel">
```

對應的 SQL：

```sql
SELECT * FROM clients ORDER BY clients.id DESC LIMIT 1
```

如果沒找到符合條件的 record，`Model.last` 會回傳 `nil`。

#### `find_by`

`Model.find_by` 找第一筆符合條件的記錄：

```ruby
Client.find_by first_name: 'Lifo'
# => #<Client id: 1, first_name: "Lifo">

Client.find_by first_name: 'Jon'
# => nil
```

等同於：

```ruby
Client.where(first_name: 'Lifo').take
```

#### `take!`

`Model.take!` 從資料庫取出一筆記錄，但不排序：

```ruby
client = Client.take!
# => #<Client id: 1, first_name: "Lifo">
```

對應的 SQL：

```sql
SELECT * FROM clients LIMIT 1
```

資料庫如果沒 record，`Model.take!` 會拋出 `ActiveRecord::RecordNotFound`。

#### `first!`

`Model.first!` 用主鍵取出第一筆資料：

```ruby
client = Client.first!
# => #<Client id: 1, first_name: "Lifo">
```

對應的 SQL：

```sql
SELECT * FROM clients ORDER BY clients.id ASC LIMIT 1
```

如果沒找到符合條件的 record，`Model.first!` 會拋出 `ActiveRecord::RecordNotFound`。

#### `last!`

`Model.last` 用主鍵取出最後一筆資料：

```ruby
client = Client.last!
# => #<Client id: 221, first_name: "Russel">
```

對應的 SQL：

```sql
SELECT * FROM clients ORDER BY clients.id DESC LIMIT 1
```

如果沒找到符合條件的 record，`Model.last!` 會拋出 `ActiveRecord::RecordNotFound`。

#### `find_by!`

`Model.find_by!` 找到第一筆符合條件的紀錄。如果沒找到符合條件的 record，會拋出 `ActiveRecord::RecordNotFound`。

```ruby
Client.find_by! first_name: 'Lifo'
# => #<Client id: 1, first_name: "Lifo">

Client.find_by! first_name: 'Jon'
# => ActiveRecord::RecordNotFound
```

等同於：

```ruby
Client.where(first_name: 'Lifo').take!
```

### 取出多個物件

#### 透過主鍵

`Model.find(array_of_primary_key)` 接受一列主鍵，並以陣列形式返回所有匹配的結果。

```ruby
# 找到主鍵從 1 至 10 的 clients。
client = Client.find([1, 10]) # 或簡寫為 Client.find(1, 10)
# => [#<Client id: 1, first_name: "Lifo">, #<Client id: 10, first_name: "Ryan">]
```

對應的 SQL：

```sql
SELECT * FROM clients WHERE (clients.id IN (1,10))
```

警告：如果沒有全找到符合條件的 record，會拋出 `ActiveRecord::RecordNotFound` 異常。

#### take

`Model.take(limit)` 從頭取出 `limit` 指定範圍內的多筆記錄（不排序）：

```ruby
Client.take(2)
# => [#<Client id: 1, first_name: "Lifo">,
      #<Client id: 2, first_name: "Raf">]
```

對應的 SQL：

```sql
SELECT * FROM clients LIMIT 2
```

#### first

`Model.first(limit)` 從頭取出 `limit` 指定範圍內的多筆記錄（按主鍵排序）：

```ruby
Client.first(2)
# => [#<Client id: 1, first_name: "Lifo">,
      #<Client id: 2, first_name: "Raf">]
```

對應的 SQL：

```sql
SELECT * FROM clients ORDER BY id ASC LIMIT 2
```

#### last

`Model.last(limit)` 從最後開始取出 `limit` 指定範圍內的多筆記錄（按主鍵排序）：

```ruby
Client.last(2)
# => [#<Client id: 10, first_name: "Ryan">,
      #<Client id: 9, first_name: "John">]
```

對應的 SQL：

```sql
SELECT * FROM clients ORDER BY id DESC LIMIT 2
```

### 批次取出多筆記錄

我們常需要處理多筆記錄，比如寄信給使用者，或是轉出資料。

可能會想到這麼做：

```ruby
# 如果有數千個使用者，非常沒效率。
User.all.each do |user|
  NewsLetter.weekly_deliver(user)
end
```

`User.all.each` 會叫 Active Record 去抓整個表，

But this approach becomes increasingly impractical as the table size increases, since `User.all.each` instructs Active Record to fetch _the entire table_ in a single pass, build a model object per row, and then keep the entire array of model objects in memory. Indeed, if we have a large number of records, the entire collection may exceed the amount of memory available.

Rails 提供了兩個方法，來解決這樣的問題：`find_each` 與 `find_in_batch`。

Rails provides two methods that address this problem by dividing records into memory-friendly batches for processing. The first method, `find_each`, retrieves a batch of records and then yields _each_ record to the block individually as a model. The second method, `find_in_batches`, retrieves a batch of records and then yields _the entire batch_ to the block as an array of models.

TIP: The `find_each` and `find_in_batches` methods are intended for use in the batch processing of a large number of records that wouldn't fit in memory all at once. If you just need to loop over a thousand records the regular find methods are the preferred option.

#### `find_each`

`find_each`

The `find_each` method retrieves a batch of records and then yields _each_ record to the block individually as a model. In the following example, `find_each` will retrieve 1000 records (the current default for both `find_each` and `find_in_batches`) and then yield each record individually to the block as a model. This process is repeated until all of the records have been processed:

```ruby
User.find_each do |user|
  NewsLetter.weekly_deliver(user)
end
```

##### `find_each` 接受的選項

The `find_each` method accepts most of the options allowed by the regular `find` method, except for `:order` and `:limit`, which are reserved for internal use by `find_each`.

Two additional options, `:batch_size` and `:start`, are available as well.

**`:batch_size`**

The `:batch_size` option allows you to specify the number of records to be retrieved in each batch, before being passed individually to the block. For example, to retrieve records in batches of 5000:

```ruby
User.find_each(batch_size: 5000) do |user|
  NewsLetter.weekly_deliver(user)
end
```

**`:start`**

By default, records are fetched in ascending order of the primary key, which must be an integer. The `:start` option allows you to configure the first ID of the sequence whenever the lowest ID is not the one you need. This would be useful, for example, if you wanted to resume an interrupted batch process, provided you saved the last processed ID as a checkpoint.

For example, to send newsletters only to users with the primary key starting from 2000, and to retrieve them in batches of 5000:

```ruby
User.find_each(start: 2000, batch_size: 5000) do |user|
  NewsLetter.weekly_deliver(user)
end
```

Another example would be if you wanted multiple workers handling the same processing queue. You could have each worker handle 10000 records by setting the appropriate `:start` option on each worker.

#### `find_in_batches`

The `find_in_batches` method is similar to `find_each`, since both retrieve batches of records. The difference is that `find_in_batches` yields _batches_ to the block as an array of models, instead of individually. The following example will yield to the supplied block an array of up to 1000 invoices at a time, with the final block containing any remaining invoices:

```ruby
# Give add_invoices an array of 1000 invoices at a time
Invoice.find_in_batches(include: :invoice_lines) do |invoices|
  export.add_invoices(invoices)
end
```

NOTE: The `:include` option allows you to name associations that should be loaded alongside with the models.

##### `find_in_batches` 接受的選項

The `find_in_batches` method accepts the same `:batch_size` and `:start` options as `find_each`, as well as most of the options allowed by the regular `find` method, except for `:order` and `:limit`, which are reserved for internal use by `find_in_batches`.

條件
----------

`where` 方法允許你輸入條件來回傳記錄，`where` 即代表了 SQL 語句的 `WHERE` 部分。

條件可以是字串、陣列、或是 Hash。

### 字串條件

Client.where("orders_count = '2'")` 會回傳所有 `orders_count` 是 2 的 clients。

警告：條件是純字串可能有 SQL injection 的風險。舉例來說，`Client.where("first_name LIKE '%#{params[:first_name]}%'")` 是不安全的，參考下節如何將字串條件改用陣列來處理。

### 陣列條件

如果我們要找的 `orders_count`，不一定固定是 2，可能是不定的數字？

```ruby
Client.where("orders_count = ?", params[:orders])
```

Active Record 會將 `?` 換成 `params[:orders]`。也可聲明多個條件：

```ruby
Client.where("orders_count = ? AND locked = ?", params[:orders], false)
```

這樣的程式碼

```ruby
Client.where("orders_count = ?", params[:orders])
```

比下面這個好多了

```ruby
Client.where("orders_count = #{params[:orders]}")
```

因為比較安全。直接將變數插入條件字串裡，不論變數是什麼，都會直接存到資料庫裡。這表示從惡意使用者傳來的變數，會直接存到資料庫。這麼做是把資料庫放在風險裡不管啊！一旦有人知道可以隨意將任何字串插入資料庫裡，他們可以做任何事。

__絕對不要直接將變數插入條件字串裡。__

關於更多 SQL injection 的資料，請參考 [Ruby on Rails 安全指南](edgeguides.rubyonrails.org/security.html#sql-injection)。

#### 佔位符

`?` 可以換成 symbol，並以 Hash 的方式傳入指定的數值：

```ruby
Client.where("created_at >= :start_date AND created_at <= :end_date",
  {start_date: params[:start_date], end_date: params[:end_date]})
```

這樣不僅是可讀性提昇了，多值傳遞也方便。

### Hash

Active Record 同時允許你傳入 hash 形式的條件：

__注意！只有 Equality、Range、subset 可用這種形式來寫條件__

#### Equality Conditions

```ruby
Client.where(locked: true)
```

欄位名稱也可以是字串：

```ruby
Client.where('locked' => true)
```

`belongs_to` 關係裡，關聯名稱也可以用來做查詢，`polymorphic` 關係也可以。

```ruby
Address.where(client: client)
Address.joins(:clients).where(clients: {address: address})
```

注意！查詢的數值不可是 symbol。比如這樣是不允許的 `Client.where(status: :active)`。

#### Range Conditions

```ruby
Client.where(created_at: (Time.now.midnight - 1.day)..Time.now.midnight)
```

This will find all clients created yesterday by using a `BETWEEN` SQL statement:

```sql
SELECT * FROM clients WHERE (clients.created_at BETWEEN '2008-12-21 00:00:00' AND '2008-12-22 00:00:00')
```

This demonstrates a shorter syntax for the examples in [Array Conditions](#array-conditions)

#### Subset Conditions

If you want to find records using the `IN` expression you can pass an array to the conditions hash:

```ruby
Client.where(orders_count: [1,3,5])
```

This code will generate SQL like this:

```sql
SELECT * FROM clients WHERE (clients.orders_count IN (1,3,5))
```

### NOT Conditions

`NOT` SQL queries can be built by `where.not`.

```ruby
Post.where.not(author: author)
```

In other words, this query can be generated by calling `where` with no argument, then immediately chain with `not` passing `where` conditions.

Ordering
--------

To retrieve records from the database in a specific order, you can use the `order` method.

For example, if you're getting a set of records and want to order them in ascending order by the `created_at` field in your table:

```ruby
Client.order(:created_at)
# OR
Client.order("created_at")
```

You could specify `ASC` or `DESC` as well:

```ruby
Client.order(created_at: :desc)
# OR
Client.order(created_at: :asc)
# OR
Client.order("created_at DESC")
# OR
Client.order("created_at ASC")
```

Or ordering by multiple fields:

```ruby
Client.order(orders_count: :asc, created_at: :desc)
# OR
Client.order(:orders_count, created_at: :desc)
# OR
Client.order("orders_count ASC, created_at DESC")
# OR
Client.order("orders_count ASC", "created_at DESC")
```

If you want to call `order` multiple times e.g. in different context, new order will append previous one

```ruby
Client.order("orders_count ASC").order("created_at DESC")
# SELECT * FROM clients ORDER BY orders_count ASC, created_at DESC
```

Selecting Specific Fields
-------------------------

By default, `Model.find` selects all the fields from the result set using `select *`.

To select only a subset of fields from the result set, you can specify the subset via the `select` method.

For example, to select only `viewable_by` and `locked` columns:

```ruby
Client.select("viewable_by, locked")
```

The SQL query used by this find call will be somewhat like:

```sql
SELECT viewable_by, locked FROM clients
```

Be careful because this also means you're initializing a model object with only the fields that you've selected. If you attempt to access a field that is not in the initialized record you'll receive:

```bash
ActiveModel::MissingAttributeError: missing attribute: <attribute>
```

Where `<attribute>` is the attribute you asked for. The `id` method will not raise the `ActiveRecord::MissingAttributeError`, so just be careful when working with associations because they need the `id` method to function properly.

If you would like to only grab a single record per unique value in a certain field, you can use `distinct`:

```ruby
Client.select(:name).distinct
```

This would generate SQL like:

```sql
SELECT DISTINCT name FROM clients
```

You can also remove the uniqueness constraint:

```ruby
query = Client.select(:name).distinct
# => Returns unique names

query.distinct(false)
# => Returns all names, even if there are duplicates
```

Limit and Offset
----------------

To apply `LIMIT` to the SQL fired by the `Model.find`, you can specify the `LIMIT` using `limit` and `offset` methods on the relation.

You can use `limit` to specify the number of records to be retrieved, and use `offset` to specify the number of records to skip before starting to return the records. For example

```ruby
Client.limit(5)
```

will return a maximum of 5 clients and because it specifies no offset it will return the first 5 in the table. The SQL it executes looks like this:

```sql
SELECT * FROM clients LIMIT 5
```

Adding `offset` to that

```ruby
Client.limit(5).offset(30)
```

will return instead a maximum of 5 clients beginning with the 31st. The SQL looks like:

```sql
SELECT * FROM clients LIMIT 5 OFFSET 30
```

Group
-----

To apply a `GROUP BY` clause to the SQL fired by the finder, you can specify the `group` method on the find.

For example, if you want to find a collection of the dates orders were created on:

```ruby
Order.select("date(created_at) as ordered_date, sum(price) as total_price").group("date(created_at)")
```

And this will give you a single `Order` object for each date where there are orders in the database.

The SQL that would be executed would be something like this:

```sql
SELECT date(created_at) as ordered_date, sum(price) as total_price
FROM orders
GROUP BY date(created_at)
```

Having
------

SQL uses the `HAVING` clause to specify conditions on the `GROUP BY` fields. You can add the `HAVING` clause to the SQL fired by the `Model.find` by adding the `:having` option to the find.

For example:

```ruby
Order.select("date(created_at) as ordered_date, sum(price) as total_price").
  group("date(created_at)").having("sum(price) > ?", 100)
```

The SQL that would be executed would be something like this:

```sql
SELECT date(created_at) as ordered_date, sum(price) as total_price
FROM orders
GROUP BY date(created_at)
HAVING sum(price) > 100
```

This will return single order objects for each day, but only those that are ordered more than $100 in a day.

Overriding Conditions
---------------------

### `except`

You can specify certain conditions to be excepted by using the `except` method. For example:

```ruby
Post.where('id > 10').limit(20).order('id asc').except(:order)
```

The SQL that would be executed:

```sql
SELECT * FROM posts WHERE id > 10 LIMIT 20

# Original query without `except`
SELECT * FROM posts WHERE id > 10 ORDER BY id asc LIMIT 20

```

### `unscope`

The `except` method does not work when the relation is merged. For example:

```ruby
Post.comments.except(:order)
```

will still have an order if the order comes from a default scope on Comment. In order to remove all ordering, even from relations which are merged in, use unscope as follows:

```ruby
Post.order('id DESC').limit(20).unscope(:order) = Post.limit(20)
Post.order('id DESC').limit(20).unscope(:order, :limit) = Post.all
```

You can additionally unscope specific where clauses. For example:

```ruby
Post.where(id: 10).limit(1).unscope({ where: :id }, :limit).order('id DESC') = Post.order('id DESC')
```

### `only`

You can also override conditions using the `only` method. For example:

```ruby
Post.where('id > 10').limit(20).order('id desc').only(:order, :where)
```

The SQL that would be executed:

```sql
SELECT * FROM posts WHERE id > 10 ORDER BY id DESC

# Original query without `only`
SELECT "posts".* FROM "posts" WHERE (id > 10) ORDER BY id desc LIMIT 20

```

### `reorder`

The `reorder` method overrides the default scope order. For example:

```ruby
class Post < ActiveRecord::Base
  ..
  ..
  has_many :comments, -> { order('posted_at DESC') }
end

Post.find(10).comments.reorder('name')
```

The SQL that would be executed:

```sql
SELECT * FROM posts WHERE id = 10 ORDER BY name
```

In case the `reorder` clause is not used, the SQL executed would be:

```sql
SELECT * FROM posts WHERE id = 10 ORDER BY posted_at DESC
```

### `reverse_order`

The `reverse_order` method reverses the ordering clause if specified.

```ruby
Client.where("orders_count > 10").order(:name).reverse_order
```

The SQL that would be executed:

```sql
SELECT * FROM clients WHERE orders_count > 10 ORDER BY name DESC
```

If no ordering clause is specified in the query, the `reverse_order` orders by the primary key in reverse order.

```ruby
Client.where("orders_count > 10").reverse_order
```

The SQL that would be executed:

```sql
SELECT * FROM clients WHERE orders_count > 10 ORDER BY clients.id DESC
```

This method accepts **no** arguments.

Null Relation
-------------

The `none` method returns a chainable relation with no records. Any subsequent conditions chained to the returned relation will continue generating empty relations. This is useful in scenarios where you need a chainable response to a method or a scope that could return zero results.

```ruby
Post.none # returns an empty Relation and fires no queries.
```

```ruby
# The visible_posts method below is expected to return a Relation.
@posts = current_user.visible_posts.where(name: params[:name])

def visible_posts
  case role
  when 'Country Manager'
    Post.where(country: country)
  when 'Reviewer'
    Post.published
  when 'Bad User'
    Post.none # => returning [] or nil breaks the caller code in this case
  end
end
```

Readonly Objects
----------------

Active Record provides `readonly` method on a relation to explicitly disallow modification of any of the returned objects. Any attempt to alter a readonly record will not succeed, raising an `ActiveRecord::ReadOnlyRecord` exception.

```ruby
client = Client.readonly.first
client.visits += 1
client.save
```

As `client` is explicitly set to be a readonly object, the above code will raise an `ActiveRecord::ReadOnlyRecord` exception when calling `client.save` with an updated value of _visits_.

Locking Records for Update
--------------------------

Locking is helpful for preventing race conditions when updating records in the database and ensuring atomic updates.

Active Record provides two locking mechanisms:

* Optimistic Locking
* Pessimistic Locking

### Optimistic Locking

Optimistic locking allows multiple users to access the same record for edits, and assumes a minimum of conflicts with the data. It does this by checking whether another process has made changes to a record since it was opened. An `ActiveRecord::StaleObjectError` exception is thrown if that has occurred and the update is ignored.

**Optimistic locking column**

In order to use optimistic locking, the table needs to have a column called `lock_version` of type integer. Each time the record is updated, Active Record increments the `lock_version` column. If an update request is made with a lower value in the `lock_version` field than is currently in the `lock_version` column in the database, the update request will fail with an `ActiveRecord::StaleObjectError`. Example:

```ruby
c1 = Client.find(1)
c2 = Client.find(1)

c1.first_name = "Michael"
c1.save

c2.name = "should fail"
c2.save # Raises an ActiveRecord::StaleObjectError
```

You're then responsible for dealing with the conflict by rescuing the exception and either rolling back, merging, or otherwise apply the business logic needed to resolve the conflict.

This behavior can be turned off by setting `ActiveRecord::Base.lock_optimistically = false`.

To override the name of the `lock_version` column, `ActiveRecord::Base` provides a class attribute called `locking_column`:

```ruby
class Client < ActiveRecord::Base
  self.locking_column = :lock_client_column
end
```

### Pessimistic Locking

Pessimistic locking uses a locking mechanism provided by the underlying database. Using `lock` when building a relation obtains an exclusive lock on the selected rows. Relations using `lock` are usually wrapped inside a transaction for preventing deadlock conditions.

For example:

```ruby
Item.transaction do
  i = Item.lock.first
  i.name = 'Jones'
  i.save
end
```

The above session produces the following SQL for a MySQL backend:

```sql
SQL (0.2ms)   BEGIN
Item Load (0.3ms)   SELECT * FROM `items` LIMIT 1 FOR UPDATE
Item Update (0.4ms)   UPDATE `items` SET `updated_at` = '2009-02-07 18:05:56', `name` = 'Jones' WHERE `id` = 1
SQL (0.8ms)   COMMIT
```

You can also pass raw SQL to the `lock` method for allowing different types of locks. For example, MySQL has an expression called `LOCK IN SHARE MODE` where you can lock a record but still allow other queries to read it. To specify this expression just pass it in as the lock option:

```ruby
Item.transaction do
  i = Item.lock("LOCK IN SHARE MODE").find(1)
  i.increment!(:views)
end
```

If you already have an instance of your model, you can start a transaction and acquire the lock in one go using the following code:

```ruby
item = Item.first
item.with_lock do
  # This block is called within a transaction,
  # item is already locked.
  item.increment!(:views)
end
```

Joining Tables
--------------

Active Record provides a finder method called `joins` for specifying `JOIN` clauses on the resulting SQL. There are multiple ways to use the `joins` method.

### Using a String SQL Fragment

You can just supply the raw SQL specifying the `JOIN` clause to `joins`:

```ruby
Client.joins('LEFT OUTER JOIN addresses ON addresses.client_id = clients.id')
```

This will result in the following SQL:

```sql
SELECT clients.* FROM clients LEFT OUTER JOIN addresses ON addresses.client_id = clients.id
```

### Using Array/Hash of Named Associations

WARNING: This method only works with `INNER JOIN`.

Active Record lets you use the names of the [associations](association_basics.html) defined on the model as a shortcut for specifying `JOIN` clause for those associations when using the `joins` method.

For example, consider the following `Category`, `Post`, `Comment`, `Guest` and `Tag` models:

```ruby
class Category < ActiveRecord::Base
  has_many :posts
end

class Post < ActiveRecord::Base
  belongs_to :category
  has_many :comments
  has_many :tags
end

class Comment < ActiveRecord::Base
  belongs_to :post
  has_one :guest
end

class Guest < ActiveRecord::Base
  belongs_to :comment
end

class Tag < ActiveRecord::Base
  belongs_to :post
end
```

Now all of the following will produce the expected join queries using `INNER JOIN`:

#### Joining a Single Association

```ruby
Category.joins(:posts)
```

This produces:

```sql
SELECT categories.* FROM categories
  INNER JOIN posts ON posts.category_id = categories.id
```

Or, in English: "return a Category object for all categories with posts". Note that you will see duplicate categories if more than one post has the same category. If you want unique categories, you can use `Category.joins(:posts).uniq`.

#### Joining Multiple Associations

```ruby
Post.joins(:category, :comments)
```

This produces:

```sql
SELECT posts.* FROM posts
  INNER JOIN categories ON posts.category_id = categories.id
  INNER JOIN comments ON comments.post_id = posts.id
```

Or, in English: "return all posts that have a category and at least one comment". Note again that posts with multiple comments will show up multiple times.

#### Joining Nested Associations (Single Level)

```ruby
Post.joins(comments: :guest)
```

This produces:

```sql
SELECT posts.* FROM posts
  INNER JOIN comments ON comments.post_id = posts.id
  INNER JOIN guests ON guests.comment_id = comments.id
```

Or, in English: "return all posts that have a comment made by a guest."

#### Joining Nested Associations (Multiple Level)

```ruby
Category.joins(posts: [{comments: :guest}, :tags])
```

This produces:

```sql
SELECT categories.* FROM categories
  INNER JOIN posts ON posts.category_id = categories.id
  INNER JOIN comments ON comments.post_id = posts.id
  INNER JOIN guests ON guests.comment_id = comments.id
  INNER JOIN tags ON tags.post_id = posts.id
```

### Specifying Conditions on the Joined Tables

You can specify conditions on the joined tables using the regular [Array](#array-conditions) and [String](#pure-string-conditions) conditions. [Hash conditions](#hash-conditions) provides a special syntax for specifying conditions for the joined tables:

```ruby
time_range = (Time.now.midnight - 1.day)..Time.now.midnight
Client.joins(:orders).where('orders.created_at' => time_range)
```

An alternative and cleaner syntax is to nest the hash conditions:

```ruby
time_range = (Time.now.midnight - 1.day)..Time.now.midnight
Client.joins(:orders).where(orders: {created_at: time_range})
```

This will find all clients who have orders that were created yesterday, again using a `BETWEEN` SQL expression.

Eager Loading Associations
--------------------------

Eager loading is the mechanism for loading the associated records of the objects returned by `Model.find` using as few queries as possible.

**N + 1 queries problem**

Consider the following code, which finds 10 clients and prints their postcodes:

```ruby
clients = Client.limit(10)

clients.each do |client|
  puts client.address.postcode
end
```

This code looks fine at the first sight. But the problem lies within the total number of queries executed. The above code executes 1 (to find 10 clients) + 10 (one per each client to load the address) = **11** queries in total.

**Solution to N + 1 queries problem**

Active Record lets you specify in advance all the associations that are going to be loaded. This is possible by specifying the `includes` method of the `Model.find` call. With `includes`, Active Record ensures that all of the specified associations are loaded using the minimum possible number of queries.

Revisiting the above case, we could rewrite `Client.limit(10)` to use eager load addresses:

```ruby
clients = Client.includes(:address).limit(10)

clients.each do |client|
  puts client.address.postcode
end
```

The above code will execute just **2** queries, as opposed to **11** queries in the previous case:

```sql
SELECT * FROM clients LIMIT 10
SELECT addresses.* FROM addresses
  WHERE (addresses.client_id IN (1,2,3,4,5,6,7,8,9,10))
```

### Eager Loading Multiple Associations

Active Record lets you eager load any number of associations with a single `Model.find` call by using an array, hash, or a nested hash of array/hash with the `includes` method.

#### Array of Multiple Associations

```ruby
Post.includes(:category, :comments)
```

This loads all the posts and the associated category and comments for each post.

#### Nested Associations Hash

```ruby
Category.includes(posts: [{comments: :guest}, :tags]).find(1)
```

This will find the category with id 1 and eager load all of the associated posts, the associated posts' tags and comments, and every comment's guest association.

### Specifying Conditions on Eager Loaded Associations

Even though Active Record lets you specify conditions on the eager loaded associations just like `joins`, the recommended way is to use [joins](#joining-tables) instead.

However if you must do this, you may use `where` as you would normally.

```ruby
Post.includes(:comments).where("comments.visible" => true)
```

This would generate a query which contains a `LEFT OUTER JOIN` whereas the `joins` method would generate one using the `INNER JOIN` function instead.

```ruby
  SELECT "posts"."id" AS t0_r0, ... "comments"."updated_at" AS t1_r5 FROM "posts" LEFT OUTER JOIN "comments" ON "comments"."post_id" = "posts"."id" WHERE (comments.visible = 1)
```

If there was no `where` condition, this would generate the normal set of two queries.

If, in the case of this `includes` query, there were no comments for any posts, all the posts would still be loaded. By using `joins` (an INNER JOIN), the join conditions **must** match, otherwise no records will be returned.

Scopes
------

Scoping allows you to specify commonly-used queries which can be referenced as method calls on the association objects or models. With these scopes, you can use every method previously covered such as `where`, `joins` and `includes`. All scope methods will return an `ActiveRecord::Relation` object which will allow for further methods (such as other scopes) to be called on it.

To define a simple scope, we use the `scope` method inside the class, passing the query that we'd like to run when this scope is called:

```ruby
class Post < ActiveRecord::Base
  scope :published, -> { where(published: true) }
end
```

This is exactly the same as defining a class method, and which you use is a matter of personal preference:

```ruby
class Post < ActiveRecord::Base
  def self.published
    where(published: true)
  end
end
```

Scopes are also chainable within scopes:

```ruby
class Post < ActiveRecord::Base
  scope :published,               -> { where(published: true) }
  scope :published_and_commented, -> { published.where("comments_count > 0") }
end
```

To call this `published` scope we can call it on either the class:

```ruby
Post.published # => [published posts]
```

Or on an association consisting of `Post` objects:

```ruby
category = Category.first
category.posts.published # => [published posts belonging to this category]
```

### Passing in arguments

Your scope can take arguments:

```ruby
class Post < ActiveRecord::Base
  scope :created_before, ->(time) { where("created_at < ?", time) }
end
```

Call the scope as if it were a class method:

```ruby
Post.created_before(Time.zone.now)
```

However, this is just duplicating the functionality that would be provided to you by a class method.

```ruby
class Post < ActiveRecord::Base
  def self.created_before(time)
    where("created_at < ?", time)
  end
end
```

Using a class method is the preferred way to accept arguments for scopes. These methods will still be accessible on the association objects:

```ruby
category.posts.created_before(time)
```

### Merging of scopes

Just like `where` clauses scopes are merged using `AND` conditions.

```ruby
class User < ActiveRecord::Base
  scope :active, -> { where state: 'active' }
  scope :inactive, -> { where state: 'inactive' }
end

User.active.inactive
# => SELECT "users".* FROM "users" WHERE "users"."state" = 'active' AND "users"."state" = 'inactive'
```

We can mix and match `scope` and `where` conditions and the final sql
will have all conditions joined with `AND` .

```ruby
User.active.where(state: 'finished')
# => SELECT "users".* FROM "users" WHERE "users"."state" = 'active' AND "users"."state" = 'finished'
```

If we do want the `last where clause` to win then `Relation#merge` can
be used .

```ruby
User.active.merge(User.inactive)
# => SELECT "users".* FROM "users" WHERE "users"."state" = 'inactive'
```

One important caveat is that `default_scope` will be overridden by
`scope` and `where` conditions.

```ruby
class User < ActiveRecord::Base
  default_scope { where state: 'pending' }
  scope :active, -> { where state: 'active' }
  scope :inactive, -> { where state: 'inactive' }
end

User.all
# => SELECT "users".* FROM "users" WHERE "users"."state" = 'pending'

User.active
# => SELECT "users".* FROM "users" WHERE "users"."state" = 'active'

User.where(state: 'inactive')
# => SELECT "users".* FROM "users" WHERE "users"."state" = 'inactive'
```

As you can see above the `default_scope` is being overridden by both
`scope` and `where` conditions.


### Applying a default scope

If we wish for a scope to be applied across all queries to the model we can use the
`default_scope` method within the model itself.

```ruby
class Client < ActiveRecord::Base
  default_scope { where("removed_at IS NULL") }
end
```

When queries are executed on this model, the SQL query will now look something like
this:

```sql
SELECT * FROM clients WHERE removed_at IS NULL
```

If you need to do more complex things with a default scope, you can alternatively
define it as a class method:

```ruby
class Client < ActiveRecord::Base
  def self.default_scope
    # Should return an ActiveRecord::Relation.
  end
end
```

### Removing All Scoping

If we wish to remove scoping for any reason we can use the `unscoped` method. This is
especially useful if a `default_scope` is specified in the model and should not be
applied for this particular query.

```ruby
Client.unscoped.load
```

This method removes all scoping and will do a normal query on the table.

Note that chaining `unscoped` with a `scope` does not work. In these cases, it is
recommended that you use the block form of `unscoped`:

```ruby
Client.unscoped {
  Client.created_before(Time.zone.now)
}
```

Dynamic Finders
---------------

NOTE: Dynamic finders have been deprecated in Rails 4.0 and will be
removed in Rails 4.1. The best practice is to use Active Record scopes
instead. You can find the deprecation gem at
https://github.com/rails/activerecord-deprecated_finders

For every field (also known as an attribute) you define in your table, Active Record provides a finder method. If you have a field called `first_name` on your `Client` model for example, you get `find_by_first_name` for free from Active Record. If you have a `locked` field on the `Client` model, you also get `find_by_locked` and methods.

You can specify an exclamation point (`!`) on the end of the dynamic finders to get them to raise an `ActiveRecord::RecordNotFound` error if they do not return any records, like `Client.find_by_name!("Ryan")`

If you want to find both by name and locked, you can chain these finders together by simply typing "`and`" between the fields. For example, `Client.find_by_first_name_and_locked("Ryan", true)`.

Find or Build a New Object
--------------------------

It's common that you need to find a record or create it if it doesn't exist. You can do that with the `find_or_create_by` and `find_or_create_by!` methods.

### `find_or_create_by`

The `find_or_create_by` method checks whether a record with the attributes exists. If it doesn't, then `create` is called. Let's see an example.

Suppose you want to find a client named 'Andy', and if there's none, create one. You can do so by running:

```ruby
Client.find_or_create_by(first_name: 'Andy')
# => #<Client id: 1, first_name: "Andy", orders_count: 0, locked: true, created_at: "2011-08-30 06:09:27", updated_at: "2011-08-30 06:09:27">
```

The SQL generated by this method looks like this:

```sql
SELECT * FROM clients WHERE (clients.first_name = 'Andy') LIMIT 1
BEGIN
INSERT INTO clients (created_at, first_name, locked, orders_count, updated_at) VALUES ('2011-08-30 05:22:57', 'Andy', 1, NULL, '2011-08-30 05:22:57')
COMMIT
```

`find_or_create_by` returns either the record that already exists or the new record. In our case, we didn't already have a client named Andy so the record is created and returned.

The new record might not be saved to the database; that depends on whether validations passed or not (just like `create`).

Suppose we want to set the 'locked' attribute to `false` if we're
creating a new record, but we don't want to include it in the query. So
we want to find the client named "Andy", or if that client doesn't
exist, create a client named "Andy" which is not locked.

We can achieve this in two ways. The first is to use `create_with`:

```ruby
Client.create_with(locked: false).find_or_create_by(first_name: 'Andy')
```

The second way is using a block:

```ruby
Client.find_or_create_by(first_name: 'Andy') do |c|
  c.locked = false
end
```

The block will only be executed if the client is being created. The
second time we run this code, the block will be ignored.

### `find_or_create_by!`

You can also use `find_or_create_by!` to raise an exception if the new record is invalid. Validations are not covered on this guide, but let's assume for a moment that you temporarily add

```ruby
validates :orders_count, presence: true
```

to your `Client` model. If you try to create a new `Client` without passing an `orders_count`, the record will be invalid and an exception will be raised:

```ruby
Client.find_or_create_by!(first_name: 'Andy')
# => ActiveRecord::RecordInvalid: Validation failed: Orders count can't be blank
```

### `find_or_initialize_by`

The `find_or_initialize_by` method will work just like
`find_or_create_by` but it will call `new` instead of `create`. This
means that a new model instance will be created in memory but won't be
saved to the database. Continuing with the `find_or_create_by` example, we
now want the client named 'Nick':

```ruby
nick = Client.find_or_initialize_by(first_name: 'Nick')
# => <Client id: nil, first_name: "Nick", orders_count: 0, locked: true, created_at: "2011-08-30 06:09:27", updated_at: "2011-08-30 06:09:27">

nick.persisted?
# => false

nick.new_record?
# => true
```

Because the object is not yet stored in the database, the SQL generated looks like this:

```sql
SELECT * FROM clients WHERE (clients.first_name = 'Nick') LIMIT 1
```

When you want to save it to the database, just call `save`:

```ruby
nick.save
# => true
```

Finding by SQL
--------------

If you'd like to use your own SQL to find records in a table you can use `find_by_sql`. The `find_by_sql` method will return an array of objects even if the underlying query returns just a single record. For example you could run this query:

```ruby
Client.find_by_sql("SELECT * FROM clients
  INNER JOIN orders ON clients.id = orders.client_id
  ORDER clients.created_at desc")
```

`find_by_sql` provides you with a simple way of making custom calls to the database and retrieving instantiated objects.

### `select_all`

`find_by_sql` has a close relative called `connection#select_all`. `select_all` will retrieve objects from the database using custom SQL just like `find_by_sql` but will not instantiate them. Instead, you will get an array of hashes where each hash indicates a record.

```ruby
Client.connection.select_all("SELECT * FROM clients WHERE id = '1'")
```

### `pluck`

`pluck` can be used to query a single or multiple columns from the underlying table of a model. It accepts a list of column names as argument and returns an array of values of the specified columns with the corresponding data type.

```ruby
Client.where(active: true).pluck(:id)
# SELECT id FROM clients WHERE active = 1
# => [1, 2, 3]

Client.distinct.pluck(:role)
# SELECT DISTINCT role FROM clients
# => ['admin', 'member', 'guest']

Client.pluck(:id, :name)
# SELECT clients.id, clients.name FROM clients
# => [[1, 'David'], [2, 'Jeremy'], [3, 'Jose']]
```

`pluck` makes it possible to replace code like:

```ruby
Client.select(:id).map { |c| c.id }
# or
Client.select(:id).map(&:id)
# or
Client.select(:id, :name).map { |c| [c.id, c.name] }
```

with:

```ruby
Client.pluck(:id)
# or
Client.pluck(:id, :name)
```

Unlike `select`, `pluck` directly converts a database result into a Ruby `Array`,
without constructing `ActiveRecord` objects. This can mean better performance for
a large or often-running query. However, any model method overrides will
not be available. For example:

```ruby
class Client < ActiveRecord::Base
  def name
    "I am #{super}"
  end
end

Client.select(:name).map &:name
# => ["I am David", "I am Jeremy", "I am Jose"]

Client.pluck(:name)
# => ["David", "Jeremy", "Jose"]
```

Furthermore, unlike `select` and other `Relation` scopes, `pluck` triggers an immediate
query, and thus cannot be chained with any further scopes, although it can work with
scopes already constructed earlier:

```ruby
Client.pluck(:name).limit(1)
# => NoMethodError: undefined method `limit' for #<Array:0x007ff34d3ad6d8>

Client.limit(1).pluck(:name)
# => ["David"]
```

### `ids`

`ids` can be used to pluck all the IDs for the relation using the table's primary key.

```ruby
Person.ids
# SELECT id FROM people
```

```ruby
class Person < ActiveRecord::Base
  self.primary_key = "person_id"
end

Person.ids
# SELECT person_id FROM people
```

Existence of Objects
--------------------

If you simply want to check for the existence of the object there's a method called `exists?`.
This method will query the database using the same query as `find`, but instead of returning an
object or collection of objects it will return either `true` or `false`.

```ruby
Client.exists?(1)
```

The `exists?` method also takes multiple values, but the catch is that it will return `true` if any
one of those records exists.

```ruby
Client.exists?(id: [1,2,3])
# or
Client.exists?(name: ['John', 'Sergei'])
```

It's even possible to use `exists?` without any arguments on a model or a relation.

```ruby
Client.where(first_name: 'Ryan').exists?
```

The above returns `true` if there is at least one client with the `first_name` 'Ryan' and `false`
otherwise.

```ruby
Client.exists?
```

The above returns `false` if the `clients` table is empty and `true` otherwise.

You can also use `any?` and `many?` to check for existence on a model or relation.

```ruby
# via a model
Post.any?
Post.many?

# via a named scope
Post.recent.any?
Post.recent.many?

# via a relation
Post.where(published: true).any?
Post.where(published: true).many?

# via an association
Post.first.categories.any?
Post.first.categories.many?
```

計算
------------

This section uses count as an example method in this preamble, but the options described apply to all sub-sections.

All calculation methods work directly on a model:

```ruby
Client.count
# SELECT count(*) AS count_all FROM clients
```

Or on a relation:

```ruby
Client.where(first_name: 'Ryan').count
# SELECT count(*) AS count_all FROM clients WHERE (first_name = 'Ryan')
```

You can also use various finder methods on a relation for performing complex calculations:

```ruby
Client.includes("orders").where(first_name: 'Ryan', orders: {status: 'received'}).count
```

Which will execute:

```sql
SELECT count(DISTINCT clients.id) AS count_all FROM clients
  LEFT OUTER JOIN orders ON orders.client_id = client.id WHERE
  (clients.first_name = 'Ryan' AND orders.status = 'received')
```

### Count

想知道 Model 有多少筆記錄，呼叫 `Client.count` 即可，要知道 Model 裡特定欄位有幾個非空，可以用 `count(:field)`，如 `Client.count(:age)`。

For options, please see the parent section, [Calculations](#calculations).

### Average

If you want to see the average of a certain number in one of your tables you can call the `average` method on the class that relates to the table. This method call will look something like this:

```ruby
Client.average("orders_count")
Client.average(:orders_count)
```

This will return a number (possibly a floating point number such as 3.14159265) representing the average value in the field.

For options, please see the parent section, [Calculations](#calculations).

### Minimum

If you want to find the minimum value of a field in your table you can call the `minimum` method on the class that relates to the table. This method call will look something like this:

```ruby
Client.minimum("age")
Client.minimum(:age)
```

For options, please see the parent section, [Calculations](#calculations).

### Maximum

If you want to find the maximum value of a field in your table you can call the `maximum` method on the class that relates to the table. This method call will look something like this:

```ruby
Client.maximum("age")
Client.maximum(:age)
```

For options, please see the parent section, [Calculations](#calculations).

### Sum

If you want to find the sum of a field for all records in your table you can call the `sum` method on the class that relates to the table. This method call will look something like this:

```ruby
Client.sum("orders_count")
Client.sum(:orders_count)
```

For options, please see the parent section, [Calculations](#calculations).

Running EXPLAIN
---------------

You can run EXPLAIN on the queries triggered by relations. For example,

```ruby
User.where(id: 1).joins(:posts).explain
```

may yield

```
EXPLAIN for: SELECT `users`.* FROM `users` INNER JOIN `posts` ON `posts`.`user_id` = `users`.`id` WHERE `users`.`id` = 1
+----+-------------+-------+-------+---------------+---------+---------+-------+------+-------------+
| id | select_type | table | type  | possible_keys | key     | key_len | ref   | rows | Extra       |
+----+-------------+-------+-------+---------------+---------+---------+-------+------+-------------+
|  1 | SIMPLE      | users | const | PRIMARY       | PRIMARY | 4       | const |    1 |             |
|  1 | SIMPLE      | posts | ALL   | NULL          | NULL    | NULL    | NULL  |    1 | Using where |
+----+-------------+-------+-------+---------------+---------+---------+-------+------+-------------+
2 rows in set (0.00 sec)
```

under MySQL.

Active Record performs a pretty printing that emulates the one of the database
shells. So, the same query running with the PostgreSQL adapter would yield instead

```
EXPLAIN for: SELECT "users".* FROM "users" INNER JOIN "posts" ON "posts"."user_id" = "users"."id" WHERE "users"."id" = 1
                                  QUERY PLAN
------------------------------------------------------------------------------
 Nested Loop Left Join  (cost=0.00..37.24 rows=8 width=0)
   Join Filter: (posts.user_id = users.id)
   ->  Index Scan using users_pkey on users  (cost=0.00..8.27 rows=1 width=4)
         Index Cond: (id = 1)
   ->  Seq Scan on posts  (cost=0.00..28.88 rows=8 width=4)
         Filter: (posts.user_id = 1)
(6 rows)
```

Eager loading may trigger more than one query under the hood, and some queries
may need the results of previous ones. Because of that, `explain` actually
executes the query, and then asks for the query plans. For example,

```ruby
User.where(id: 1).includes(:posts).explain
```

yields

```
EXPLAIN for: SELECT `users`.* FROM `users`  WHERE `users`.`id` = 1
+----+-------------+-------+-------+---------------+---------+---------+-------+------+-------+
| id | select_type | table | type  | possible_keys | key     | key_len | ref   | rows | Extra |
+----+-------------+-------+-------+---------------+---------+---------+-------+------+-------+
|  1 | SIMPLE      | users | const | PRIMARY       | PRIMARY | 4       | const |    1 |       |
+----+-------------+-------+-------+---------------+---------+---------+-------+------+-------+
1 row in set (0.00 sec)

EXPLAIN for: SELECT `posts`.* FROM `posts`  WHERE `posts`.`user_id` IN (1)
+----+-------------+-------+------+---------------+------+---------+------+------+-------------+
| id | select_type | table | type | possible_keys | key  | key_len | ref  | rows | Extra       |
+----+-------------+-------+------+---------------+------+---------+------+------+-------------+
|  1 | SIMPLE      | posts | ALL  | NULL          | NULL | NULL    | NULL |    1 | Using where |
+----+-------------+-------+------+---------------+------+---------+------+------+-------------+
1 row in set (0.00 sec)
```

under MySQL.

### 解讀 EXPLAIN

Interpretation of the output of EXPLAIN is beyond the scope of this guide. The
following pointers may be helpful:

* SQLite3: [EXPLAIN QUERY PLAN](http://www.sqlite.org/eqp.html)

* MySQL: [EXPLAIN Output Format](http://dev.mysql.com/doc/refman/5.6/en/explain-output.html)

* PostgreSQL: [Using EXPLAIN](http://www.postgresql.org/docs/current/static/using-explain.html)
