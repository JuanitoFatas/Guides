Active Record Associations
==========================

__特別要強調的翻譯名詞__

> Association ＝ 關聯

本篇介紹 「Active Record」的關聯功能。

讀完本篇可能會學到.....

* Active Record Model 之間的關聯。
* 理解各種不同的 Active Record 關聯。
* 如何透過新建關聯，來給 Model 新增方法。

------------------------------------------------------------------------------

為什麼要用關聯？
-----------------

關聯簡化了常見的資料庫操作，讓程式碼更精簡。舉個例子，有 2 個 Model，用戶與訂單，每個顧客可有多個訂單：

```ruby
class Customer < ActiveRecord::Base
end

class Order < ActiveRecord::Base
end
```

給已存在的顧客，新增訂單：

```ruby
@order = Order.create(order_date: Time.now, customer_id: @customer.id)
```

刪除客戶順便刪除訂單：


```ruby
@orders = Order.where(customer_id: @customer.id)
@orders.each do |order|
  order.destroy
end
@customer.destroy
```

這真是繁瑣啊！現在看看關聯如何使程式簡化。首先你得告訴 Rails，顧客與訂單之間的關係為何：

```ruby
class Customer < ActiveRecord::Base
  has_many :orders, dependent: :destroy
end

class Order < ActiveRecord::Base
  belongs_to :customer
end
```

加入關聯後，新增訂單竟是如此簡單：

```ruby
@order = @customer.orders.create(order_date: Time.now)
```

刪除顧客及相關的訂單：

```ruby
@customer.destroy
```

下節介紹更多種類的關聯、關聯小秘訣，以及一個完整的關於關聯所有方法與選項的參考手冊。

關聯的種類
-------------------------

Rails 的世界裡，關聯是兩個 Active Record Model 的連結。關聯用簡潔的語法聲明。比如某個 Model 屬於另一個，只消聲明哪個 Model 是 `belongs_to` 那個，Rails 便幫你維護好兩個 Model 之間的主外鍵關係，並幫你新增了許多有用的方法。

Rails 支援以下幾種關聯：

* `belongs_to`
* `has_one`
* `has_many`
* `has_many :through`
* `has_one :through`
* `has_and_belongs_to_many`

本篇之後細講各種關聯如何使用，首先介紹各種關聯的應用場景。

