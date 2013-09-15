# [Form Helpers][fh]

表單（Form）是給使用者輸入的介面，web application 裡面最基礎的元素之一。表單寫起來很繁瑣，Rails 提供很多有用的 helper 讓你快速製造出不同需求的表單。

# 1. 簡單的表單

最基本的 form helper：`form_tag`

```erb
<%= form_tag do %>
  Form contents
<% end %>
```

按下表單送出時，會對頁面做 POST。假設上面這個表單在 `/home/index`，產生的 HTML 如下：

```html
<form accept-charset="UTF-8" action="/home/index" method="post">
  <div style="margin:0;padding:0">
    <input name="utf8" type="hidden" value="&#x2713;" />
    <input name="authenticity_token" type="hidden" value="f755bb0ed134b76c432144748a6d4b7a7ddf2b71" />
  </div>
  Form contents
</form>
```

注意到 HTML 裡有個額外的 `div` 元素，裡面有兩個 input。第一個 input 讓瀏覽器使用 `utf8`。第二個 input 是 Rails 內建用來防止 __CSRF (cross-site request forgery protection)__ 攻擊的安全機制，每個非 GET 的表單，Rails 都會幫你產生一個這樣的 `authenticity_token`。

## 1.1 通用搜索表單

最簡單的表單之一就是搜索表單了，通常有：

* 一個有 GET 動詞的表單。
* 可輸入文字的 input。
* input 有 label。
* 送出元素

```erb
<%= form_tag("/search", method: "get") do %>
  <%= label_tag(:q, "Search for:") %>
  <%= text_field_tag(:q) %>
  <%= submit_tag("Search") %>
<% end %>
```

用了這四個 helper：`form_tag`、`label_tag`、`text_field_tag`、`submit_tag`。

會產生如下 HTML：

```html
<form accept-charset="UTF-8" action="/search" method="get"><div style="margin:0;padding:0;display:inline"><input name="utf8" type="hidden" value="&#x2713;" /></div>
  <label for="q">Search for:</label>
  <input id="q" name="q" type="text" />
  <input name="commit" type="submit" value="Search" />
</form>
```

ID 是根據表單名稱（上例為 `q`）所產生，可供 CSS 或 JavaScript 使用。

__切記：搜索表單用正確的 HTTP 動詞：GET。__

### 1.2 Form Helper 呼叫裡傳多個 Hash

`form_tag` 接受 2 個參數：_動作發生的路徑（path）與選項（以 hash 形式傳入）__。可指定送出時要用的方法，及更改表單元素的 class 等。

跟 `link_to` 類似，路徑可以不是字串。可以是 Rails router 看的懂的 URL hash，比如：

```ruby
{ controller: "people", action: "search" }
```

路徑跟選項都是以 hash 傳入，很容易把兩者混在一起，看這個例子：

```ruby
form_tag(controller: "people", action: "search", method: "get", class: "nifty_form")
# => '<form accept-charset="UTF-8" action="/people/search?method=get&class=nifty_form" method="post">'
```

這時候 Ruby 認為你只傳了一個 hash，所以 `method` 與 `class` 跑到 query string 裡了，要明顯的分隔開來才是：

```ruby
form_tag({controller: "people", action: "search"}, method: "get", class: "nifty_form")
# => '<form accept-charset="UTF-8" action="/people/search" method="get" class="nifty_form">'
```

### 1.3 生成表單的 Helpers

Rails 提供一系列的 Helpers，可以產生 checkbox、text field、radio buttons。

__`_tag`__ 結尾的 helper 會生成一個 `<input>`：

`text_field_tag`、`check_box_tag`，第一個參數是 `input` 的 `name`。表單送出時，`name` 會與表單資料一起放到 `params` 裡送出。

舉例

```erb
<%= text_field_tag(:query) %>
```

取出資料：`params[:query]`

#### 1.3.1 Checkbox

Checkbox? 使用者有一系列的選項，可以決定啟用或停用。

```erb
<%= check_box_tag(:pet_dog) %>
<%= label_tag(:pet_dog, "I own a dog") %>
<%= check_box_tag(:pet_cat) %>
<%= label_tag(:pet_cat, "I own a cat") %>
```

會生成：

