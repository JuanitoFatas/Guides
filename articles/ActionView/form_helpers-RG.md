# [Form Helpers][fh]

表單（Form）是給使用者輸入的介面，web application 裡面最基礎的元素之一。表單寫起來很繁瑣，Rails 提供很多有用的 helper 讓你快速製造出不同需求的表單。

## 目錄

* [1. 簡單的表單](1-簡單的表單)
* [2. 處理 Model Object 的 Helpers](2-處理-model-object-的-helpers)
* [3. 輕鬆製作下拉式選單](3-輕鬆製作下拉式選單)
* [4. 使用日期與時間的](4-使用日期與時間的-form-helpers)
* [5. 上傳檔案](5-上傳檔案)
* [6. 客製化 Form Builders](6-客製化-form-helpers)
* [7. 了解參數的命名規範](7-了解參數的命名規範)
* [8. 給外部 resource 使用的表單](8-給外部-resource-使用的表單)
* [9. 打造複雜的表單](9-打造複雜的表單)

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

__`_tag` 結尾的 helper 會生成一個 `<input>`__ ：

`text_field_tag`、`check_box_tag`，第一個參數是 `input` 的 `name`。表單送出時，`name` 會與表單資料一起放到 `params` 裡送出。

舉例

```erb
<%= text_field_tag(:query) %>
```

取出資料：`params[:query]`

#### 1.3.1 Checkbox

Checkbox? 使用者有一系列的選項，可多選：

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

其它相關的 helpers：textareas, password fields, hidden fields, search fields, telephone fields, date fields, time fields, color fields, datetime fields, datetime-local fields, month fields, week fields, URL fields and email fields，__其中 search、telephone、date、time、color、datetime、datetime-local、month、week、URL、以及 email 是 HTML5 才有的 input__。

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

# 2. 處理 Model Object 的 Helpers

## 2.1 Model Object Helpers

表單通常是拿來編輯或新建一個 model object。帶有 `_tag` 字尾的 Helpers 可以解決這件事，但是太繁瑣了。Rails 提供更多方便的 Helpers（沒有 `_tag` 字尾），像是 `text_field`、`text_area` 等，用來處理 Model objects。

這些 Helpers 的第一個參數是 instance variable 的 `name`，第二個參數是要對 instance object 調用的方法名（通常是 attribute）。Rails 會將調用的結果存成 `input` 的 `value`，並幫你給 `input` 的 `name` 取個好名字。

假設 controller 定義了 `@person`，這 `@person` 的 `name` 叫 `Henry`，則

```erb
<%= text_field(:person, :name) %>
```

會生成

```erb
<input id="person_name" name="person[name]" type="text" value="Henry"/>
```

送出表單時，使用者的輸入會存在 `params[:person][:name]`，`params[:person]` 可傳給 `new` 或是 `update` action。由於第二個參數實在是太常用了，不給也可以：

```erb
<%= text_field(:person) %>
```

只要 `Person` objects 有 `name` 與 `name=` 就可以了。

__警告：第一個參數必須是 instance 變數的名稱，如：`:person` 或 `"person"`，而不是傳實際的 instance 進去。__

## 2.2 將表單綁定至 Object

當 `Person` 有很多 attributes 時，我們得一直重複傳入 `:person` 來生成對應的表單。Rails 提供了 `form_for` 讓你把表單綁定至 model 的 object。

假設我們有個處理文章的 controller：`app/controllers/articles_controller.rb`：

```ruby
def new
  @article = Article.new
end
```

對應的 view `app/views/articles/new.html.erb`：

```erb
<%= form_for @article, url: {action: "create"}, html: {class: "nifty_form"} do |f| %>
  <%= f.text_field :title %>
  <%= f.text_area :body, size: "60x12" %>
  <%= f.submit "Create" %>
<% end %>
```

幾件事情要說明一下：

