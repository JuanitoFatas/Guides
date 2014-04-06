Active Record 查詢接口
=============================

本篇詳細介紹各種用 Active Record 多種從資料庫取出資料的方法。

讀完本篇，您將學到：

* 如何使用各種方法與條件來取出資料庫記錄（record）。
* 如何排序、取出某幾個屬性、分組、其它用來找出資料庫記錄的特性。
* 如何使用 Eager load 來減少資料庫查詢的次數。
* 如何使用 Active Record 動態的 Finder 方法。
* 如何檢查特定的資料庫記錄是否存在。
* 如何在 Active Record Model 裡做各式計算。
* 如何對 Active Record Relation 使用 `EXPLAIN`。

--------------------------------------------------------------------------------

如果習慣寫純 SQL 來查詢資料庫，則會發現在 Rails 裡有更好的方式可以執行同樣的操作。Active Record 適用於大多數場景，需要寫 SQL 的場景會變得非常少。

本篇之後的例子都會用下列的 Model 來講解：

TIP: 除非特別說明，否則下列 Model 都用 `id` 作為主鍵。

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

Active Record 幫你對資料庫做查詢，相容多數資料庫（MySQL、PostgreSQL 以及 SQLite 等）。不管用的是何種資料庫，Active Record 方法格式保持一致。

取出資料
----------

Active Record 提供了多種 Finder 方法，用來從資料庫裡取出物件。每個 Finder 方法允許傳參數，來對資料庫執行不同的查詢，而無需直接寫純 SQL。

Finder 方法有：

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

以上方法皆會回傳一個 `ActiveRecord::Relation` 實例。

`Model.find(options)` 的主要操作可以總結如下：

* 將傳入的參數轉換成對應的 SQL 語句。
* 執行 SQL 語句，去資料庫取回對應的結果。
* 將每個查詢結果，根據適當的 Model 實例化出 Ruby 物件。
* 有 `after_find` 回呼的話，執行它們。

### 取出單一物件

Active Record 提供數種方式來取出一個物件。

#### 透過主鍵

使用 `Model.find(primary_key)` 來取出給定主鍵的物件，比如：

```ruby
# Find the client with primary key (id) 10.
client = Client.find(10)
# => #<Client id: 10, first_name: "Ryan">
```

對應的 SQL：

```sql
SELECT * FROM clients WHERE (clients.id = 10) LIMIT 1
```

如果 `Model.find(primary_key)` 沒找到符合條件的記錄，則會拋出 `ActiveRecord::RecordNotFound` 異常。

#### `take`

`Model.take` 從資料庫取出一筆記錄，不考慮順序，比如：

```ruby
client = Client.take
# => #<Client id: 1, first_name: "Lifo">
```

對應的 SQL：

```sql
SELECT * FROM clients LIMIT 1
```

如果沒找到記錄，`Model.take` 會回傳 `nil`，不會拋出異常。

TIP: 取得的記錄根據使用的資料庫引擎會有不同結果。

#### `first`

`Model.first` 按主鍵排序，取出第一筆資料，比如：

```ruby
client = Client.first
# => #<Client id: 1, first_name: "Lifo">
```

對應的 SQL：

```sql
SELECT * FROM clients ORDER BY clients.id ASC LIMIT 1
```

如果沒找到記錄，`Model.first` 會回傳 `nil`，不會拋出異常。

#### `last`

`Model.last` 按主鍵排序，取出最後一筆資料，比如：

```ruby
client = Client.last
# => #<Client id: 221, first_name: "Russel">
```

對應的 SQL：

```sql
SELECT * FROM clients ORDER BY clients.id DESC LIMIT 1
```

如果沒找到記錄，`Model.last` 會回傳 `nil`，不會拋出異常。

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

`Model.take!` 從資料庫取出一筆記錄，不考慮任何順序，比如：

```ruby
client = Client.take!
# => #<Client id: 1, first_name: "Lifo">
```

對應的 SQL：

```sql
SELECT * FROM clients LIMIT 1
```

如果沒找到記錄，`Model.take!` 會拋出 `ActiveRecord::RecordNotFound`。

#### `first!`

`Model.first!` 按主鍵排序，取出第一筆資料，比如：

