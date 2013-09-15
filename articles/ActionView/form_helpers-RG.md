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