* `@article` 是實際被編輯的 object。
* 有兩個 options (hash）：`:url` 與 `:html`。還可傳入 `:namespace`，用來產生獨一無二的 ID。
* `|f|` 為 form builder。
* 本來寫成 `text_field(:article)` 改為 `f.text_filed`。

生成的 HTML 為：

```html
<form accept-charset="UTF-8" action="/articles/create" method="post" class="nifty_form">
  <input id="article_title" name="article[title]" type="text" />
  <textarea id="article_body" name="article[body]" cols="60" rows="12"></textarea>
  <input name="commit" type="submit" value="Create" />
</form>
```

除了 form builder，還有個 `fields_for` 可用。這在使用相同表單，來編輯多個 model object 的場合下很有用。比如你有個 `Person` model，有一個與之關聯的 `ContactDetail` model，則可產生可同時編輯兩個 model 的表單：

```erb
<%= form_for @person, url: {action: "create"} do |person_form| %>
  <%= person_form.text_field :name %>
  <%= fields_for @person.contact_detail do |contact_details_form| %>
    <%= contact_details_form.text_field :phone_number %>
  <% end %>
<% end %>
```

會生成：

```html
<form accept-charset="UTF-8" action="/people/create" class="new_person" id="new_person" method="post">
  <input id="person_name" name="person[name]" type="text" />
  <input id="contact_detail_phone_number" name="contact_detail[phone_number]" type="text" />
</form>
```

## 2.3 Record Identification

假設你是用 RESTful 風格：

```ruby
resources :articles
```

便可簡化 `form_for` 的書寫。

創建新文章

```ruby
form_for(@article, url: articles_path)
```

可簡化為：

```ruby
form_for(@article)
```


編輯一個 resource

```ruby
form_for(@article, url: article_path(@article), html: {method: "patch"})
```

可簡化為

```ruby
form_for(@article)
```

但若使用了 STI（Single Table Inheritance，單表繼承）則得明確指定 `:url` 與 `:method`。

### 2.3.1 處理 namespace

如果你有 namespace 的 route，`form_for` 也有個簡便的縮寫：

```ruby
form_for [:admin, @article]
```

會新建一個表單，在 `admin` namespace 下將表單送給 `articles` controller。

上面這種寫法等價於：

```ruby
form_for admin_article_path(@article)
```

如果有更多層的命名空間，依樣畫葫蘆就是了：

```ruby
form_for [:admin, :management, @article]
```

## 2.4 PATCH、PUT、DELETE 表單是怎麼工作的？

Rails 框架提倡使用 _RESTful_ 風格來設計  application 。這表示會有很多 “PATCH” 以及 “DELETE” 請求（request），而不是 “GET” 與 “POST”，但多數瀏覽器在送出表單時，不支援非 `GET` 或 `POST` 的請求。Rails 透過一個 `name` 為 `_method` 的隱藏 `input` 來模擬 POST。

```ruby
form_tag(search_path, method: "patch")
```

output:

```html
<form accept-charset="UTF-8" action="/search" method="post">
  <div style="margin:0;padding:0">
    <input name="_method" type="hidden" value="patch" />
    <input name="utf8" type="hidden" value="&#x2713;" />
    <input name="authenticity_token" type="hidden" value="f755bb0ed134b76c432144748a6d4b7a7ddf2b71" />
  </div>
  ...
```

在送出資料時，Rails 會將 `_method` 考慮進去，模擬成一個 POST 請求。

# 3. 輕鬆製作下拉式選單

HTML 純手寫下拉式選單（Select box）需要花很多工夫，比如說有 12 個城市的下拉選單：

```html
<select name="city_id" id="city_id">
  <option value="1">Lisbon</option>
  <option value="2">Madrid</option>
  ...
  <option value="12">Berlin</option>
</select>
```

看看 Rails 是怎麼化繁為簡的。

## 3.1 Select 與 Option 標籤

最通用的 helper 便是 `select_tag`，用來生成 `<select> … </select>`，內有 option 標籤：

```erb
<%= select_tag(:city_id, '<option value="1">Lisbon</option>...') %>
```

這只是剛開始而已，封裝字串在 `select_tag` 裡面無法動態生成 option 標籤，於是有了 `options_for_select`：

```html+erb
<%= options_for_select([['Lisbon', 1], ['Madrid', 2], ...]) %>
```

會生成

```html
<option value="1">Lisbon</option>
<option value="2">Madrid</option>
...
```

`options_for_select` 的第一個參數是嵌套的 array，每個元素有兩個元素，城市名稱（option text）與數值（option value）。option value 是會傳給 controller 的數值。通常會是資料庫 object 裡對應的 id。

現在把 `select_tag` 與 `options_for_select` 結合起來：

```erb
<%= select_tag(:city_id, options_for_select(...)) %>
```

`options_for_select` 可選一個數值作為預設值，比如 Mardrid。

```html+erb
<%= options_for_select([['Lisbon', 1], ['Madrid', 2], ...], 2) %>
```

會生成：

```html
<option value="1">Lisbon</option>
<option value="2" selected="selected">Madrid</option>
...
```

預設值會加上 `selected` attribute。

__注意：__ `options_for_select` 的第二個參數的類型必須與你想要的數值類型一樣，整數就整數、字串就字串。從 `params` 取出的數值為字串，這點要注意一下。

可以用 hash 給每個 option 加上任意的 attribute：

```html+erb
<%= options_for_select([['Lisbon', 1, {'data-size' => '2.8 million'}], ['Madrid', 2, {'data-size' => '3.2 million'}]], 2) %>
```

會生成：

```html
<option value="1" data-size="2.8 million">Lisbon</option>
<option value="2" selected="selected" data-size="3.2 million">Madrid</option>
...
```

## 3.2 處理 Models 的下拉選單

表單與 model 結合，下拉選單也是。處理 model 時，去掉 `_tag` 字尾，用 `select` 即可：

```ruby
# controller:
@person = Person.new(city_id: 2)
```

```erb
# view:
<%= select(:person, :city_id, [['Lisbon', 1], ['Madrid', 2], ...]) %>
```

注意到第三個參數，跟傳給 `options_for_select` 的參數一樣。你無需煩惱如果使用者已經屬於某個城市，Rails 會自己去讀取 `@person.city_id` 幫你決定預選擇的城市是哪個。

也可以用 form builder：

```erb
# select on a form builder
<%= f.select(:city_id, ...) %>
```

上例 Person 與 City Model 存在 `belongs_to` 關係，在使用 `select` 時必須傳入 foreign key，否則會報這個錯誤：`ActiveRecord::AssociationTypeMismatch`。

## 3.3 從任意 objects 集合來的 option tags

`options_for_select` 需要給一個 array 參數，包含了 option 的 text 與 value。但要是你已經有了 City model，而你想要從 model 裡生成這些選項該怎麼做？

```erb
<% cities_array = City.all.map { |city| [city.name, city.id] } %>
<%= options_for_select(cities_array) %>
```

這完全是個完美又可行的解決方案，但 Rails 提供一個更方便的方法：`options_from_collection_for_select`

這個 helper 接受一個隨意物件的集合（collection of arbitrary objects）及兩個額外的參數：讀取 `option` 的 **value** 與 **text** 的名稱。

__注意__ **value** 與 **text** 的順序與 `options_for_select` 顛倒。

```erb
<%= options_from_collection_for_select(City.all, :id, :name) %>
```

接著搭配 `select_tag` 使用，便可生成下拉式選單。但處理 model 時，要用 `collection_select`。

複習下：

`select` = `select_tag` + `options_for_select`
`collection_select` = `select_tag` + `options_from_collection_for_select`


## 3.4 Time Zone 與 Country

要詢問使用者在哪個時區，可以使用

```erb
<%= time_zone_select(:person, :time_zone) %>
```

同時也提供 `time_zone_options_for_select`，讓你有更高的訂製性。

Rails 過去使用 `country_select` 供選擇國家，但這已從 Rails 拿掉了，現在是 Rails 的一個 plugin：[country_select plugin](https://github.com/stefanpenner/country_select)。

某些名稱是不是國家是有爭議的，這也是為什麼要從 Rails 拿掉的原因。

# 4. 使用日期與時間的 Form Helpers

先前有 `_tag` 的 helper 稱為 _barebones helper_，沒有 `_tag_` 的則是操作 model objects 的 helper。

日期與時間的情境下：

`select_date`、`select_time`、 `select_datetime` 是 barebones helpers；

`date_select`、`time_select`、`datetime_select` 則是對應的 model objects helper。

### Barebones Helpers

`select_*` 家族的 helper 第一個參數是 `Date`、`Time` 或 `DateTime` 的 instance，用來作為目前選中的數值，可以忽略不給。舉例來說：

```erb
<%= select_date Date.today, prefix: :start_date %>
```

會生成

```html
<select id="start_date_year" name="start_date[year]"> ... </select>
<select id="start_date_month" name="start_date[month]"> ... </select>
<select id="start_date_day" name="start_date[day]"> ... </select>
```

可以從 `params[:start_date]` 取用年月日：

```ruby
params[:start_date][:year]
params[:start_date][:month]
params[:start_date][:day]
```

要獲得實際的 `Time` 或 `Date` object，要先將這些值取出，丟給對的 constructor 處理：priate constructor, for example

```ruby
Date.civil(params[:start_date][:year].to_i, params[:start_date][:month].to_i, params[:start_date][:day].to_i)
```

`:prefix` 選項為用來在 `params` 取出日期的 key，如上例 `params[:start_date]`，預設值是 `date`。

### Model Object Helpers

`select_date` 與 Active Record 配合的不好，因為 Active Record 期望每個 `params` 的元素都對應到一個 attribute。

而 `date_select` 則給每個參數提供了特別的名字，讓 Active Record 可以識別出來，並做相對應的處理。

```erb
<%= date_select :person, :birth_date %>
```

會生成

```html
<select id="person_birth_date_1i" name="person[birth_date(1i)]"> ... </select>
<select id="person_birth_date_2i" name="person[birth_date(2i)]"> ... </select>
<select id="person_birth_date_3i" name="person[birth_date(3i)]"> ... </select>
```

產生出的 `params`：

```ruby
{'person' => {'birth_date(1i)' => '2008', 'birth_date(2i)' => '11', 'birth_date(3i)' => '22'}}
```

當傳給 `Person.new` 或是 `Person.update` 時，Active Record 注意到這些參數是給 `birth_date` attribute 使用的，並從字尾的 `(ni)` 察覺出先後順序。

### 4.3 常見選項

預設不輸入任何 option，Rails 會使用當下的年月日來產生下拉式選單。比如年份，Rails 通常會產生前後 5 年。如果這個範圍不合適，可以用 `:start_year` 及 `end_year` 來修改。完整的選項清單請查閱 [API documentation](http://api.rubyonrails.org/classes/ActionView/Helpers/DateHelper.html)。

__經驗法則：跟 model 用 `date_select`、其它情況用 `select_date`。__

### 4.4 單一選項

有時候只想顯示年月份當中的某一個，Rails 也有提供這些 helper：

`select_year`、`select_month`、`select_day`、`select_hour`、`select_minute`、`select_second`。

預設選中的值可是數字，或是一個 `Date`、`Time`、`DateTime` 的 instance。

```erb
<%= select_year(2009) %>
<%= select_year(Time.now) %>
```

會生成

```
<select id="date_year" name="date[year]">
...
</select>
```

`params[:date][:year]` 可取出使用者選擇的年份。

可以進一步透過 `:prefix` 或是 `field_name` 選項來訂製 `select` 標籤。

用 `field_name` 選項：

```erb
<%= select_year(2009, :field_name => 'field_name') %>
```

會生成

```erb
<select id="date_field_name" name="date[field_name]">
...
</select>
```

用 `:prefix` 選項：

```erb
<%= select_year(2009, :prefix => 'prefix') %>
```

會生成

```html
<select id="prefix_year" name="prefix[year]">
...
</select>
```


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