```ruby
client = Client.first!
# => #<Client id: 1, first_name: "Lifo">
```

對應的 SQL：

```sql
SELECT * FROM clients ORDER BY clients.id ASC LIMIT 1
```

如果沒找到記錄，`Model.first!` 會拋出 `ActiveRecord::RecordNotFound` 異常。

#### `last!`

`Model.last!` 按主鍵排序，取出最後一筆資料，比如：

```ruby
client = Client.last!
# => #<Client id: 221, first_name: "Russel">
```

對應的 SQL：

```sql
SELECT * FROM clients ORDER BY clients.id DESC LIMIT 1
```

如果沒找到記錄，`Model.last!` 會拋出 `ActiveRecord::RecordNotFound` 異常。

#### `find_by!`

`Model.find_by!` 找第一筆符合條件的紀錄。

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

如果沒找到符合條件的記錄，`Model.find_by!` 會拋出 `ActiveRecord::RecordNotFound` 異常。

### 取出多個物件

#### 使用多個主鍵

`Model.find(array_of_primary_key)` 接受以主鍵組成的陣列，並以陣列形式返回所有匹配的結果，比如：

```ruby
# Find the clients with primary keys 1 and 10.
client = Client.find([1, 10]) # Or even Client.find(1, 10)
# => [#<Client id: 1, first_name: "Lifo">, #<Client id: 10, first_name: "Ryan">]
```

對應的 SQL：

```sql
SELECT * FROM clients WHERE (clients.id IN (1,10))
```

WARNING: 只要有一個主鍵沒找到對應的紀錄，`Model.find(array_of_primary_key)` 會拋出 ActiveRecord::RecordNotFound` 異常。

#### `take`

`Model.take(limit)` 取出 `limit` 筆記錄，不考慮順序：

```ruby
Client.take(2)
# => [#<Client id: 1, first_name: "Lifo">,
      #<Client id: 2, first_name: "Raf">]
```

對應的 SQL：

```sql
SELECT * FROM clients LIMIT 2
```

#### `first`

`Model.first(limit)` 按主鍵排序，取出 `limit` 筆記錄：

```ruby
Client.first(2)
# => [#<Client id: 1, first_name: "Lifo">,
      #<Client id: 2, first_name: "Raf">]
```

對應的 SQL：

```sql
SELECT * FROM clients ORDER BY id ASC LIMIT 2
```

#### `last`

`Model.last(limit)` 按主鍵排序，從後取出 `limit` 筆記錄：

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

處理多筆記錄是常見的需求，比如寄信給使用者，轉出資料。

直覺可能會這麼做：

```ruby
# 如果有數千個使用者，效率非常差。
User.all.each do |user|
  NewsLetter.weekly_deliver(user)
end
```

但在資料表很大的時候，這個方法便不實用了。由於 `User.all.each` 告訴 Active Record 一次去把整張表抓出來，再為表的每一列建出物件，最後將所有的物件放到記憶體裡。如果資料庫裡存了非常多筆記錄，可能會把記憶體用光。

Rails 提供了兩個方法來解決這個問題，將記錄針對記憶體來說有效率的大小，分批處理。第一個方法是 `find_each`，取出一批記錄，並將每筆記錄傳入至區塊裡，可取單一筆記錄。第二個方法是 `find_in_batches`，一次取一批記錄，整批放至區塊裡，整批記錄以陣列形式取用。

TIP: `find_each` 與 `find_in_batches` 方法專門用來解決大量記錄，處理無法一次放至記憶體的大量記錄。如果只是一千筆資料，使用平常的查詢方法便足夠了。

#### `find_each`

`find_each` 方法取出一批記錄，將每筆記錄傳入區塊裡。下面的例子，將以 `find_each` 來取出 1000 筆記錄（`find_each` 與 `find_in_batches` 的預設值），並傳至區塊。一次處理 1000 筆，直至記錄通通處理完畢為止：

```ruby
User.find_each do |user|
  NewsLetter.weekly_deliver(user)
