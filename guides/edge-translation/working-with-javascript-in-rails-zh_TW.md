Rails 與 JavaScript
================================

__特別要強調的翻譯名詞__

> Web application 應用程式。

> Request 請求。

本篇介紹 Rails 內建的 Ajax/JavaScript 功能。讓你輕鬆打造豐富生動的 Ajax 應用程式。

讀完你可能會學到...

* Ajax 的基礎。
* Unobtrusive JavaScript (via jQuery-ujs)。
* 如何使用 Rails 內建的 Helpers。
* 在伺服器端處理 Ajax。
* Turbolinks。

-------------------------------------------------------------------------------

Ajax 介紹
------------------------

為了要理解 Ajax，首先要了解瀏覽器平常如何運作。

當你在瀏覽器網址欄輸入 `http://localhost:3000`，並按下前往。瀏覽器（“Client”）向伺服器發送請求（Request）。伺服器接受 Request，去拿所有需要的資源（assets）給你，像是 js、css、圖片等，將這些資源組合成網頁，再返回給你（Response）。在網頁裡按下某個連結，重複這個步驟：發送請求、抓取資源、組合頁面、返回結果。這通常叫做 “Request Response Cycle”。

JavaScript 也可以當作 Client。向 Server 發送請求，並解析 Response，來更新網頁。JavaScript 的熟手可寫出只更新部分頁面的 JavaScript 程式，並只從伺服器拿需要的資料即可（不浪費）。

__這個技術叫做 Ajax。__

Rails 出廠內建 CoffeeScript，故以下的例子皆以 CoffeeScript 撰寫。這些例子當然也可用純 JavaScript 寫出來。

用 jQuery 發送 Ajax 請求的例子：

```coffeescript
$.ajax(url: "/test").done (html) ->
  $("#results").append html
```

這段程式從 `/test` 獲取資料，並將資料附加在 `id` 為 `#results` 的元素後。

上面的技巧 Rails 提供了許多的官方支援。很少會需要自己寫這樣的程式。以下章節將示範 Rails 如何用簡單的技術幫助你寫出這樣的網站，

Unobtrusive JavaScript
-------------------------------------

Rails 運用一種叫做 “Unobtrusive JavaScript” 的技術來處理 DOM 操作。這是前端社群的最佳實踐，但有些教學文件可能會用別種技術來達成同樣的事情。

以下是寫 JavaScript 最簡單的方式（行內 JavaScript）：

```html
<a href="#" onclick="this.style.backgroundColor='#990000'">Paint it red</a>
```

按下連結，背景就變紅。但要是我們有許多 JavaScript 程式要在按下時執行怎麼辦？lick?

```html
<a href="#" onclick="this.style.backgroundColor='#009900';this.style.color='#FFFFFF';">Paint it green</a>
```

尷尬吧？我們可以將 JavaScript 抽離出來，並用 CoffeeScript 改寫：

```coffeescript
paintIt = (element, backgroundColor, textColor) ->
  element.style.backgroundColor = backgroundColor
  if textColor?
    element.style.color = textColor
```

接著在頁面上：

```html
<a href="#" onclick="paintIt(this, '#990000')">Paint it red</a>
```

看起來好一點了，但多個連結都要有同樣的效果呢？

```html
<a href="#" onclick="paintIt(this, '#990000')">Paint it red</a>
<a href="#" onclick="paintIt(this, '#009900', '#FFFFFF')">Paint it green</a>
<a href="#" onclick="paintIt(this, '#000099', '#FFFFFF')">Paint it blue</a>
```

不是很漂亮，很冗餘。可以使用事件來簡化。給每個連結加上 `data-*` 屬性，接著給每個連結的 click 事件綁上 handler 來處理：

```coffeescript
paintIt = (element, backgroundColor, textColor) ->
  element.style.backgroundColor = backgroundColor
  if textColor?
    element.style.color = textColor

$ ->
  $("a[data-background-color]").click ->
    backgroundColor = $(this).data("background-color")
    textColor = $(this).data("text-color")
    paintIt(this, backgroundColor, textColor)
```
```html
<a href="#" data-background-color="#990000">Paint it red</a>
<a href="#" data-background-color="#009900" data-text-color="#FFFFFF">Paint it green</a>
<a href="#" data-background-color="#000099" data-text-color="#FFFFFF">Paint it blue</a>
```

