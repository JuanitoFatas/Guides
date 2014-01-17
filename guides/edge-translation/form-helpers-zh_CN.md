# [Form Helpers][fh]

__特别要强调的翻译名词__

> render 渲染

表单（Form）是给使用者输入的界面，web 应用里面最基础的元素之一。表单写起来很繁琐，Rails 提供很多有用的 helper 让你快速制造出符合不同需求的表单。

## 目录

- [1. 简单的表单](#1-简单的表单)
  - [1.1 通用搜索表单](#11-通用搜索表单)
    - [1.2 Form Helper 调用里传多个 Hash](#12-form-helper-调用里传多个-hash)
    - [1.3 生成表单的 Helpers](#13-生成表单的-helpers)
      - [1.3.1 Checkbox](#131-checkbox)
      - [1.3.2 Radio Buttons](#132-radio-buttons)
    - [1.4 其它相关的 helpers](#14-其它相关的-helpers)
- [2. 处理 Model 对象的 Helpers](#2-处理-model-对象的-helpers)
  - [2.1 Model 对象的 Helpers](#21-model-对象的-helpers)
  - [2.2 将表单绑定至对象](#22-将表单绑定至对象)
  - [2.3 Record Identification](#23-record-identification)
    - [2.3.1 处理 namespace](#231-处理-namespace)
  - [2.4 PATCH、PUT、DELETE 表单是怎么工作的？](#24-patch、put、delete-表单是怎么工作的？)
- [3. 轻松制作下拉式选单](#3-轻松制作下拉式选单)
  - [3.1 Select 与 Option 标签](#31-select-与-option-标签)
  - [3.2 处理 Models 的下拉选单](#32-处理-models-的下拉选单)
  - [3.3 从任意对象集合来的 option 标签](#33-从任意对象集合来的-option-标签)
  - [3.4 Time Zone 与 Country](#34-time-zone-与-country)
- [4. 使用日期与时间的 Form Helpers](#4-使用日期与时间的-form-helpers)
    - [Barebones Helpers](#barebones-helpers)
    - [Model 对象的 Helpers](#model-对象的-helpers)
    - [4.3 常见选项](#43-常见选项)
    - [4.4 单一选项](#44-单一选项)
- [5. 上传文件](#5-上传文件)
    - [5.1 究竟上传了什么](#51-究竟上传了什么)
    - [5.2 处理 Ajax](#52-处理-ajax)
- [6. 客制化 Form Builders](#6-客制化-form-builders)
- [7. 了解参数的命名规范](#7-了解参数的命名规范)
  - [7.1 基本结构](#71-基本结构)
  - [7.2 结合起来](#72-结合起来)
  - [7.3 使用 Form Helpers](#73-使用-form-helpers)
- [8. 给外部的 resource 使用的表单](#8-给外部的-resource-使用的表单)
- [9. 打造复杂的表单](#9-打造复杂的表单)
  - [9.1 设​​定 Model](#91-设​​定-model)
  - [9.2 制作表单](#92-制作表单)
  - [9.3 控制器层面](#93-控制器层面)
    - [9.4 移除对象](#94-移除对象)
    - [9.5 避免有空的 Record](#95-避免有空的-record)
    - [9.6 动态加入 Fields](#96-动态加入-fields)
- [表单相关的 RubyGems](#表单相关的-rubygems)
- [延伸阅读](#延伸阅读)

# 1. 简单的表单

最基本的表单 helper：`form_tag`

```erb
<%= form_tag do %>
  Form contents
<% end %>
```

按下表单送出时，会对页面做 POST。假设上面这个表单在 `/home/index`，生成的 HTML 如下：

```html
<form accept-charset="UTF-8" action="/home/index" method="post">
  <div style="margin:0;padding:0">
    <input name="utf8" type="hidden" value="&#x2713;" />
    <input name="authenticity_token" type="hidden" value="f755bb0ed134b76c432144748a6d4b7a7ddf2b71" />
  </div>
  Form contents
</form>
```

注意到 HTML 里有个额外的 `div` 元素，里面有两个 `input`。第一个 `input` 让浏览器使用 `UTF-8`。第二个 `input` 是 Rails 内建用来防止 __CSRF (cross-site request forgery protection)__ 攻击的安全机制，每个非 GET 的表单，Rails 都会帮你生成一个这样的 `authenticity_token`。

## 1.1 通用搜索表单

最简单的表单就是搜索表单了，通常有：

* 一个有 GET 动词的表单。
* 可输入文字的 `input`。
* `input` 有 `label`。
* 送出元素。

```erb
<%= form_tag("/search", method: "get") do %>
  <%= label_tag(:q, "Search for:") %>
  <%= text_field_tag​​(:q) %>
  <%= submit_tag("Search") %>
<% end %>
```

用到这四个 Helper：`form_tag`、`label_tag`、`text_field_tag​​`、`submit_tag`。

会生成如下 HTML：

```html
<form accept-charset="UTF-8" action="/search" method="get"><div style="margin:0;padding:0;display:inline"><input name="utf8" type= "hidden" value="&#x2713;" /></div>
  <label f​​or="q">Search for:</label>
  <input id="q" name="q" type="text" />
  <input name="commit" type="submit" value="Search" />
</form>
```

ID 是根据表单名称（上例为 `q`）所生成，可供 CSS 或 JavaScript 使用。

__切记：搜索表单用正确的 HTTP 动词：GET。__

### 1.2 Form Helper 调用里传多个 Hash

`form_tag` 接受 2 个参数： __动作发生的路径（path）与选项（以 hash 形式传入）__。可指定送出时要用的方法、更改表单元素的 `class` 等。

和 `link_to` 相似，路径可以不是字串。可以是 Rails Router 看的懂的 URL hash，比如：

```ruby
{ controller: "people", action: "search" }
```

路径和选项都是以 hash 传入，很容易把两者混在一起，看这个例子：

```ruby
form_tag(controller: "people", action: "search", method: "get", class: "nifty_form")
# => '<form accept-charset="UTF-8" action="/people/search?method=get&class=nifty_form" method="post">'
```

这时候 Ruby 认为你只传了一个 hash，所以 `method` 与 `class` 跑到 query string 里了，要明确的分隔开来才是：

```ruby
form_tag({controller: "people", action: "search"}, method: "get", class: "nifty_form")
# => '<form accept-charset="UTF-8" action="/people/search" method="get" class="nifty_form">'
```

### 1.3 生成表单的 Helpers

Rails 提供一系列的 Helpers，可以生成 checkbox、text field、radio buttons 等。

__`_tag` 结尾的 helper 会生成一个 `<input>`__ ：

`text_field_tag​​`、`check_box_tag`，第一个参数是 `input` 的 `name`。表单送出时，`name` 会与表单数据一起放到 `params` 里送出。

举例

```erb
<%= text_field_tag​​(:query) %>
```

取出数据：`params[:query]`

#### 1.3.1 Checkbox

Checkbox 是多选框，让使用者有一系列可多选的选项：

```erb
<%= check_box_tag(:pet_dog) %>
<%= label_tag(:pet_dog, "I own a dog") %>
<%= check_box_tag(:pet_cat) %>
<%= label_tag(:pet_cat, "I own a cat") %>
```

会生成：

```html
<input id="pet_dog" name="pet_dog" type="checkbox" value="1" />
<label f​​or="pet_dog">I own a dog</label>
<input id="pet_cat" name="pet_cat" type="checkbox" value="1" />
<label f​​or="pet_cat">I own a cat</label>
```

`checkbox_box_tag` 第一个参数是 `input` 的 `name`，第二个参数通常是 `input` 的 `value`，当该 checkbox 被选中时，`value` 可在 `params` 取得。

#### 1.3.2 Radio Buttons

跟 checkbox 类似，但只能选一个。

```erb
<%= radio_button_tag(:age, "child") %>
<%= label_tag(:age_child, "I am younger than 21") %>
<%= radio_button_tag(:age, "adult") %>
<%= label_tag(:age_adult, "I'm over 21") %>
```

会生成：

```html
<input id="age_child" name="age" type="radio" value="child" />
<label f​​or="age_child">I am younger than 21</label>
<input id="age_adult" name="age" type="radio" value="adult" />
<label f​​or="age_adult">I'm over 21</label>
```

`radio_button_tag` 第二个参数同样是 `input` 的 `value`，上例中 `name` 都是 `age`，若使用者有按其中一个 radio button 的话，可以用 `params[:age]` 取出。可能的值是 `"child"` 或 `"adult"`。

__记得要给 checkbox 与 radio button 加上 `label`，这样可按的区域更广。__

### 1.4 其它相关的 helpers

textareas、password fields、hidden fields、search fields、telephone fields、date fields、time fields、color fields、datetime fields、datetime-local fields、month fields、week fields、url fields、email fields、number fields 及 range fields， __其中 search、telephone、date、time、color、datetime、datetime-local、month、week、url、email、number 以及 range 是 HTML5 才有的 input type__。

```erb
<%= text_area_tag(:message, "Hi, nice site", size: "24x6") %>
<%= password_field_tag​​(:password) %>
<%= hidden_​​field_tag​​(:parent_id, "5") %>
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
<%= number_field(:price, nil, in: 1.0..20.0, step: 0.5) %>
<%= range_field(:percent, nil, in: 1..100) %>
```

会生成：

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
<input id="price_" max="20.0" min="1.0" name="price[]" step="0.5" type="number" />
<input id="percent_" max="100" min="1" name="percent[]" type="range" />
```

# 2. 处理 Model 对象的 Helpers

## 2.1 Model 对象的 Helpers

表单通常拿来编辑或新建 model 对象。带有 `_tag` 字尾的 Helpers 可以办到这件事，但太繁琐了。 Rails 提供更多方便的 Helpers（没有 `_tag` 字尾），像是 `text_field`、`text_area` 等，用来处理 Model 对象。

这些 Helpers 的第一个参数是实例变量的名字 `name`，第二个参数是要对实例对象调用的方法名称（通常是 `attr​​ibute`）。 Rails 会将调用的结果存成 `input` 的 `value`，并帮你给 `input` 的 `name` 取个好名字。

假设 controller 定义了 `@person`，这 `@person` 的 `name` 叫 `Henry`，则

```erb
<%= text_field(:person, :name) %>
```

会生成

```erb
<input id="person_name" name="person[name]" type="text" value="Henry"/>
```

送出表单时，使用者的输入会存在 `params[:person][:name]`，`params[:person]` 可传给 `new` 或是 `update` action。由于第二个参数实在是太常用了，不给也可以：

```erb
<%= text_field(:person) %>
```

只要 `Person` 对象 有 `name` 与 `name=` 就可以了。

__警告：第一个参数必须是实例变量的“名称”，如：`:person` 或 `"person"`，而不是传实际的实例进去。__

## 2.2 将表单绑定至对象

当 `Person` 有很多属性时，得重复传入 `:person` 来生成对应的表单时。Rails 提供了 `form_for` 让你把表单绑定至 model 的对象。

假设我们有个处理文章的 controller：`app/controllers/articles_controller.rb`：

```ruby
def new
  @article = Article.new
end
```

对应的 view `app/views/articles/new.html.erb`：

```erb
<%= form_for @article, url: {action: "create"}, html: {class: "nifty_form"} do |f| %>
  <%= f.text_field :title %>
  <%= f.text_area :body, size: "60x12" %>
  <%= f.submit "Create" %>
<% end %>
```

几件事情要说明一下：

* `@article` 是实际被编辑的对象。
* 传入了两个选项 (hash）：`:url` 与 `:html`。还可传入 `:namespace`，用来生成独一无二的 ID。
* `|f|` 为 form builder。
* 本来写成 `text_field(:article)` 改为 `f.text_filed`。

生成的 HTML 为：

```html
<form accept-charset="UTF-8" action="/articles/create" method="post" class="nifty_form">
  <input id="article_title" name="article[title]" type="text" />
  <textarea id="article_body" name="article[body]" cols="60" rows="12"></textarea>
  <input name="commit" type="submit" value="Create" />
</form>
```

除了 form builder，还有个 `fields_for` 可用。这在使用相同表单，来编辑多个 model 对象的场合下很有用。比如你有个 `Person` model，有一个与之关联的 `ContactDetail` model，则可生成可同时编辑两个 model 的表单：

```erb
<%= form_for @person, url: {action: "create"} do |person_form| %>
  <%= person_form.text_field :name %>
  <%= fields_for @person.contact_detail do |contact_details_form| %>
    <%= contact_details_form.text_field :phone_number %>
  <% end %>
<% end %>
```

会生成：

```html
<form accept-charset="UTF-8" action="/people/create" class="new_person" id="new_person" method="post">
  <input id="person_name" name="person[name]" type="text" />
  <input id="contact_detail_phone_number" name="contact_detail[phone_number]" type="text" />
</form>
```

## 2.3 Record Identification

假设你依循 RESTful 风格：

```ruby
resources :articles
```

便可简化 `form_for` 的书写。

创建新文章

```ruby
form_for(@article, url: articles_path)
```

可简化为：

```ruby
form_for(@article)
```

编辑一个 resource

```ruby
form_for(@article, url: article_path(@article), html: {method: "patch"})
```

可简化为

```ruby
form_for(@article)
```

但若使用了 STI（Single Table Inheritance，单表继承）则得明确指定 `:url` 与 `:method`。

__写 `form_for` 最好指定 `:url`，这是一个常见的新手错误。__

### 2.3.1 处理 namespace

如果你有 namespace 的 route，`form_for` 也有个简便的缩写：

```ruby
form_for [:admin, @article]
```

会新建一个表单，在 `admin` namespace 下，将表单送给 `articles` Controller。

上面这种写法等价于：

```ruby
form_for admin_article_path(@article)
```

如果有更多层的命名空间，依样画葫芦便是：

```ruby
form_for [:admin, :management, @article]
```

## 2.4 PATCH、PUT、DELETE 表单是怎么工作的？

Rails 框架提倡使用 _RESTful_ 风格来设计 web 应用。这表示会有很多 “PATCH” 以及 “DELETE” 请求（request），而不是 “GET” 与 “POST”，但多数浏览器在送出表单时，不支援非 `GET` 或 `POST` 的请求。 Rails 通过一个 `name` 为 `_method` 的 hidden `input` 来将 PATCH 请求，模拟成 POST。

```ruby
form_tag(search_path, method: "patch")
```

输出：

```html
<form accept-charset="UTF-8" action="/search" method="post">
  <div style="margin:0;padding:0">
    <input name="_method" type="hidden" value="patch" />
    <input name="utf8" type="hidden" value="&#x2713;" />
    <input name="authenticity_token" type="hidden" value="f755bb0ed134b76c432144748a6d4b7a7ddf2b71" />
  </div>
  ...
```

在送出数据时，Rails 会将 `_method` 考虑进去，模拟成一个 POST 请求。

# 3. 轻松制作下拉式选单

HTML 纯手写下拉式选单（Select box）需要花很多功夫，比如说有 12 个城市的下拉选单：

```html
<select name="city_id" id="city_id">
  <option value="1">Lisbon</option>
  <option value="2">Madrid</option>
  ...
  <option value="12">Berlin</option>
</select>
```

看看 Rails 是怎么化繁为简的。

## 3.1 Select 与 Option 标签

最通用的 helper 便是 `select_tag`，用来生成 `<select> … </select>`，内有 option 标签：

```erb
<%= select_tag(:city_id, '<option value="1">Lisbon</option>...') %>
```

这只是刚开始而已，上面把字串封装在 `select_tag` 里面，无法动态生成 `option` 标签，于是有了 `options_for_select`：

```html+erb
<%= options_for_select([['Lisbon', 1], ['Madrid', 2], ...]) %>
```

会生成

```html
<option value="1">Lisbon</option>
<option value="2">Madrid</option>
...
```

`options_for_select` 的第一个参数是嵌套的 array，每个元素有两个元素，城市名称（option text）与数值（option value）。 option value 是会传给 controller 的数值。通常会是数据库里，对象对应的 `id`。

现在把 `select_tag` 与 `options_for_select` 结合起来：

```erb
<%= select_tag(:city_id, options_for_select(...)) %>
```

`options_for_select` 可选一个数值作为预设值，比如 Mardrid。

```html+erb
<%= options_for_select([['Lisbon', 1], ['Madrid', 2], ...], 2) %>
```

会生成：

```html
<option value="1">Lisbon</option>
<option value="2" selected="selected">Madrid</option>
...
```

预设值会加上 `selected` attribute。

__注意__ `options_for_select` 的第二个参数的类型，必须与你想要的数值类型一样，整数就整数、字串就字串。从 `params` 取出的数值为字串，这点要注意一下。

可以用 hash 给每个 option 加上任意的属性：

```html+erb
<%= options_for_select([['Lisbon', 1, {'data-size' => '2.8 million'}], ['Madrid', 2, {'data-size' => '3.2 million'}]] , 2) %>
```

会生成：

```html
<option value="1" data-size="2.8 million">Lisbon</option>
<option value="2" selected="selected" data-size="3.2 million">Madrid</option>
...
```

## 3.2 处理 Models 的下拉选单

多数情况下，表单控件会与特定数据库模型绑在一起，而由于你预期 Rails 会提供定制好的 Helper 给你用。

Rails 已经帮你想好了！有的，表单处理 Model 对象把 `_tag` 去掉；

下拉选单也一样，`select_tag` 去掉 `_tag`，用 `select` 即可：

```ruby
# controller:
@person = Person.new(city_id: 2)
```

```erb
# view:
<%= select(:person, :city_id, [['Lisbon', 1], ['Madrid', 2], ...]) %>
```

注意到第三个参数，跟传给 `options_for_select` 的参数一样。无需烦恼使用者是否属于某个城市，Rails 会自己去读取 `@person.city_id` 帮你决定预选择的城市是哪个。

也可以用 form builder：

```erb
# select on a form builder
<%= f.select(:city_id, ...) %>
```

上例 Person 与 City Model 存在 `belongs_to` 关系，在使用 `select` 时必须传入 for​​eign key，否则会报这个错误：`ActiveRecord::AssociationTypeMismatch`。

## 3.3 从任意对象集合来的 option 标签

`options_for_select` 需要给一个 array 参数，包含了 option 的 `text` 与 `value`。但要是已经有了 City Model，想要直接从 Model 里生成这些选项该怎么做？

```erb
<% cities_array = City.all.map { |city| [city.name, city.id] } %>
<%= options_for_select(cities_array) %>
```

这完全是个完美又可行的解决方案，但 Rails 提供一个更方便的方法：`options_from_collection_for_select`

这个 helper 接受一个任意对象的集合（collection of arbitrary objects）及两个额外的参数：读取 `option` 的 **value** 与 **text** 的名称。

__注意 `options_from_collection_for_select` 参数 `value` 与 `text` 的顺序与 `options_for_select` 颠倒__。

```erb
<%= options_from_collection_for_select(City.all, :id, :name) %>
```

接着搭配 `select_tag` 使用，便可生成下拉式选单。但处理 model 时，要用 `collection_select`。

复习：

`select` = `select_tag` + `options_for_select`

`collection_select` = `select_tag` + `options_from_collection_for_select`

## 3.4 Time Zone 与 Country

要询问使用者在哪个时区，可以使用

```erb
<%= time_zon​​e_select(:person, :time_zon​​e) %>
```

同时也提供 `time_zon​​e_options_for_select`，让你有更高的订制性。

Rails 过去使用 `country_select` 供选择国家，但这已从 Rails 拿掉了，现在是 Rails 的一个 插件：[country_select plugin](https://github.com/stefanpenner/country_select)。

某些名称是不是国家是有争议的，这也是为什么要从 Rails 拿掉的原因。

# 4. 使用日期与时间的 Form Helpers

先前有 `_tag` 的 helper 称为 _barebones helper_，没有 `_tag_` 的则是操作 model 对象的 helper。

日期与时间的情境下：

`select_date`、`select_time`、 `select_datetime` 是 barebones helpers；

`date_select`、`time_select`、`datetime_select` 则是对应的 model 对象的 helper。

### Barebones Helpers

`select_*` 家族的 helper 第一个参数是 `Date`、`Time` 或 `DateTime` 的 instance，用来作为目前选中的数值，可以忽略不给。举例来说：

```erb
<%= select_date Date.today, prefix: :start_date %>
```

会生成

```html
<select id="start_date_year" name="start_date[year]"> ... </select>
<select id="start_date_month" name="start_date[month]"> ... </select>
<select id="start_date_day" name="start_date[day]"> ... </select>
```

可以从 `params[:start_date]` 取用年月日：

```ruby
params[:start_date][:year]
params[:start_date][:month]
params[:start_date][:day]
```

要获得实际的 `Time` 或 `Date` 对象，要先将这些值取出，丢给对的 constructor 处理：priate constructor，举例来说：

```ruby
Date.civil(params[:start_date][:year].to_i, params[:start_date][:month].to_i, params[:start_date][:day].to_i)
```

`:prefix` 选项为用来在 `params` 取出日期的 key，如上例 `params[:start_date]`，预设值是 `date`。

### Model 对象的 Helpers

`select_date` 与 Active Record 配合的不好，因为 Active Record 期望每个 `params` 的元素都对应到一个属性。

而 `date_select` 则给每个参数提供了特别的名字，让 Active Record 可以识别出来，并做相对应的处理。

```erb
<%= date_select :person, :birth_date %>
```

会生成

```html
<select id="person_birth_date_1i" name="person[birth_date(1i)]"> ... </select>
<select id="person_birth_date_2i" name="person[birth_date(2i)]"> ... </select>
<select id="person_birth_date_3i" name="person[birth_date(3i)]"> ... </select>
```

生成出的 `params`：

```ruby
{'person' => {'birth_date(1i)' => '2008', 'birth_date(2i)' => '11', 'birth_date(3i)' => '22'}}
```

当传给 `Person.new` 或是 `Person.update` 时，Active Record 注意到这些参数是给 `birth_date` attribute 使用的，并从字尾的 `(ni)` 察觉出先后顺序。

### 4.3 常见选项

预设不输入任何 option，Rails 会使用当下的年月日来生成下拉式选单。比如年份，Rails 通常会生成前后 5 年。如果这个范围不合适，可以用 `:start_year` 及 `end_year` 来修改。完整的选项清单请查阅 [API documentation](http://api.rubyonrails.org/classes/ActionView/Helpers/DateHelper.html)。

__经验法则：跟 model 用 `date_select`、其它情况用 `select_date`。__

### 4.4 单一选项

有时候只想显示年月份当中的某一个，Rails 也有提供这些 helper：

`select_year`、`select_month`、`select_day`、`select_hour`、`select_minute`、`select_second`。

预设选中的值可是数字，或是一个 `Date`、`Time`、`DateTime` 的实例。

```erb
<%= select_year(2009) %>
<%= select_year(Time.now) %>
```

会生成

```
<select id="date_year" name="d​​ate[year]">
...
</select>
```

`params[:date][:year]` 可取出使用者选择的年份。

可以进一步通过 `:prefix` 或是 `field_name` 选项来订制 `select` 标签。

用 `field_name` 选项：

```erb
<%= select_year(2009, :field_name => 'field_name') %>
```

会生成

```erb
<select id="date_field_name" name="d​​ate[field_name]">
...
</select>
```

用 `:prefix` 选项：

```erb
<%= select_year(2009, :prefix => 'prefix') %>
```

会生成

```html
<select id="prefix_year" name="prefix[year]">
...
</select>
```

# 5. 上传文件

常见的任务是上传文件，无论是图片或是 CSV。最最最重要的事情是， __必须__ 把编码设成 `"multipart/form-data"`。 `form_for` 已经设定好了、`form_tag` 要自己设定。

下面包含了两个表单，用来上传文件。

```erb
<%= form_tag({action: :upload}, multipart: true) do %>
  <%= file_field_tag​​ 'picture' %>
<% end %>

<%= form_for @person do |f| %>
  <%= f.file_field :picture %>
<% end %>
```

Rails 提供的 helper 通常都是成对的：barebone 的 `file_field_tag​​` 以及针对 model 的 `file_field`。这两个 helper 无法设定预设值（没意义）。

要取出上传的文件，

第一个表单：`params[:picture]`

第二个表单：`params[:person][:picture]`

### 5.1 究竟上传了什么

从 `params` 取出来的对象是 `IO` 子类别的实例。根据文件大小的不同，可能是 `StringIO` 或是 `File` 的 instance。这两个情况里，对象都会有一个 `original_filename` 属性，内容是文件名称；`content_type` 属性包含了文件的 MIME 类型。下面的程式码，上传文件至 `#{Rails.root}/public/uploads`，并用原来的名字储存。


```ruby
def upload
  uploaded_io = params[:person][:picture]
  File.open(Rails.root.join('public', 'uploads', uploaded_io.original_filename), 'wb') do |file|
    file.write(uploaded_io.read)
  end
end
```

文件上传之后还有很多事情要做，比如图片要缩放大小，文件可能要传到 Amazon S3 等。有两个 Rubygem 专门处理这些事情：[CarrierWave](https://github.com/jnicklas/carrierwave) 以及 [Paperclip](http://www.thoughtbot.com/projects/paperclip).

若使用者没有传文件，则对应的参数会是空字串。

### 5.2 处理 Ajax

文件上传要做成 Ajax 不像 `form_for` 加个 `remote: true` 选项那么简单。因为 Serialization 是客户端的 JavaScript 解决，JavaScript 不能从计算机里读取文件，所以文件无法上传。最常见的解决办法是插入一个 iframe，作为表单提交的目的地。

加入 iframe: [AJAX File Uploads with the iFrame Method - Alfa Jango Blog](http://www.alfajango.com/blog/ajax-file-uploads-with-the-if​​rame-method/)

> Remotipart Rails jQuery file uploads via standard Rails "remote: true" forms.

[JangoSteve/remotipart](https://github.com/JangoSteve/remotipart)

# 6. 客制化 Form Builders

`form_for` 与 `fields_for` 是 `FormBuilder` 的 instance。 `FormBuilder` 将显示表单元素都抽象到一个单独的对象里，我们也可以自己写一个 form builder。

```erb
<%= form_for @person do |f| %>
  <%= text_field_with_label f​​, :first_name %>
<% end %>
```

可以换成

```erb
<%= form_for @person, builder: LabellingFormBuilder do |f| %>
  <%= f.text_field :first_name %>
<% end %>
```

自己定义一个 `LabellingFormBuilder`：

```ruby
class LabellingFormBuilder < ActionView::Helpers::FormBuilder
  def text_field(attribute, options={})
    label(attribute) + super
  end
end
```

如果常常会用到这个 helper，可以自己定义一个 `labeled_form_for` helper 来自动加上 `builder: LabellingFormBuilder` 选项。

如果 `f` 是 `FormBuilder` 的实例，则会渲染 (render) `form` partial，并将 partial 的对象设成 `f`。

```erb
<%= render partial: f %>
```

# 7. 了解参数的命名规范

用 Rack 的参数解析器来实验不同的 query，用来了解参数的命名规范。

```ruby
Rack::Utils.parse_query "name=fred&phone=0123456789"
# => {"name"=>"fred", "phone"=>"0123456789"}
```

## 7.1 基本结构

举例

```html
<input id="person_name" name="person[name]" type="text" value="Henry"/>
```

则 `params` hash：

```erb
{'person' => {'name' => 'Henry'}}
```

用 `params[:person][:name]` 可取出送至 controller 的值。

Hash 可以嵌套：

```html
<input id="person_address_city" name="person[address][city]" type="text" value="New York"/>
```

则 `params` hash 变成

```ruby
{'person' => {'address' => {'city' => 'New York'}}}
```

通常 Rails 会忽略重复的参数名称。如果参数名称含有 `[]`，则会变成数组。这可以干嘛？比如想要让使用者输入多组电话：

```html
<input name="person[phone_number][]" type="text"/>
<input name="person[phone_number][]" type="text"/>
<input name="person[phone_number][]" type="text"/>
```

`params[:person][:phone_number]` 会是使用者输入的多组电话。

## 7.2 结合起来

hash 里可以有数组，或是数组里可以有 hash。举例来说，表单可以让你填入任何地址：

```html
<input name="addresses[][line1]" type="text"/>
<input name="addresses[][line2]" type="text"/>
<input name="addresses[][city]"  type="text"/>
```

则 `params[:address]` 会是个里面有数组的 hash，。 hash 的键为 `line1`、`line2`、`city`。 Rails 在碰到已经存在的名称时才会新建一个 hash。

```ruby
{ 'addresses' => { 'line1' => {...}, 'line2' => {...}, 'city' => {...} } }
```

虽然 hash 可以随意嵌套，但数组只能有一层。 数组通常可替换成 hash。举例来说，model 的对象可以表示成数组，但也可用键是对象的 id 的 hash，。

__警告：__

数组参数跟 `check_box` 配合的不好。根据 HTML 的规范来看，没有勾选的 checkbox 不会送出值。但 checkbox 总是送出某个值会比较方便，`check_box` 藉由创建一个隐藏的 input 来送出假值。而选中的 checkbox 送出的值优先级比较高，所以假值不会影响。

要用数组类型的参数最好使用 `check_box_tag` 或是使用 hash 形式的参数。

## 7.3 使用 Form Helpers

`form_for` 与 `fields_for` 都接受 `:index` 选项。

假设我们要做个 person 的地址表单：

```erb
<%= form_for @person do |person_form| %>
  <%= person_form.text_field :name %>
  <% @person.addresses.each do |address| %>
    <%= person_form.fields_for address, index: address.id do |address_form|%>
      <%= address_form.text_field :city %>
    <% end %>
  <% end %>
<% end %>
```

假设每个人有两组地址，id 分别是 23 与 45，则上面的代码会生成：

```html
<form accept-charset="UTF-8" action="/people/1" class="edit_person" id="edit_person_1" method="post">
  <input id="person_name" name="person[name]" type="text" />
  <input id="person_address_23_city" name="person[address][23][city]" type="text" />
  <input id="person_address_45_city" name="person[address][45][city]" type="text" />
</form>
```

最终生成的 `params` hash：

```ruby
{'person' => {'name' => 'Bob', 'address' => {'23' => {'city' => 'Paris'}, '45' => {'city' => ' London'}}}}
```

<!-​​- NOT CLEAR -->
Rails 知道这些输入都是 person 的一部分，因为我们用的是 `fields_for`。而指定 `:index` 选项你告诉 Rails 在 `person[address][city]` 之间插入 id。这通常是用来，修改特定 id 的 Active Record 对象。

看另外一个嵌套的例子。

```erb
<%= fields_for 'person[address][primary]', address, index: address do |address_form| %>
  <%= address_form.text_field :city %>
<% end %>
```

会生成像是这样的 `input`：

```html
<input id="person_address_primary_1_city" name="person[address][primary][1][city]" type="text" value="bologna" />
```

通用规则：

__`fields_for` 或 `form_for` 传入的名字 ＋ index 的值 ＋ 属性名称__

有一个小技巧是加上 `[]`，而不用传入 `index: address` 选项，上面的例子等同于：

```erb
<%= fields_for 'person[address][primary][]', address do |address_form| %>
  <%= address_form.text_field :city %>
<% end %>
```

# 8. 给外部的 resource 使用的表单

如果需要将数据 POST 到外部的 resource，通常外部的 resource 会给你一个 token，可以用 `form_tag` 加入这个选项：

```erb
<%= form_tag 'http://farfar.away/form', authenticity_token: 'external_t​​oken') do %>
  Form contents
<% end %>
```

有时候当送出数据到外部资源时，比如说付款吧，可以有个 field 是受外部的 API 限制，需要把隐藏的 `authenticity_token` 关掉，只消将其设成 `false` 即可：

```erb
<%= form_tag 'http://farfar.away/form', authenticity_token: false) do %>
  Form contents
<% end %>
```

`form_for` 也是一样：

```erb
<%= form_for @invoice, url: external_url, authenticity_token: 'external_t​​oken' do |f| %>
  Form contents
<% end %>
```

关掉 `authenticity_token`：

```erb
<%= form_for @invoice, url: external_url, authenticity_token: false do |f| %>
  Form contents
<% end %>
```

# 9. 打造复杂的表单

许多应用程序需要复杂的表单。举例来说，创造一个 `Person`，你可能想让使用者，使用者可填地址，用同个表单填多组地址（家里地址、单位地址、老家地址...等）而之后 `Person` 编辑个人数据的时候要可以新增、修改或取消已输入的地址。

## 9.1 设​​定 Model

Active Record 在 model 层级提供了 `accepts_nested_attributes_for` 方法：

```ruby
class Person < ActiveRecord::Base
  has_many :addresses
  accepts_nested_attributes_for :addresses
end

class Address < ActiveRecord::Base
  belongs_to :person
end
```

这给 `Person` 创建了一个 `addresses_attributes=` 方法，让你可 `create`、`update` 及（选择性） `destroy` 地址。也就是通过 `Person` 来操纵 `Address` Model。

## 9.2 制作表单

下面这个表单让使用者（`Person`）可以填多组地址：

```html+erb
<%= form_for @person do |f| %>
  Addresses:
  <ul>
    <%= f.fields_for :addresses do |addresses_form| %>
      <li>
        <%= addresses_form.label :kind %>
        <%= addresses_form.text_field :kind %>

        <%= addresses_form.label :street %>
        <%= addresses_form.text_field :street %>
        ...
      </li>
    <% end %>
  </ul>
<% end %>
```

当 `Person` 声明了 `accepts_nested_attributes_for`，`fields_for` 会给关联 Model 里的每个元素都渲染一次；也就是说，假设 `Person` 有 2 组地址：

```ruby
def new
  @person = Person.new
  2.times { @person.addresses.build}
end
```

`fields_for` 会为 2 组地址的每个栏位都渲染一次。

有两组地址的使用者，表单送出的参数看起来会像是：

```ruby
{
  'person' => {
    'name' => 'John Doe',
    'addresses_attributes' => {
      '0' => {
        'kind' => 'Home',
        'street' => '221b Baker Street'
      },
      '1' => {
        'kind' => 'Office',
        'street' => '31 Spooner Street'
      }
    }
  }
}
```

`:addresses_attributes` hash 的键不重要，只要每个地址的键不同即可。

如果地址已经储存了，​​`fields_for` 自动生成一个隐藏的 `input`，有已存 record 的 `id`。可以让 `fields_for` 不要自动生成，给入一个 `include_id: false` 即可。

## 9.3 控制器层面

通常需要在传给 model 之前，要在 controller 设定 [参数的白名单](action_controller_overview.html#strong-parameters)

```ruby
def create
  @person = Person.new(person_params)
  # ...
end

private
  def person_params
    params.require(:person).permit(:name, addresses_attributes: [:id, :kind, :street])
  end
```

### 9.4 移除对象

可以允许 `Person` 删除 `Address`，通过传入 `allow_destroy: true` 选项给 `accepts_nested_attributes_for`：

```ruby
class Person < ActiveRecord::Base
  has_many :addresses
  accepts_nested_attributes_for :addresses, allow_destroy: true
end
```

当 `_destroy` 为 `1` 或 `true` 时，对象会被销毁。

用来移除地址的表单这么写：

```erb
<%= form_for @person do |f| %>
  Addresses:
  <ul>
    <%= f.fields_for :addresses do |addresses_form| %>
      <li>
        <%= check_box :_destroy%>
        <%= addresses_form.label :kind %>
        <%= addresses_form.text_field :kind %>
        ...
      </li>
    <% end %>
  </ul>
<% end %>
```

别忘了给 controller 的 Strong Parameter 加上 `_destroy`：

```ruby
def person_params
  params.require(:person).
    permit(:name, addresses_attributes: [:id, :kind, :street, :_destroy])
end
```

### 9.5 避免有空的 Record

比如有三组地址，有一组使用者没有输入，要忽略没有输入的表单，加入 `:reject_if` 选项至 `accepts_nested_attributes_for`。 `reject_if:` 所给入的 `lambda` 返回假时，Active Record 不会把相关联的对象 build 出来给 hash。下面的例子当 `kind` 属性有输入时，才会新增一组地址。

```ruby
class Person < ActiveRecord::Base
  has_many :addresses
  accepts_nested_attributes_for :addresses, reject_if: lambda {|attributes| attributes['kind'].blank?}
end
```

也可以用 `:all_blank` 选项，在所有 attributes 为空时，不会储存这个 rec​​ord。

### 9.6 动态加入 Fields

与其一开始就渲染多组地址，不如加入一个按钮 `Add new address`，让使用者自己决定何时要新增一组地址，不是比较好吗？但 Rails 不支援这个功能。用 JavaScript 轮询来实现是一个常见的​​解决办法。

# 表单相关的 RubyGems

最多人使用的是这两个 RubyGem，

[formtastic](https://github.com/justinfrench/formtastic)

[simple_form](https://github.com/plataformatec/simple_form)

差别可看这里 [How do Formtastic and simple_form compare? - Stack Overflow](http://stackoverflow.com/questions/7510760/how-do-formtastic-and-simple-form-compare)

其它制作表单的 Gems 可参考: [Form Builders | The Ruby Toolbox](https://www.ruby-too​​lbox.com/categories/rails_form_builders)

# 延伸阅读

* [Form Helpers — Ruby on Rails Guides][fh]

* [Ruby on Rails 实战圣经| ActionView Helpers 辅助方法](http://ihower.tw/rails3/actionview-helpers.html)

关于嵌套表单可參考 [Railscasts #196 (Pro)](http://railscasts.com/episodes/196-nested-model-form-revised)。

[fh]: http://edgeguides.rubyonrails.org/form_helpers.html