end
```

##### `find_each` 選項

`find_each` 方法接受多數 `find` 所允許的選項，除了 `:order` 與 `:limit`，這兩個選項保留供 `find_each` 內部使用。

此外有兩個額外的選項，`:batch_size` 與 `:start`。

**`:batch_size`**

`:batch_size` 選項允許你在將各筆記錄傳進區塊前，指定一批要取多少筆記錄。比如一次取 5000 筆：

```ruby
User.find_each(batch_size: 5000) do |user|
  NewsLetter.weekly_deliver(user)
end
```

**`:start`**

預設記錄按主鍵升序取出，主鍵類型必須是整數。批次預設從最小的 ID 開始，可用 `:start` 選項可以設定批次的起始 ID。在前次被中斷的批量處理重新開始的場景下很有用。

舉例來說，本週總共有 5000 封信要發。1-1999 已經發過了，便可以使用此選項從 2000 開始發信：

```ruby
User.find_each(start: 2000, batch_size: 5000) do |user|
  NewsLetter.weekly_deliver(user)
end
```

另個例子是想要多個 worker 處理同個佇列時。可以使用 `:start` 讓每個 worker 分別處理 10000 筆記錄。

#### `find_in_batches`

`find_in_batches` 方法與 `find_each` 類似，皆用來取出記錄。差別在於 `find_in_batchs` 取出記錄放入陣列傳至區塊，而 `find_each` 是一筆一筆放入區塊。下例會一次將 1000 張發票拿到區塊裡處理：

```ruby
# Give add_invoices an array of 1000 invoices at a time
Invoice.find_in_batches(include: :invoice_lines) do |invoices|
  export.add_invoices(invoices)
