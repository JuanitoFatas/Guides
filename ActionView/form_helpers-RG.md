# Form Helpers

表單是給使用者輸入的介面，web application 裡面最基礎的元素之一。表單寫起來很繁瑣，Rails 提供很多有用的 helper 讓你快速製造出不同需求的表單。

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

注意到 HTML 裡有個額外的 `div` 元素，裡面有兩個 input。第一個 input 讓瀏覽器使用 `utf8`。第二個 input Rails 內建用來防止 __CSRF (cross-site request forgery protection)__ 攻擊的安全機制，每個非 GET 的表單，Rails 都會幫你產生一個這樣的 `authenticity_token`。

# 2. 處理 Model 物件

# 3. 輕鬆製作下拉選單

# 4. 使用日期與時間的 Form Helpers

# 5. 上傳檔案

# 6. 客製化 Form Builders

# 7. 了解參數的命名規範

# 8. 給外部 resource 使用的 Form

# 9. 打造複雜的表單

# 延伸閱讀

* [Form Helpers — Ruby on Rails Guides](http://edgeguides.rubyonrails.org/form_helpers.html)

* [Ruby on Rails 實戰聖經 | ActionView Helpers 輔助方法](http://ihower.tw/rails3/actionview-helpers.html)