我們將這個技術稱為 “unobtrusive” JavaScript 因為我們不再需要把 JavaScript 與 HTML 混在一起。如此一來之後更容易修改，也更容易加新功能上去，只消加個新的 `data-` attribute。JavaScript 與 HTML 分開便可用 JavaScript 壓縮工具來壓縮程式碼，

Rails 團隊強烈建議你用這種風格來撰寫 CoffeeScript (JavaScript)。

內建的 Ajax Helpers
----------------------

Rails 在 View 提供了許多用 Ruby 寫的 Helper 方法來幫你產生 HTML。有時候會想在這些元素加上 Ajax，沒問題，Rails 會幫助你。

Rails 的 “Ajax Helpers” 實際上分成 JavaScript 與 Ruby 寫成的 Helpers。

用 JavaScript 寫的可以在這找到 [rails.js][rails-js]

### form_for

[`form_for`][form_for]

撰寫表單。接受一個 `:remote` 選項：

```erb
<%= form_for(@post, remote: true) do |f| %>
  ...
<% end %>
```

會產生出：

```html
<form accept-charset="UTF-8" action="/posts" class="new_post" data-remote="true" id="new_post" method="post">
  ...
</form>
```

注意 `data-remote="true"`。有了這個 attribute 後，表單會透過 Ajax 提交，而不是平常瀏覽器的提交機制。

提交成功與失敗可以透過 `ajax:success` 與 `ajax:error` 事件來附加內容至 DOM：

```coffeescript
$(document).ready ->
  $("#new_post").on("ajax:success", (e, data, status, xhr) ->
    $("#new_post").append xhr.responseText
  ).bind "ajax:error", (e, xhr, status, error) ->
    $("#new_post").append "<p>ERROR</p>"
```

當然這只是個開始，更多可用的事件可在 [jQuery-ujs 的維基頁面][jquery-ujs-wiki]上可找到。

### form_tag

[`form_tag`][form_tag]

跟 `form_for` 非常類似，接受 `:remote` 選項：

```erb
<%= form_tag('/posts', remote: true) %>
```

會產生

```html
<form accept-charset="UTF-8" action="/posts" data-remote="true" method="post">
  ...
</form>
```

### link_to

[`link_to`][link_to]

產生連結。接受一個 `:remote` 選項：

```erb
<%= link_to "a post", @post, remote: true %>
```

會產生

```html
<a href="/posts/1" data-remote="true">a post</a>
```

You can bind to the same Ajax events as `form_for`. Here's an example. Let's
assume that we have a list of posts that can be deleted with just one
click. We would generate some HTML like this:

```erb
<%= link_to "Delete post", @post, remote: true, method: :delete %>
```

and write some CoffeeScript like this:

```coffeescript
$ ->
  $("a[data-remote]").on "ajax:success", (e, data, status, xhr) ->
    alert "The post was deleted."
```

### button_to

[`button_to`][button_to]

建立按鈕。接受一個 `:remote` 選項：

```erb
<%= button_to "A post", @post, remote: true %>
```

會產生：

```html
<form action="/posts/1" class="button_to" data-remote="true" method="post">
  <div>
    <input type="submit" value="A post">
    <input name="authenticity_token" type="hidden" value="PVXViXMJCLd717CYN5Ty7/gTLF3iaqPhL33FTeBmoVk=">
  </div>
</form>
```

伺服器端的考量
--------------------

Ajax 不只是 Client-side 的事，伺服器也要出力。人們傾向 Ajax requests 返回 JSON 而不是 HTML，讓我們看看如何返回 JSON。

### 簡單的例子

想像你有許多用戶，你想給他們顯示建立新用戶的表單：。Controller 的 `index` action：

```ruby
class UsersController < ApplicationController
  def index
    @users = User.all
    @user = User.new
  end
  # ...
```

`index` view (`app/views/users/index.html.erb`)：

```erb
<b>Users</b>

<ul id="users">
<%= render @users %>
</ul>

<br>

<%= form_for(@user, remote: true) do |f| %>
  <%= f.label :name %><br>
  <%= f.text_field :name %>
  <%= f.submit %>
<% end %>
```