end
```

NOTE: `:include` 選項可以指定需要跟 Model 一起載入的關聯。

##### `find_in_batches` 接受的選項

`find_in_batches` 方法接受和 `find_each` 一樣的選項： `:batch_size` 與 `:start`，以及多數 `find` 接受的參數，除了 `:order` 與 `:limit` 之外。

`find_in_batches` 方法接受和 `find_each` 一樣的選項： `:batch_size` 與 `:start`，以及多數 `find` 接受的參數，除了 `:order` 與 `:limit` 之外。這兩個選項保留供 `find_in_batches` 內部使用。

條件
----------

`where` 方法允許取出符合條件的記錄，`where` 即代表了 SQL 語句的 `WHERE` 部分。

條件可以是字串、陣列、或是 Hash。

### 字串條件

直接將要使用的條件，以字串形式傳入 `where` 即可。如 `Client.where("orders_count = '2'")` 會回傳所有 `orders_count` 是 2 的 clients。

WARNING: 條件是純字串可能有 SQL injection 的風險。舉例來說，`Client.where("first_name LIKE '%#{params[:first_name]}%'")` 是不安全的，參考下節如何將字串條件改用陣列來處理。

### 陣列條件

如果我們要找的 `orders_count`，不一定固定是 2，可能是不定的數字：

```ruby
Client.where("orders_count = ?", params[:orders])
```

Active Record 會將 `?` 換成 `params[:orders]` 做查詢。也可聲明多個條件，條件式後的元素，對應到條件裡的每個 `?`。

```ruby
Client.where("orders_count = ? AND locked = ?", params[:orders], false)
```

上例第一個 `?` 會換成 `params[:orders]`，第二個則會換成 SQL 裡的 `false` （根據不同的 adapter 而異）。

這麼寫

```ruby
Client.where("orders_count = ?", params[:orders])
```

比下面這種寫法好多了

```ruby
Client.where("orders_count = #{params[:orders]}")
```

因為前者比較安全。直接將變數插入條件字串裡，不論變數是什麼，都會直接存到資料庫裡。這表示從惡意使用者傳來的變數，會直接存到資料庫。這麼做是把資料庫放在風險裡不管啊！一旦有人知道，可以隨意將任何字串插入資料庫裡，就可以做任何想做的事。__絕對不要直接將變數插入條件字串裡。__

TIP: 關於更多 SQL injection 的資料，請參考 [Ruby on Rails 安全指南](edgeguides.rubyonrails.org/security.html#sql-injection)。

#### 佔位符

替換除了可以使用 `?` 之外，用符號也可以。以 Hash 的鍵值對方式，傳入陣列條件：

```ruby
Client.where("created_at >= :start_date AND created_at <= :end_date", {start_date: params[:start_date], end_date: params[:end_date]})
```

若條件中有許多參數，這種寫法不僅提高了可讀性，傳遞起來也更方便。

### Hash

Active Record 同時允許你傳入 Hash 形式的條件，以提高條件式的可讀性。使用 Hash 條件時，鍵是要查詢的欄位、值為期望值。

NOTE: 只有 Equality、Range、subset 可用這種形式來寫條件。

#### Equality

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

Note: 條件的值不能用符號。比如這樣是不允許的 `Client.where(status: :active)`。

#### Range

```ruby
Client.where(created_at: (Time.now.midnight - 1.day)..Time.now.midnight)
```

會使用 SQL 的 `BETWEEN` 找出所有在昨天建立的客戶。

```sql
SELECT * FROM clients WHERE (clients.created_at BETWEEN '2008-12-21 00:00:00' AND '2008-12-22 00:00:00')
```

這種寫法展示了如何簡化[陣列條件](#)。

#### Subset

如果要使用 SQL 的 `IN` 來查詢，可以在條件 Hash 裡傳入陣列：

```ruby
Client.where(orders_count: [1,3,5])
```

上例會產生像是如下的 SQL：

```sql
SELECT * FROM clients WHERE (clients.orders_count IN (1,3,5))
```

### NOT

SQL 的 `NOT` 可以使用 `where.not`。

```ruby
Post.where.not(author: author)
```

換句話說，先不傳參數呼叫 `where`，再使用 `not` 傳入 `where` 條件。

排序
--------

要按照特定順序來取出記錄，可以使用 `order` 方法。

比如有一組記錄，想要按照 `created_at` 升序排列：

```ruby
Client.order(:created_at)
# OR
Client.order("created_at")
```

升序 `ASC`；降序 `DESC`：

```ruby
Client.order(created_at: :desc)
# OR
Client.order(created_at: :asc)
# OR
Client.order("created_at DESC")
# OR
Client.order("created_at ASC")
```

排序多個欄位：

```ruby
Client.order(orders_count: :asc, created_at: :desc)
# OR
Client.order(:orders_count, created_at: :desc)
# OR
Client.order("orders_count ASC, created_at DESC")
# OR
Client.order("orders_count ASC", "created_at DESC")
```

如果想在不同的語境裡連鎖使用 `order`，SQL 的 ORDER BY 順序與呼叫順序相同：

```ruby
Client.order("orders_count ASC").order("created_at DESC")
# SELECT * FROM clients ORDER BY orders_count ASC, created_at DESC
```

選出特定欄位
-------------------------

`Model.find` 預設會使用 `select *` 取出所有的欄位。

只要取某些欄位的話，可以透過 `select` 方法來聲明。

比如，只要 `viewable_by` 與 `locked` 欄位：

```ruby
Client.select("viewable_by, locked")
```

會產生出像是下面的 SQL 語句：

```sql
SELECT viewable_by, locked FROM clients
```

要小心使用 `select`。因為實例化出來的物件僅有所選欄位。如果試圖存取不存在的欄位，會得到 `ActiveModel::MissingAttributeError` 異常：

```bash
ActiveModel::MissingAttributeError: missing attribute: <attribute>
```

上面的 `<attribute>` 會是試圖存取的欄位。`id` 方法不會拋出 `ActiveModel::MissingAttributeError`，所以在關聯裡使用要格外注意，因為關聯要有 `id` 才能正常工作。

如果想找出特定欄位所有不同的數值，使用 `distinct`：

```ruby
Client.select(:name).distinct
```

會產生如下 SQL：

```sql
SELECT DISTINCT name FROM clients
```

也可以之後移掉唯一性的限制：

```ruby
query = Client.select(:name).distinct
# => Returns unique names