```html
<input id="pet_dog" name="pet_dog" type="checkbox" value="1" />
<label for="pet_dog">I own a dog</label>
<input id="pet_cat" name="pet_cat" type="checkbox" value="1" />
<label for="pet_cat">I own a cat</label>
```

`checkbox_box_tag` 第一個參數是 `input` 的 `name`，第二個參數通常是 `input` 的 `value`，當該 checkbox 被選中時，`value` 可在 `params` 取得。

#### 1.3.2 Radio Buttons

跟 checkbox 類似，但只能選一個。

```erb
<%= radio_button_tag(:age, "child") %>
<%= label_tag(:age_child, "I am younger than 21") %>
<%= radio_button_tag(:age, "adult") %>
<%= label_tag(:age_adult, "I'm over 21") %>
```

會生成：

```html
<input id="age_child" name="age" type="radio" value="child" />
<label for="age_child">I am younger than 21</label>
<input id="age_adult" name="age" type="radio" value="adult" />
<label for="age_adult">I'm over 21</label>
```

`radio_button_tag` 第二個參數同樣是 `input` 的 `value`，上例中 `name` 都是 `age`，若使用者有按其中一個 radiobutton 的話，可以用 `params[:age]` 取出。可能的值是 `"child"` 或 `"adult"`。

__記得要給 checkbox 與 radio button 加上 `label`，這樣讓可按的區域變得較廣。

### 1.4 Other Helpers of Interest

其它相關的 helpers：textareas, password fields, hidden fields, search fields, telephone fields, date fields, time fields, color fields, datetime fields, datetime-local fields, month fields, week fields, URL fields and email fields，其中 __search、telephone、date、time、color、datetime、datetime-local、month、week、URL、以及 email 是 HTML5 才有的 input__。

```erb
<%= text_area_tag(:message, "Hi, nice site", size: "24x6") %>
<%= password_field_tag(:password) %>
<%= hidden_field_tag(:parent_id, "5") %>
<%= search_field(:user, :name) %>
<%= telephone_field(:user, :phone) %>
<%= date_field(:user, :born_on) %>
<%= datetime_field(:user, :meeting_time) %>
<%= datetime_local_field(:user, :graduation_day) %>
<%= month_field(:user, :birthday_month) %>
<%= week_field(:user, :birthday_week) %>
<%= url_field(:user, :homepage) %>
<%= email_field(:user, :address) %>
<%= color_field(:user, :favorite_color) %>
<%= time_field(:task, :started_at) %>
```

會生成：

```html
<textarea id="message" name="message" cols="24" rows="6">Hi, nice site</textarea>
<input id="password" name="password" type="password" />
<input id="parent_id" name="parent_id" type="hidden" value="5" />
<input id="user_name" name="user[name]" type="search" />
<input id="user_phone" name="user[phone]" type="tel" />
<input id="user_born_on" name="user[born_on]" type="date" />
<input id="user_meeting_time" name="user[meeting_time]" type="datetime" />
<input id="user_graduation_day" name="user[graduation_day]" type="datetime-local" />
<input id="user_birthday_month" name="user[birthday_month]" type="month" />
<input id="user_birthday_week" name="user[birthday_week]" type="week" />
<input id="user_homepage" name="user[homepage]" type="url" />
<input id="user_address" name="user[address]" type="email" />
<input id="user_favorite_color" name="user[favorite_color]" type="color" value="#000000" />
<input id="task_started_at" name="task[started_at]" type="time" />
```

# 2. 處理 Model 物件



# 3. 輕鬆製作下拉選單

# 4. 使用日期與時間的 Form Helpers

# 5. 上傳檔案

# 6. 客製化 Form Builders

# 7. 了解參數的命名規範

# 8. 給外部 resource 使用的 Form

# 9. 打造複雜的表單

# 相關的 RubyGems

## 熱門

[formtastic](https://github.com/justinfrench/formtastic)

[simple_form](https://github.com/plataformatec/simple_form)

其它製作表單的 Gems 可參考: [Form Builders | The Ruby Toolbox](https://www.ruby-toolbox.com/categories/rails_form_builders)

# 延伸閱讀

* [Form Helpers — Ruby on Rails Guides][fh]

* [Ruby on Rails 實戰聖經 | ActionView Helpers 輔助方法](http://ihower.tw/rails3/actionview-helpers.html)

[fh]: http://edgeguides.rubyonrails.org/form_helpers.html