`app/views/users/_user.html.erb` partial：

```erb
<li><%= user.name %></li>
```

index 頁面上半部列出用戶，下半部提供新建用戶的表單。

下面的表單會呼叫 Users Controller 的 `create` action。因為表單有 `remote: true` 這個選項，Request 會使用 Ajax Post 到 Users Controller，要求 JavaScript。處理這個 Request 的 `create` action：

```ruby
  # app/controllers/users_controller.rb
  # ......
  def create
    @user = User.new(params[:user])

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: 'User was successfully created.' }
        format.js   {}
        format.json { render json: @user, status: :created, location: @user }
      else
        format.html { render action: "new" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end
```

注意 `respond_to` 區塊內的 `format.js`，這是 Cotroller 回應 Ajax Request 的地方。`create` action 對應 `app/views/users/create.js.erb`：

```erb
$("<%= escape_javascript(render @user) %>").appendTo("#users");
```

Turbolinks
-------------

Rails 4 出廠內建 [Turbolinks Gem](https://github.com/rails/turbolinks)。

這個 Gem 使用了 Ajax 技術，來加速頁面的渲染。

### Turbolinks 工作原理

Turbolinks 給頁面上所有的 `a` 標籤添加了一個 click handler。如果瀏覽器支援 [PushState][ps]，Turbolinks 會利用 PushState 來改變 URL，發送 Ajax 請求，替換 `<body>` 的內容。

啟用 Turbolinks 只需在 `Gemfile` 加入：

```ruby
gem 'turbolinks'
```

並在 CoffeeScript Manifest 檔案（`app/assets/javascripts/application.js`）裡加入：

```coffeescript
//= require turbolinks
```

要給某些 link 禁用 Turbolinks，給該標籤加上 `data-no-turbolink` attribute 即可：

```html
<a href="..." data-no-turbolink>No turbolinks here</a>.
```

### 頁面變化的事件

撰寫 CoffeeScript 時，通常會想在頁面加載時做某些處理，搭配 jQuery，通常會寫出像是下面的程式碼：

```coffeescript
$(document).ready ->
  alert "page has loaded!"
```

而 Turbolinks 覆寫了頁面加載邏輯，依賴 `$(document).ready` 的程式碼不會被執行。必須改寫成：

```coffeescript
$(document).on "page:change", ->
  alert "page has loaded!"
```

關於更多細節，其他你可以綁定的事件等，參考 [Turbolinks 的 README](https://github.com/rails/turbolinks/blob/master/README.md)。

譯者推薦
-----------

推薦閱讀 [@Rei](https://twitter.com/chloerei) 所寫的 [Rails 3.2 的 Ajax 嚮導][rails-3-2-ajax-by-rei]。

其他資源
-----------------

了解更多相關內容，請參考以下連結：

* [jquery-ujs wiki](https://github.com/rails/jquery-ujs/wiki)
* [jquery-ujs list of external articles](https://github.com/rails/jquery-ujs/wiki/External-articles)
* [Rails 3 Remote Links and Forms: A Definitive Guide](http://www.alfajango.com/blog/rails-3-remote-links-and-forms/)
* [Railscasts: Unobtrusive JavaScript](http://railscasts.com/episodes/205-unobtrusive-javascript)
* [Railscasts: Turbolinks](http://railscasts.com/episodes/390-turbolinks)

[jquery-ujs-wiki]: https://github.com/rails/jquery-ujs/wiki/ajax
[ps]: https://developer.mozilla.org/en-US/docs/DOM/Manipulating_the_browser_history#The_pushState(\).C2.A0method
[rails-js]: https://github.com/rails/jquery-ujs/blob/master/src/rails.js
[form_for]: http://edgeapi.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-form_for
[form_tag]: http://edgeapi.rubyonrails.org/classes/ActionView/Helpers/FormTagHelper.html#method-i-form_tag
[link_to]: http://edgeapi.rubyonrails.org/classes/ActionView/Helpers/UrlHelper.html#method-i-link_to
[button_to]: http://edgeapi.rubyonrails.org/classes/ActionView/Helpers/UrlHelper.html#method-i-button_to

[rails-3-2-ajax-by-rei]: http://chloerei.com/2012/04/21/rails-3-2-ajax-guide/