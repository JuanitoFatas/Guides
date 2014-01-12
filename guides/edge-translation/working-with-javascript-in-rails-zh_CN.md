Rails x JavaScript
================================

__特别要强调的翻译名词__

> Web application 应用程序<br>
> Request 请求<br>
> Vanilla JavaScript 纯 JavaScript

本篇介绍 Rails 自带的 Ajax/JavaScript 功能。让你轻松打造丰富生动的 Ajax 应用程序。

读完你可能会学到...

* Ajax 的基础。
* Unobtrusive JavaScript (via jQuery-ujs)。
* 如何使用 Rails 内建的 Helpers。
* 在服务器端处理 Ajax。
* Turbolinks。

目录
------

  - [1. Ajax 介绍](#ajax-介绍)
  - [2. Unobtrusive JavaScript](#unobtrusive-javascript)
  - [3. 自带的 Ajax Helpers](#自带的-ajax-helpers)
    - [3.1 form_for](#form_for)
    - [3.2 form_tag](#form_tag)
    - [3.3 link_to](#link_to)
    - [3.4 button_to](#button_to)
  - [4. 服务器端的考量](#服务器端的考量)
    - [简单的例子](#简单的例子)
  - [5. Turbolinks](#turbolinks)
    - [Turbolinks 工作原理](#turbolinks-工作原理)
    - [页面变化的事件](#页面变化的事件)
  - [6. 其他资源](#其他资源)

Ajax 介绍
------------------------

为了要理解 Ajax，首先要了解浏览器平常的工作原理。

当你在浏览器网址栏输入 `http://localhost:3000`，并按下回车。浏览器此时（Client）便向服务器发送请求。服务器接受 Request，去拿所有需要的资源（assets）给你，像是 js、css、图片等，接著将这些资源按照程序逻辑组合成网页，再响应给你（Response）。

如果你在网页里按下某个连结，将会重复刚刚的步骤：发送请求、抓取资源、组合页面、返回结果。这几个步骤通常称之为 “Request Response Cycle”。

JavaScript 也可向服务器发送请求或是解析 Response。JavaScript 也具有更新网页的能力。熟悉 JavaScript 的开发者可以做到只更新部分的页面，而无需向服务器请求整个页面。

__这个强大的技术叫做 Ajax。__

Rails 出厂内建 CoffeeScript，故以下的例子皆以 CoffeeScript 撰写。当然，这些例子也可用纯 JavaScript 写出来。

用 jQuery 发送 Ajax 请求的例子：

```coffeescript
$.ajax(url: "/test").done (html) ->
  $("#results").append html
```

这段程序从 `/test` 获取数据，并将数据附加在 `id` 为 `#results` 的元素之后。

Rails 对于使用这种技巧来撰写网页，提供了相当多的官方支援。几乎鲜少会需要自己编这样的程序。以下章节将示范，如何用点简单的技术，Rails 便能帮你写出应用了 Ajax 的网站。

Unobtrusive JavaScript
-------------------------------------

Rails 使用一种叫做 “[Unobtrusive JavaScript][ujs]” （缩写为 UJS）的技术来处理 DOM 操作。这是来自前端社群的最佳实践，但有些教学文件可能会用别种技术，来达成同样的事情。

以下是撰写 JavaScript 最简单的方式（行内 JavaScript）：

```html
<a href="#" onclick="this.style.backgroundColor='#990000'">Paint it red</a>
```

按下连结，背景就变红。但要是我们有许多 JavaScript 代码，要在按下时执行怎么办？

```html
<a href="#" onclick="this.style.backgroundColor='#009900';this.style.color='#FFFFFF';">Paint it green</a>
```

尴尬吧？我们可以将 JavaScript 抽离出来，并用 CoffeeScript 改写：

```coffeescript
paintIt = (element, backgroundColor, textColor) ->
  element.style.backgroundColor = backgroundColor
  if textColor?
    element.style.color = textColor
```

接著在页面上：

```html
<a href="#" onclick="paintIt(this, '#990000')">Paint it red</a>
```

看起来好一点了，但多个连结都要有同样的效果呢？

```html
<a href="#" onclick="paintIt(this, '#990000')">Paint it red</a>
<a href="#" onclick="paintIt(this, '#009900', '#FFFFFF')">Paint it green</a>
<a href="#" onclick="paintIt(this, '#000099', '#FFFFFF')">Paint it blue</a>
```

不是很漂亮，很冗赘。可以使用事件来简化。给每个连结加上 `data-*` 属性，接著给每个连结的 click 事件，加上一个 Handler：

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

我们将这个技术称为 “Unobtrusive” JavaScript。因为我们不再需要把 JavaScript 与 HTML 混在一起。之后便更容易修改，也更容易加新功能上去，只要加个 `data-` attribute。将 JavaScript 从 HTML 抽离后，JavaScript 便可透过合并压缩工具，让所有页面可以共用整份 JavaScript 。也就是说，只需在第一次戴入页面时下载一次，之后的页面使用快取的文件即可。

Rails 团队强烈建议你用这种风格来撰写 CoffeeScript (JavaScript)。

自带的 Ajax Helpers
----------------------

Rails 在 View 提供了许多用 Ruby 写的 Helper 方法来帮你生成 HTML。有时候会想在这些元素加上 Ajax，没问题，Rails 会帮助你。

Rails 的 “Ajax Helpers” 实际上分成 JavaScript 所写的 Helpers，与 Ruby 所写成的 Helpers。

用 JavaScript 写的可以在这找到 [rails.js][rails-js]。

### form_for

[`form_for`][form_for]

帮助你撰写表单的 Helper。接受一个 `:remote` 选项：

```erb
<%= form_for(@post, remote: true) do |f| %>
  ...
<% end %>
```

会生成出：

```html
<form accept-charset="UTF-8" action="/posts" class="new_post" data-remote="true" id="new_post" method="post">
  ...
</form>
```

注意 `data-remote="true"`。有了这个 attribute 之后，表单会透过 Ajax 提交，而不是浏览器平常的提交机制。

提交成功与失败可以透过 `ajax:success` 与 `ajax:error` 事件，来附加内容至 DOM：

```coffeescript
$(document).ready ->
  $("#new_post").on("ajax:success", (e, data, status, xhr) ->
    $("#new_post").append xhr.responseText
  ).bind "ajax:error", (e, xhr, status, error) ->
    $("#new_post").append "<p>ERROR</p>"
```

当然这只是个开始，更多可用的事件可在 [jQuery-ujs 的维基页面][jquery-ujs-wiki]上可找到。

### form_tag

[`form_tag`][form_tag]

跟 `form_for` 非常类似，接受 `:remote` 选项：

```erb
<%= form_tag('/posts', remote: true) %>
```

会生成

```html
<form accept-charset="UTF-8" action="/posts" data-remote="true" method="post">
  ...
</form>
```

### link_to

[`link_to`][link_to]

帮助你生成连结的 Helper。接受一个 `:remote` 选项：

```erb
<%= link_to "a post", @post, remote: true %>
```

会生成

```html
<a href="/posts/1" data-remote="true">a post</a>
```

你可以上面 `form_for` 例子那样，绑定相同的 Ajax 事件上去。 来看个例子，假设按个按键，删除一篇文章，提示一些讯息。只需写一些 HTML：

```erb
<%= link_to "Delete post", @post, remote: true, method: :delete %>
```

并写一点 CoffeeScript：

```coffeescript
$ ->
  $("a[data-remote]").on "ajax:success", (e, data, status, xhr) ->
    alert "The post was deleted."
```

就这么简单。

### button_to

[`button_to`][button_to]

建立按钮的 Helper。接受一个 `:remote` 选项：

```erb
<%= button_to "A post", @post, remote: true %>
```

会生成：

```html
<form action="/posts/1" class="button_to" data-remote="true" method="post">
  <div>
    <input type="submit" value="A post">
    <input name="authenticity_token" type="hidden" value="PVXViXMJCLd717CYN5Ty7/gTLF3iaqPhL33FTeBmoVk=">
  </div>
</form>
```

由于这只是个 `<form>`，所有 `form_for` 可用的东西，也可以应用在 `button_to`。

服务器端的考量
--------------------

Ajax 不只是 Client-side 的事，服务器也要出力。人们倾向 Ajax requests 返回 JSON，而不是 HTML，让我们看看如何返回 JSON。

### 简单的例子

想像你有许多用户，你想给他们显示建立新用户的表单。而 Controller 的 `index` action：

```ruby
class UsersController < ApplicationController
  def index
    @users = User.all
    @user = User.new
  end
  # ...
```

以及 `index` View (`app/views/users/index.html.erb`)：

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

`app/views/users/_user.html.erb` Partial：

```erb
<li><%= user.name %></li>
```

index 页面上半部列出用户，下半部提供新建用户的表单。

下面的表单会呼叫 Users Controller 的 `create` action。因为表单有 `remote: true` 这个选项，Request 会使用 Ajax Post 到 Users Controller，等待 Controller 回应 JavaScript。处理这个 Request 的 `create` action 会像是：

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

注意 `respond_to` 区块内的 `format.js`，这是 Cotroller 回应 Ajax Request 的地方。`create` action 对应 `app/views/users/create.js.erb`：

```erb
$("<%= escape_javascript(render @user) %>").appendTo("#users");
```

Turbolinks
-------------

Rails 4 出厂内建 [Turbolinks Gem](https://github.com/rails/turbolinks)。

这个 Gem 使用了 Ajax 技术，可以加速页面的渲染。

### Turbolinks 工作原理

Turbolinks 给页面上所有的 `a` 标籤添加了一个 click handler。如果浏览器支援 [PushState][ps]，Turbolinks 会利用 PushState 来改变 URL，发送 Ajax 请求，替换 `<body>` 的内容。

启用 Turbolinks 只需在 `Gemfile` 加入：

```ruby
gem 'turbolinks'
```

并在 CoffeeScript Manifest 文件（`app/assets/javascripts/application.js`）里加入：

```coffeescript
//= require turbolinks
```

要给某些 link 禁用 Turbolinks，给该标籤加上 `data-no-turbolink` attribute 即可：

```html
<a href="..." data-no-turbolink>No turbolinks here</a>.
```

### 页面变化的事件

撰写 CoffeeScript 时，通常会想在页面加载时做某些处理，搭配 jQuery，通常会写出像是下面的代码：

```coffeescript
$(document).ready ->
  alert "page has loaded!"
```

而 Turbolinks 覆写了页面加载逻辑，依赖 `$(document).ready` 的代码不会被执行。必须改写成：

```coffeescript
$(document).on "page:change", ->
  alert "page has loaded!"
```

关于更多细节，其他可以绑定的事件等，参考 [Turbolinks 的 README](https://github.com/rails/turbolinks/blob/master/README.md)。

其他资源
-----------------

中文推荐阅读 [@Rei](https://twitter.com/chloerei) 所写的 [Rails 3.2 的 Ajax 向导][rails-3-2-ajax-by-rei]。

了解更多相关内容，请参考以下连结：

* [jquery-ujs wiki](https://github.com/rails/jquery-ujs/wiki)
* [jquery-ujs list of external articles](https://github.com/rails/jquery-ujs/wiki/External-articles)
* [Rails 3 Remote Links and Forms: A Definitive Guide](http://www.alfajango.com/blog/rails-3-remote-links-and-forms/)
* [Railscasts: Unobtrusive JavaScript](http://railscasts.com/episodes/205-unobtrusive-javascript)
* [Railscasts: Turbolinks](http://railscasts.com/episodes/390-turbolinks)

[jquery-ujs-wiki]: https://github.com/rails/jquery-ujs/wiki/ajax
[ps]: https://developer.mozilla.org/en-US/docs/DOM/Manipulating_the_browser_history#The_pushState(\).C2.A0method
[rails-js]: https://github.com/rails/jquery-ujs/blob/master/src/rails.js
[form_for]: http://api.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-form_for
[form_tag]: http://api.rubyonrails.org/classes/ActionView/Helpers/FormTagHelper.html#method-i-form_tag
[link_to]: http://api.rubyonrails.org/classes/ActionView/Helpers/UrlHelper.html#method-i-link_to
[button_to]: http://api.rubyonrails.org/classes/ActionView/Helpers/UrlHelper.html#method-i-button_to
[ujs]: http://zh.wikipedia.org/zh-cn/Unobtrusive_JavaScript

[rails-3-2-ajax-by-rei]: http://chloerei.com/2012/04/21/rails-3-2-ajax-guide/