query.distinct(false)
# => Returns all names, even if there are duplicates
```

Limit 與 Offset
----------------

要在 `Model.find` 裡使用 SQL 的 `LIMIT`，可以對 Active Record Relation 使用 `limit` 與 `offset` 方法 可以指定從第幾個記錄開始查詢。比如：

```ruby
Client.limit(5)
```

最多會回傳 5 位客戶。因為沒指定 `offset`，會回傳資料比如的前 5 筆。產生的 SQL 會像是：

```sql
SELECT * FROM clients LIMIT 5
```

上例加上 `offset`：

```ruby
Client.limit(5).offset(30)
```

會從資料庫裡的第 31 筆開始，最多回傳 5 位客戶的紀錄，產生的 SQL 像是：

```sql
SELECT * FROM clients LIMIT 5 OFFSET 30
```

Group
----------


要在 `Model.find` 裡使用 SQL 的 `LIMIT`，可以對 Active Record Relation 使用 `group` 方法。

比如想找出某日的訂單：

```ruby
Order.select("date(created_at) as ordered_date, sum(price) as total_price").group("date(created_at)")
```

會依照存在資料庫裡的順序，按日期回傳單筆訂單物件。

產生的 SQL 會像是：

```sql
SELECT date(created_at) as ordered_date, sum(price) as total_price
FROM orders
GROUP BY date(created_at)
```

Having
------

在 SQL 裡，可以使用 `HAVING` 子句來對 `GROUP BY` 欄位下條件。`Model.find` 加入 `:having` 選項。

比如：

```ruby
Order.select("date(created_at) as ordered_date, sum(price) as total_price").
  group("date(created_at)").having("sum(price) > ?", 100)
```

產生的 SQL 會像是：

```sql
SELECT date(created_at) as ordered_date, sum(price) as total_price
FROM orders
GROUP BY date(created_at)
HAVING sum(price) > 100
```

這會回傳每天總價大於 `100` 的訂單。

覆蓋條件
---------------------

### `except`

用 `except` 來去掉特定條件，如：

```ruby
Post.where('id > 10').limit(20).order('id asc').except(:order)
```

執行的 SQL 語句：

```sql
SELECT * FROM posts WHERE id > 10 LIMIT 20

# Original query without `except`
SELECT * FROM posts WHERE id > 10 ORDER BY id asc LIMIT 20

```

### `unscope`

`except` 在 Relation 合併時無效，比如：

```ruby
Post.comments.except(:order)
```

如果 `.order(...)` 從預設 scope 而來，則不會消去。為了要移掉所有 `.order(...)`，使用 `unscope`：

```ruby
Post.order('id DESC').limit(20).unscope(:order) = Post.limit(20)
Post.order('id DESC').limit(20).unscope(:order, :limit) = Post.all
```

`unscope` 特定的 `where` 子句也可以：

```ruby
Post.where(id: 10).limit(1).unscope({ where: :id }, :limit).order('id DESC') = Post.order('id DESC')
```

### `only`

`only` 可以留下特定條件，比如：

```ruby
Post.where('id > 10').limit(20).order('id desc').only(:order, :where)
```

執行的 SQL 語句：

```sql
SELECT * FROM posts WHERE id > 10 ORDER BY id DESC

# Original query without `only`
SELECT "posts".* FROM "posts" WHERE (id > 10) ORDER BY id desc LIMIT 20

```

### `reorder`

`reorder` 可以覆蓋掉預設 scope 的 `order` 條件：

```ruby
class Post < ActiveRecord::Base
  ..
  ..
  has_many :comments, -> { order('posted_at DESC') }
end

Post.find(10).comments.reorder('name')
```

執行的 SQL 語句：

```sql
SELECT * FROM posts WHERE id = 10 ORDER BY name
```

原本會執行的 SQL 語句（沒用 `reorder`）：

```sql
SELECT * FROM posts WHERE id = 10 ORDER BY posted_at DESC
```

### `reverse_order`

`reverse_order` 方法反轉 `order` 條件。

```ruby
Client.where("orders_count > 10").order(:name).reverse_order
```

執行的 SQL 語句（`ASC` 反轉為 `DESC`）：

```sql
SELECT * FROM clients WHERE orders_count > 10 ORDER BY name DESC
```

如果查詢裡沒有 `order` 條件，預設 `reverse_order` 會對主鍵做反轉。

```ruby
Client.where("orders_count > 10").reverse_order
```

執行的 SQL 語句：

```sql
SELECT * FROM clients WHERE orders_count > 10 ORDER BY clients.id DESC
```

`reverse_order` **不接受參數**。

空 Relation
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

唯讀物件
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
