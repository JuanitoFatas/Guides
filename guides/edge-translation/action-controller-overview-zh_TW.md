Action Controller 概覽
==========================

__特別要強調的翻譯名詞__

> application 應用程式 <br>
> Parameters 參數 <br>
> Client 客戶端

本篇介紹 Controller 的工作原理、Controller 如何與應用程式的 Request 生命週期結合在一起。

讀完本篇可能會學到.....

* Request 進到 Controller 的流程。
* 限制傳入 Controller 的參數。
* 資料存在 Session 或 Cookie 裡的應用場景。
* 如何在處理 Request 時，使用 Filters 來附加行為。
* 如何使用 Action Controller 內建的 HTTP 驗證機制。
* 如何用串流方式將資料傳給使用者。
* 如何過濾應用程式 Log 裡的敏感資料。
* 如何在 Request 生命週期裡，處理可能拋出的異常。

----------------------------------------------------------------

1. Controller 做了什麼？
--------------------------

Action Controller 是 MVC 的 C，Controller。一個 Request 進來，路由決定是那個 Controller 的工作後，便把工作指派給 Controller，Controller 負責處理該 Request，給出對應的 Output。幸運的是，Action Controller 把大部分的苦差事都給您辦好了，您只需按照一些規範來寫代碼，事情便豁然開朗。

對多數按照 [RESTful](http://en.wikipedia.org/wiki/Representational_state_transfer) 規範來編寫的應用程式來說，Controller 的工作便是接收 Request，按照 Request 的請求，去 Model 取或寫資料，並將資料交給 View，來產生出 HTML。

Controller 因此可以想成是 Model 與 View 的中間人。負責替 Model 將資料傳給 View，讓 View 可以顯示資料給使用者。Controller 也將使用者更新或儲存的資料，存回 Model。

路由過程的細節可以查閱 [Rails Routing From the Outside In](http://edgeguides.rubyonrails.org/routing.html)。

2. Controller 命名慣例
-----------------------

Rails Controller 的命名慣例是以**複數形式結尾**，但也是有例外，比如 `ApplicationController`。舉例來說：

偏好 `ClientsController` 勝過 `ClientController`。

偏好 `SiteAdminsController` 勝過 `SitesAdminsController`。

遵循慣例便可享受內建 Rails Router 的功能，如：`resources`、`resource` 等，而無需特地修飾 `:path`、`controller`，便可保持 URL 與 path Helpers 的一致性。更多詳情請參考 [Layouts & Rendering Guide](/guides/edge/layouts_and_rendering.md) 一篇。

注意：Controller 的命名慣例與 Model 的命名慣例不同，Model 命名慣例是**單數形式**。

3. Methods 與 Actions
-------------------------

Controller 繼承自 `ApplicationController`，但 Controller 其實與普通的 Ruby Class 一樣，都擁有 methods。當應用程式收到 Request 時，Router 會決定這要交給那個 Controller 的那個 Action 來處理，接著 Rails 實例化出該 Controller 的 instance，呼叫與 Action 名稱相同的 Method。

```ruby
class ClientsController < ApplicationController
  def new
  end
end
```

假設使用者跑去 `/clients/new`，想要新增 `client`，Rails 實例化 `ClientsController` 的 instance，並呼叫 `new` 來處理。注意 `new` 雖沒有內容，但 Rails 預設行為會 `render` `new.html.erb`。

先前提過 Controller 可從 Model 取資料，再拿給 View，該怎麼做呢？

```ruby
def new
  @client = Client.new
end
```

只要在與 View 對應的 action 裡，將資料取出放至 instance 變數，如此一來便可在 View 裡取用 `@client`。

詳情請參考 [Layouts & Rendering Guide](layouts_and_rendering.html) 一篇。

`ApplicationController` 繼承自 `ActionController::Base`，`ActionController::Base` 定義了許多有用的 Methods。本篇會提到一些，若是好奇定義了些什麼方法，可參考 [ActionController::Base 的 API 文件](http://edgeapi.rubyonrails.org/classes/ActionController/Base.html)，或是閱讀 [ActionController::Base 的原始碼](https://github.com/rails/rails/blob/master/actionpack/lib/action_controller/base.rb)。

只有公有方法可以被外部作為 `action` 呼叫。所以輔助方法、Filter 方法，最好藏在 `protected` 或 `private` 裡。

4. 參數
------------

通常會想在 Controller 裡，存取由使用者傳入的資料，或是其他的參數。Web 應用程式有兩種參數。第一種是由 URL 的部份組成，這種叫做 “query string parameters”。Query string 是 URL `?` 後面的任何字串，通常是透過 HTTP `GET` 傳遞。第二種參數是 “POST data”，透過 HTTP `POST` 傳遞，故得名 “POST data”。這通常是使用者從表單填入的訊息。叫做 POST data 的原因是，這種參數只能作為 HTTP POST Request 的一部分來傳遞。Rails 並不區分 Query String Parameter 或 POST Parameter，兩者皆可在 Controller 裡取用，從 `params` hash 裡取出：

```ruby
class ClientsController < ApplicationController
  # This action uses query string parameters because it gets run
  # by an HTTP GET request, but this does not make any difference
  # to the way in which the parameters are accessed. The URL for
  # this action would look like this in order to list activated
  # clients: /clients?status=activated
  def index
    if params[:status] == "activated"
      @clients = Client.activated
    else
      @clients = Client.inactivated
    end
  end

  # This action uses POST parameters. They are most likely coming
  # from an HTML form which the user has submitted. The URL for
  # this RESTful request will be "/clients", and the data will be
  # sent as part of the request body.
  def create
    @client = Client.new(params[:client])
    if @client.save
      redirect_to @client
    else
      # This line overrides the default rendering behavior, which
      # would have been to render the "create" view.
      render "new"
    end
  end
end
```

### Hash 與 Array 參數

`params` Hash 不侷限於一維的 Hash，可以是巢狀結構；或是 Hash 裡面包有陣列，都可以。

若是想要以陣列形式傳遞參數，在 key 的名稱後方附加 `[]` 即可，如下所示：

```
GET /clients?ids[]=1&ids[]=2&ids[]=3
```

注意：上例 URL 會編碼為 `"/clients?ids%5B%5D=1&ids%5B%5D=2&ids%5B%5D=3"`，因為 `[]` 對 URL 來說是非法字元。多數情況下，瀏覽器會處理字元合法與否的問題，自動將非法字元做編碼。Rails 收到時會自己解碼。但當你要手動將 Request 發給 Server 時，要記得自己處理好這件事。

`params[:ids]` 現在會是 `["1", "2", "3"]`。注意參數的值永遠是 String。Rails 不會試著去臆測或是轉換類型。

要送出 Hash 形式的參數，在中括號裡聲明 Hash 與 key 的名稱：

```html
<form accept-charset="UTF-8" action="/clients" method="post">
  <input type="text" name="client[name]" value="Acme" />
  <input type="text" name="client[phone]" value="12345" />
  <input type="text" name="client[address][postcode]" value="12345" />
  <input type="text" name="client[address][city]" value="Carrot City" />
</form>
```

這個表單送出時，`params[:client]` 的數值會是 `{ "name" => "Acme", "phone" => "12345", "address" => { "postcode" => "12345", "city" => "Carrot City" } }`

注意 `params[:client][:address]` 是巢狀結構。

`params` Hash 其實是 `ActiveSupport::HashWithIndifferentAccess` 的 instance，`ActiveSupport::HashWithIndifferentAccess` 與一般 Hash 相同，不同的是取出 Hash 的值時，key 可以用字串與符號：`params[:foo]` 等同於 `params["foo"]`。

### JSON 參數

在撰寫 Web Service 的應用程式時，通常會需要處理 JSON 格式的參數。若 Request 的 `"Content-Type"` header 是 `"application/json"`，Rails 會自動將收到的 JSON 參數轉換好（將 JSON 轉成 Ruby 的 Hash），存至 `params` 裡。

送出的 JSON

```json
{ "company": { "name": "acme", "address": "123 Carrot Street" } }
```

進來的資料

```ruby
params[:company] => { "name" => "acme", "address" => "123 Carrot Street" }
```

除此之外，如果開啟了 `config.wrap_parameters` 選項，或是在 Controller 呼叫了 `wrap_parameters`，可以忽略掉 JSON 參數的 Root element，即 JSON 參數的內容會被拷貝到 `params` 裡，並有著對應的 key：

送出的 JSON

```json
{ "name": "acme", "address": "123 Carrot Street" }
```

傳給 `CompaniesController` 時，會自動推測出 Hash 名稱，放在 `:company` key 裡：

```ruby
{ name: "acme", address: "123 Carrot Street", company: { name: "acme", address: "123 Carrot Street" } }
```

關於如何客製化 key 名稱，或針對某些特殊的參數執行 `wrap_parameters`，請查閱 [ActionController::ParamsWrapper 的 API 文件](http://edgeapi.rubyonrails.org/classes/ActionController/ParamsWrapper.html)。

**解析 XML 的功能現已抽成 [actionpack-xml_parser](https://github.com/rails/actionpack-xml_parser) Gem。**

### Routing 參數

`params` Hash 永遠會有兩個 key：`:controller` 與 `:action`，分別是當下呼叫的 Controller，與 Action 的名稱。若想知道現在的 Controller 以及 Action 名稱時，請使用 `controller_name` 與 `action_name`，不要直接從 `params` 裡取：

```ruby
controller.controller_name %>
controller.action_name %>
```

路由定義裡的參數也會放在 `params` 裡，像是 `:id`。

假設有一張 `Client` 的清單，`Client 有兩種狀態，分別為 Active 與 Inactive。我們可以加入一條路由，來捕捉 `Client` 的狀態：

```ruby
get '/clients/:status' => 'clients#index', foo: 'bar'
```

這個情況裡，當使用者打開 `/clients/active` 這一頁，`params[:status]` 會被設成 `"active"`，`params[:foo]` 也會被設成 `"bar"`，就像是我們從 query string 傳進去那樣。同樣的，`params[:action]` 也會被設成 `index`。

### `default_url_options`

可以為 URL 產生設定預設的參數，在 Controller 定義一個叫做 `default_url_options` 的方法。這個方法必須回傳期望的預設值，且 key 必須是 `Symbol`：

```ruby
class ApplicationController < ActionController::Base
  def default_url_options
    { locale: I18n.locale }
  end
end
```

這些選項會被作為預設的選項，用來傳給 `url_for`，但還是可以被覆寫掉。

如果你在 `ApplicationController` 定義 `default_url_options`，如上例，則產生所有 URL 的時候，都會傳入 `default_url_options` 內所定義的參數。`default_url_options` 也可以在特定的 Controller 裡定義，如此一來便只會影響與定義 `default_url_options` Controller 有關 URL 的產生。

### Strong Parameters

> 大量賦值 Mass Assignment

原先大量賦值是由 Active Model 來處理，透過白名單來過濾不可賦值的參數。有了 Strong Parameter 之後，這件工作由 Action Controller 處理。

這表示你會需要決定，哪些 attributes 允許做大量賦值。

In addition, parameters can be marked as required and flow through a
predefined raise/rescue flow to end up as a 400 Bad Request with no
effort.

```ruby
class PeopleController < ActionController::Base
  # This will raise an ActiveModel::ForbiddenAttributes exception
  # because it's using mass assignment without an explicit permit
  # step.
  def create
    Person.create(params[:person])
  end

  # This will pass with flying colors as long as there's a person key
  # in the parameters, otherwise it'll raise a
  # ActionController::ParameterMissing exception, which will get
  # caught by ActionController::Base and turned into that 400 Bad
  # Request reply.
  def update
    person = current_account.people.find(params[:id])
    person.update!(person_params)
    redirect_to person
  end

  private
    # Using a private method to encapsulate the permissible parameters
    # is just a good pattern since you'll be able to reuse the same
    # permit list between create and update. Also, you can specialize
    # this method with per-user checking of permissible attributes.
    def person_params
      params.require(:person).permit(:name, :age)
    end
end
```

#### Permitted Scalar Values

給定

```ruby
params.permit(:id)
```


the key `:id` will pass the whitelisting if it appears in `params` and
it has a permitted scalar value associated. Otherwise the key is going
to be filtered out, so arrays, hashes, or any other objects cannot be
injected.

The permitted scalar types are `String`, `Symbol`, `NilClass`,
`Numeric`, `TrueClass`, `FalseClass`, `Date`, `Time`, `DateTime`,
`StringIO`, `IO`, `ActionDispatch::Http::UploadedFile` and
`Rack::Test::UploadedFile`.

To declare that the value in `params` must be an array of permitted
scalar values map the key to an empty array:

```ruby
params.permit(id: [])
```

To whitelist an entire hash of parameters, the `permit!` method can be
used:

```ruby
params.require(:log_entry).permit!
```

This will mark the `:log_entry` parameters hash and any subhash of it
permitted. Extreme care should be taken when using `permit!` as it
will allow all current and future model attributes to be
mass-assigned.

#### Nested Parameters

巢狀參數的允許：

```ruby
params.permit(:name, { emails: [] },
              friends: [ :name,
                         { family: [ :name ], hobbies: [] }])
```

This declaration whitelists the `name`, `emails` and `friends`
attributes. It is expected that `emails` will be an array of permitted
scalar values and that `friends` will be an array of resources with
specific attributes : they should have a `name` attribute (any
permitted scalar values allowed), a `hobbies` attribute as an array of
permitted scalar values, and a `family` attribute which is restricted
to having a `name` (any permitted scalar values allowed, too).

#### 更多例子

You want to also use the permitted attributes in the `new`
action. This raises the problem that you can't use `require` on the
root key because normally it does not exist when calling `new`:

```ruby
# using `fetch` you can supply a default and use
# the Strong Parameters API from there.
params.fetch(:blog, {}).permit(:title, :author)
```

`accepts_nested_attributes_for` allows you to update and destroy
associated records. This is based on the `id` and `_destroy`
parameters:

```ruby
# permit :id and :_destroy
params.require(:author).permit(:name, books_attributes: [:title, :id, :_destroy])
```

Hashes with integer keys are treated differently and you can declare
the attributes as if they were direct children. You get these kinds of
parameters when you use `accepts_nested_attributes_for` in combination
with a `has_many` association:

```ruby
# To whitelist the following data:
# {"book" => {"title" => "Some Book",
#             "chapters_attributes" => { "1" => {"title" => "First Chapter"},
#                                        "2" => {"title" => "Second Chapter"}}}}

params.require(:book).permit(:title, chapters_attributes: [:title])
```

#### Outside the Scope of Strong Parameters

Strong Parameter API 不是銀彈，無法處理所有白名單的問題。但可以簡單地將 API 與你的程式碼混合使用，來因應不同的需求。

假想看看，你想要給某個 attribute 加上白名單，該 attribute 可以包含一個 Hash，裡面可能有任何 key。使用 Strong Parameter 你無法允許有任何 key 的 Hash，但你可以這麼做：

```ruby
def product_params
  params.require(:product).permit(:name, data: params[:product][:data].try(:keys))
end
```

5. Session
--------------------

應用程式為每個使用者都準備了一個 Session，可以儲存小量的資料，資料在 Request 之間都會保存下來。Session 僅在 Controller 與 View 可存取，有下列幾種儲存機制：

* `ActionDispatch::Session::CookieStore` ─ 資料存在用戶端。
* `ActionDispatch::Session::CacheStore` ─ 資料存在 Rails 的 Cache。
* `ActionDispatch::Session::ActiveRecordStore` ─ 資料使用 Active Record 存在資料庫（需要 `activerecord-session_store` RubyGem）。
* `ActionDispatch::Session::MemCacheStore` ─ 資料存在 memcached（這是遠古時代的實作方式，考慮改用 CacheStore 吧）。

所有的儲存機制，會為每個 Session 在 Cookie 裡存一個獨立的 ID。必須要存在 Cookie 裡，否則 Rails 不允許你在 URL 傳遞 session ID（不安全）。

For most stores, this ID is used to look up the session data on the server, e.g. in a database table. There is one exception, and that is the default and recommended session store - the CookieStore - which stores all session data in the cookie itself (the ID is still available to you if you need it). This has the advantage of being very lightweight and it requires zero setup in a new application in order to use the session. The cookie data is cryptographically signed to make it tamper-proof. And it is also encrypted so anyone with access to it can't read its contents. (Rails will not accept it if it has been edited).

The CookieStore can store around 4kB of data - much less than the others - but this is usually enough. Storing large amounts of data in the session is discouraged no matter which session store your application uses. You should especially avoid storing complex objects (anything other than basic Ruby objects, the most common example being model instances) in the session, as the server might not be able to reassemble them between requests, which will result in an error.

If your user sessions don't store critical data or don't need to be around for long periods (for instance if you just use the flash for messaging), you can consider using ActionDispatch::Session::CacheStore. This will store sessions using the cache implementation you have configured for your application. The advantage of this is that you can use your existing cache infrastructure for storing sessions without requiring any additional setup or administration. The downside, of course, is that the sessions will be ephemeral and could disappear at any time.

關於如何安全地儲存 Session，請閱讀 [Security Guide](/guides/edge/security.md)。

若是需要不同的 Session 儲存機制，可以在 `config/initializers/session_store.rb` 裡更改：

```ruby
# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails g active_record:session_migration")
# YourApp::Application.config.session_store :active_record_store
```

Rails sets up a session key (the name of the cookie) when signing the session data. These can also be changed in `config/initializers/session_store.rb`:

```ruby
# Be sure to restart your server when you modify this file.
YourApp::Application.config.session_store :cookie_store, key: '_your_app_session'
```

You can also pass a `:domain` key and specify the domain name for the cookie:

```ruby
# Be sure to restart your server when you modify this file.
YourApp::Application.config.session_store :cookie_store, key: '_your_app_session', domain: ".example.com"
```

Rails sets up (for the CookieStore) a secret key used for signing the session data. This can be changed in `config/initializers/secret_token.rb`

```ruby
# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
YourApp::Application.config.secret_key_base = '49d3f3de9ed86c74b94ad6bd0...'
```

NOTE: Changing the secret when using the `CookieStore` will invalidate all existing sessions.

### Accessing the Session

在 Controller 可以透過 `session` 這個 instance method 來存取 Session。


NOTE: Sessions are lazily loaded. If you don't access sessions in your action's code, they will not be loaded. Hence you will never need to disable sessions, just not accessing them will do the job.

Session values are stored using key/value pairs like a hash:

```ruby
class ApplicationController < ActionController::Base

  private

  # Finds the User with the ID stored in the session with the key
  # :current_user_id This is a common way to handle user login in
  # a Rails application; logging in sets the session value and
  # logging out removes it.
  def current_user
    @_current_user ||= session[:current_user_id] &&
      User.find_by(id: session[:current_user_id])
  end
end
```

要在 Session 裡存值，只要像使用 Hash 一樣操作即可：

```ruby
class LoginsController < ApplicationController
  # "Create" a login, aka "log the user in"
  def create
    if user = User.authenticate(params[:username], params[:password])
      # Save the user ID in the session so it can be used in
      # subsequent requests
      session[:current_user_id] = user.id
      redirect_to root_url
    end
  end
end
```

要從 Session 裡移掉數值，賦 `nil` 給想移除的 key 即可：

```ruby
class LoginsController < ApplicationController
  def destroy
    # 將 user id 從 session 裡移除
    @_current_user = session[:current_user_id] = nil
    redirect_to root_url
  end
end
```

要將整個 session 清掉，使用 `reset_session`。

### The Flash

Flash 是 Session 特殊的一部分，可以從一個 Request，傳遞訊息（錯誤、提示訊息）到下個 Request，下個 Request 結束後，便會清除 Flash。

`flash` 的使用方式與 `session` 雷同，跟操作一般的 Hash 一樣（實際上 `flash` 是 [FlashHash](http://edgeapi.rubyonrails.org/classes/ActionDispatch/Flash/FlashHash.html) 的 instance）。

用登出作為例子，Controller 可以傳一個訊息，用來給下個 Request 顯示：

```ruby
class LoginsController < ApplicationController
  def destroy
    session[:current_user_id] = nil
    flash[:notice] = "成功登出了"
    redirect_to root_url
  end
end
```

`destroy` action 轉向到應用程式的 `root_url`，並顯示 `"成功登出了"`。

`redirect_to` 也接受 flash 訊息參數：

```ruby
redirect_to root_url, notice: "You have successfully logged out."
redirect_to root_url, alert: "You're stuck here!"
redirect_to root_url, flash: { referral_code: 1234 }
```

The `destroy` action redirects to the application's `root_url`, where the message will be displayed. Note that it's entirely up to the next action to decide what, if anything, it will do with what the previous action put in the flash. It's conventional to display any error alerts or notices from the flash in the application's layout:

```erb
<html>
  <!-- <head/> -->
  <body>
    <% flash.each do |name, msg| -%>
      <%= content_tag :div, msg, class: name %>
    <% end -%>

    <!-- more content -->
  </body>
</html>
```

如此一來，action 有設定 `:notice` 或 `:alert` 訊息，layout 便會自動顯示。

Flash 訊息的種類不侷限於 `:notice`、`:alert` 或 `:flash`，可以自己定義：

```erb
<% if flash[:just_signed_up] %>
  <p class="welcome">Welcome to our site!</p>
<% end %>
```

若是想要 Flash 在 Request 之間保留下來，使用 `keep` 方法：

```ruby
class MainController < ApplicationController
  # Let's say this action corresponds to root_url, but you want
  # all requests here to be redirected to UsersController#index.
  # If an action sets the flash and redirects here, the values
  # would normally be lost when another redirect happens, but you
  # can use 'keep' to make it persist for another request.
  def index
    # 保留整個 flash
    flash.keep

    # 也可以只保留 :notice 訊息
    # flash.keep(:notice)
    redirect_to users_url
  end
end
```

#### `flash.now`

預設情況下，加入值至 `flash` 會訊息在下次 Request 可以取用，但有時候你想在同個 Request 裡顯示這些訊息。舉例來說，如果 `create` action 無法儲存，你想要直接 `render` `new` template，這不會發另一個 Request，但你仍想顯示訊息，這時候便可以使用 `flash.now`：

```ruby
class ClientsController < ApplicationController
  def create
    @client = Client.new(params[:client])
    if @client.save
      # ...
    else
      flash.now[:error] = "無法儲存 Client"
      render action: "new"
    end
  end
end
```

6. Cookies
------------------

應用程式可以在客戶端儲存小量的資料，這種資料我們稱作 Cookie。Cookie 在 Request 與 Session 之間是不會消失的。Rails 提供了簡單存取 Cookies 的方法，`cookies`，跟 `session` 方法很像：

```ruby
class CommentsController < ApplicationController
  def new
    # 若是 Cookie 裡有存留言者的名字，自動填入。
    @comment = Comment.new(author: cookies[:commenter_name])
  end

  def create
    @comment = Comment.new(params[:comment])
    if @comment.save
      flash[:notice] = "感謝您的意見！"
      if params[:remember_name]
        # 選擇記住名字，則記下留言者的名稱。
        cookies[:commenter_name] = @comment.author
      else
        # 選擇不記住名字，刪掉 Cookie 裡留言者的名稱。
        cookies.delete(:commenter_name)
      end
      redirect_to @comment.article
    else
      render action: "new"
    end
  end
end
```

Note that while for session values you set the key to `nil`, to delete a cookie value you should use `cookies.delete(:key)`.

7. Rendering XML 與 JSON 資料
------------------------------------------

在 `ActionController` 裡 render `XML` 或是 `JSON` 真是再簡單不過了，看看下面這個用鷹架產生出的 Controller：

```ruby
class UsersController < ApplicationController
  def index
    @users = User.all
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render xml: @users}
      format.json { render json: @users}
    end
  end
end
```

注意這裡 `render` XML 的時候是寫 `render xml: @users`，而不是 `render xml: @users.to_xml`。如果 `render` 的物件不是字串的話，Rails 會自動替我們呼叫 `to_xml`。

8. Filters
------------------------

Filter 是在 Controller action 執行前、後、之間所執行的方法。Filter 可繼承，也就是在 `ApplicationController` 定義的 Filter，在整個應用程式裡都會執行該 Filter。

“Before” filters 可能會終止 Request 週期。常見的 “before” filter 像是某個 `action` 需要使用者登入。Filter 方法可以這麼定義：

```ruby
class ApplicationController < ActionController::Base
  before_action :require_login, only: [:admin]

  def admin
    # 管理員才可使用的...
  end

  private

  def require_login
    unless logged_in?
      flash[:error] = "這個區塊必須登入才能存取"
      redirect_to new_login_url # 終止 Request 週期
    end
  end
end
```

**`before_action` 是 `before_filter` 的 alias，兩者皆可用，Rails 4 偏好 `before_action`** [見此 Commit](https://github.com/rails/rails/commit/9d62e04838f01f5589fa50b0baa480d60c815e2c)

這個方法非常簡單，當使用者沒有登入時，將錯誤訊息存在 flash，並轉向到登入頁。若 “before” filter 執行了 `render` 或是 `redirect_to`，則 `admin` action 便不會執行。要是 before filter 互相之間有依賴，一個取消了，另一個也會跟著取消。

剛剛的例子裡，filter 加入至 `ApplicationController`，所以在應用程式裡，只要是繼承 `ApplicationController` 的所有 action，都會需要登入才能使用。但使用者還沒註冊之前，怎麼登入？所以一定有方法可以跳過 filter，`skip_before_action`：

```ruby
class LoginsController < ApplicationController
  skip_before_action :require_login, only: [:new, :create]
end
```

現在 `LoginsController` 的 `new` 與 `create` action 會如同先前一般工作，而不需要使用者登入。

`:only`   選項用來決定這個 filter 只需要檢查哪幾個 `action`，
`:except` 選項則是決定這個 filter 不需要檢查哪幾個 `action`。

### After Filters and Around Filters

“before” filter 在 `action` 前執行，也可以在 `action` 後執行：“after” filter。

“after” filter 與 “before” filter 類似，但因為 `action` 已經執行完畢，所以 “after” filter 可以存取即將要回給使用者的 Response。“after” filter 是無法終止 Request 週期的，因為 `action` 已經執行完畢，無法終止。不像 `before_action` 可以 `render` 或是 `redirect_to`，來終止 action 的執行。

“around” filter 主要負責執行相關的 action，跟 Rack 的工作原理類似。

舉例來說，要給某個網站提交改動時，必須先獲得管理員同意，改動才會生效。管理員會需要某種類似預覽功能的操作，將此操作包在 transaction 即可：

```ruby
class ChangesController < ApplicationController
  around_action :wrap_in_transaction, only: :show

  private

  def wrap_in_transaction
    ActiveRecord::Base.transaction do
      begin
        yield
      ensure
        raise ActiveRecord::Rollback
      end
    end
  end
end
```

注意 “around” filter 包含了 `render`。需要特別說明的是，假設 View 會從資料庫讀取資料來顯示，在 transaction 裡也會這麼做，如此一來便可達到預覽的效果。

你也可以自己生 Response，不需要用 `yield`。若是沒使用 `yield`，則 `show` action 便不會被執行。

### Other Ways to Use Filters

Filters 一般的使用方式是，先建立一個 `private` 方法，在使用 `*_action` 來針對特定 `action` 執行該 `private` 方法。但還有兩種方式，也可以達到 filters 的效果。

第一種是直接對 `*_action` 使用區塊。區塊接受 `controller` 作為參數，上面的 `require_login` 例子可以改寫為：

```ruby
class ApplicationController < ActionController::Base
  before_action do |controller|
    unless controller.send(:logged_in?)
      flash[:error] = flash[:error] = "這個區塊必須登入才能存取"
      redirect_to new_login_url
    end
  end
end
```

注意到這裡使用了 `send`，因為 `logged_in?` 方法是 `private`，filter 不在 controller 的 scope 下執行。這種實作 filter 的方式不推薦使用，但在非常簡單的情況下可能有用。

第二種方式是使用 `Class`，實際上使用任何物件都可以，只要物件有回應 `filter` 這個 class method 即可。用 `Class` 實作的好處是可讀性、重用性提昇。舉個例子，login filter 可以改寫為：

```ruby
class ApplicationController < ActionController::Base
  before_action LoginFilter
end

class LoginFilter
  def self.filter(controller)
    unless controller.send(:logged_in?)
      controller.flash[:error] = "You must be logged in"
      controller.redirect_to controller.new_login_url
    end
  end
end
```

這也不推薦使用，因為不是在 controller 的 scope 下執行，所以需要傳 `controller` 作為參數。`LoginFilter` class 有一個 class method `filter`，會在 `ApplicationController` 的 action 執行前執行。用 Class 來實作 “around” filters 也可以使用同樣的 `filter` 方法，必須使用 `yield` 才能執行 action。或者是使用 `before` 與 `after` 的組合來達到 `around` 的效果。

9. Request Forgery Protection
------------------------------------------

跨站偽造請求（CSRF, Cross-site request forgery）是利用 A 站的使用者，給 B 站發送 Request 的一種攻擊手法，比如利用 A 站的梁山伯，去新增、修改、刪除 B 站祝英台的資料。

防範的第一動是確保所有破壞性的 Actions：`create`、`update` 與 `destroy` 只可以透過 **非 GET** Request 來操作。若你遵循 RESTful 的慣例，則這已經沒問題了。但惡意站點仍可發送非 GET Request 至你的網站，這時便是 Request Forgery Protection 派上用場的時刻了，Request Forgery Protection 如其名：偽造請求防禦。

防護的手法是每次 Request 加上一個猜不到的暗號（token）。如此一來，沒有正確暗號的 Request 便會被拒絕存取。.

假設有下列表單

```erb
<%= form_for @user do |f| %>
  <%= f.text_field :username %>
  <%= f.text_field :password %>
<% end %>
```

會看到 Rails 自動加上一個隱藏的 input field，數值是 token：

```html
<form accept-charset="UTF-8" action="/users/1" method="post">
<input type="hidden"
       value="67250ab105eb5ad10851c00a5621854a23af5489"
       name="authenticity_token"/>
<!-- username & password fields -->
</form>
```

Rails 給所有使用了 [Form Helpers](https://github.com/JuanitoFatas/Guides/blob/master/guides/edge-translation/form-helpers-zh_TW.md) 的表單加上這個 token，所以你不用擔心怎麼處理。若是你手寫表單可以透過 `form_authenticity_token` 方法來處理。

`form_authenticity_token` 產生一個有效的驗證 token。這在 Rails 沒有自動加上 token 的場景下很有用，像是自定的 Ajax Request，`form_authenticity_token` 很簡單，就是設定了 Session 的 `_csrf_token`：

```ruby
def form_authenticity_token
  session[:_csrf_token] ||= SecureRandom.base64(32)
end
```

來自：[ActionController::RequestForgeryProtection API](http://edgeapi.rubyonrails.org/classes/ActionController/RequestForgeryProtection.html#method-i-form_authenticity_token)。

參閱 [Security Guide](http://edgeguides.rubyonrails.org/security.html) 來了解更多關於安全性的問題。

10. The Request and Response Objects
------------------------------------------------------

Request 生命週期裡，每個 Controller 都有兩個 accessor 方法，`request` 與 `response`。

`request` 方法包含了 `AbstractRequest` 的實例。

`response` 方法則包含即將回給 client 的 `response` 物件。

### The `request` Object

`request` object 帶有許多從 client 端而來的有用資訊。關於所有可用的方法，請查閱 [ActionDispatch::Request API 文件](http://api.rubyonrails.org/classes/ActionDispatch/Request.html)。而所有可存取的 properties 有：

| `request` 的 property                     | 用途                                                        |
| ----------------------------------------- | ---------------------------------------------------------- |
| host                                      | request 使用的 hostname。|
| domain(n=2)                               | Hostname 的前 `n` 個區段，從 TLD 右邊開始算起。|
| format                                    | request 使用的 content type。|
| method                                    | request 使用的 HTTP 動詞。|
| get?, post?, patch?, put?, delete?, head? | HTTP 動詞為右列其一時，返回真。 GET/POST/PATCH/PUT/DELETE/HEAD。|
| headers                                   | 返回 request 的 header (Hash)。|
| port                                      | Request 使用的 port 號。|
| protocol                                  | 返回包含 "://" 的字串，如 "http://"。|
| query_string                              | URL 的 Query String 部分。也就是 "?" 之後的字串。|
| remote_ip                                 | Client 的 IP 位址。|
| url                                       | Request 使用的完整 URL 位址。|

#### `path_parameters`, `query_parameters`, and `request_parameters`

Rails 將所有與 Request 一起送來的參數，不管是 query string 還是 post body 而來的參數，都蒐集在 `params` Hash 裡。

Request 物件有三個 accessors，讓你取出這些參數，分別是 `query_parameters`、`request_parameters` 以及 `path_parameters`，這仨都是 Hash。

* `query_parameters`： Query String 參數（via GET）。

* `request_parameters`： POST 而來的參數。

* `path_parameters`： Controller 與 Action 名稱：

  ```ruby
  { 'action' => 'my_action', 'controller' => 'my_controller' }
  ```

### The `response` Object

`response` 物件通常不會直接使用，會在執行 action 與 render 即將送回給使用者的資料時建立出 `response` 物件。有時候需要處理 Response 再回給 User 時有用，比如在 `after` Filter 處理這件事。這時便可以存取到 Response，甚至透過 setters 來改變 Response 部分的值。

| `response` 的 property  | 用途                                               |
| ---------------------- | ---------------------------------------------------|
| body                   | 傳回給 Client 的字串，通常是 HTML。|
| status                 | Response 的 Status code，比如成功回 200，找不到回 404。|
| location               | Redirect 的 URL（如果有的話）。|
| content_type           | Response 的 Content-Type。|
| charset                | Response 使用的編碼集，預設是 "UTF-8"。|
| headers                | Response 使用的 Header。|

#### Setting Custom Headers

若是想給 Response 自定 Header，修改 `response.headers`。`headers` 是一個 Hash，將 Response Header 的名稱與值關連起來，某些值 Rails 已經幫你設定好了。假設你的 API 需要回一個特殊的 Header，`X-TOP-SECRET-HEADER`，在 Controller 便可以這麼寫：

```ruby
response.headers["X-TOP-SECRET-HEADER"] = '123456789'
```

若是要設定每個 response 的預設 Header，可在 `config/application.rb` 裡設定，詳情參考 [Configuring Rails Applications - 3.8 Configuring Action Dispatch](http://edgeguides.rubyonrails.org/configuring.html#configuring-action-dispatch) 一節。

11. HTTP Authentications
------------------------------------

Rails 內建了兩種 HTTP 驗證方法：

* Basic Authentication（基礎驗證）
* Digest Authentication

### HTTP Basic Authentication

「HTTP 基礎驗證」是一種主流瀏覽器與 HTTP 客戶端皆支援的驗證方式。舉個例子，假設有一段管理員才能瀏覽的區塊，必須在瀏覽器的 HTTP basic dialog 視窗輸入 `username` 與 `password`，確保身分是管理員才可瀏覽。

在 Rails 裡只要使用一個方法：`http_basic_authenticate_with` 即可。

```ruby
class AdminsController < ApplicationController
  http_basic_authenticate_with name: "humbaba", password: "5baa61e4"
end
```

有了這行代碼之後，可以從 `AdminsController` 切出 namespace，讓要管控的 Controller 繼承 `AdminsController`。

### HTTP Digest Authentication

HTTP digest authentication 比 HTTP Basic Authentication 高級一些，不需要使用者透過網路傳送未加密的密碼（但採用 HTTPS 的情況下，HTTP Basic Authentication 是安全的）。使用 digest authentication 也只需要一個方法：`authenticate_or_request_with_http_digest`。

```ruby
class AdminsController < ApplicationController
  USERS = { "lifo" => "world" }

  before_action :authenticate

  private

    def authenticate
      authenticate_or_request_with_http_digest do |username|
        USERS[username]
      end
    end
end
```

從上例可以看出來，`authenticate_or_request_with_http_digest` 接受一個參數，`username`。區塊內返回密碼：

```ruby
authenticate_or_request_with_http_digest do |username|
  USERS[username]
end
```

最後 `authenticate` 返回 `true` 或 `false`，決定驗證是否成功。

12. Streaming and File Downloads
----------------------------------------

Sometimes you may want to send a file to the user instead of rendering an HTML page. All controllers in Rails have the `send_data` and the `send_file` methods, which will both stream data to the client. `send_file` is a convenience method that lets you provide the name of a file on the disk and it will stream the contents of that file for you.

To stream data to the client, use `send_data`:

```ruby
require "prawn"
class ClientsController < ApplicationController
  # Generates a PDF document with information on the client and
  # returns it. The user will get the PDF as a file download.
  def download_pdf
    client = Client.find(params[:id])
    send_data generate_pdf(client),
              filename: "#{client.name}.pdf",
              type: "application/pdf"
  end

  private

    def generate_pdf(client)
      Prawn::Document.new do
        text client.name, align: :center
        text "Address: #{client.address}"
        text "Email: #{client.email}"
      end.render
    end
end
```

The `download_pdf` action in the example above will call a private method which actually generates the PDF document and returns it as a string. This string will then be streamed to the client as a file download and a filename will be suggested to the user. Sometimes when streaming files to the user, you may not want them to download the file. Take images, for example, which can be embedded into HTML pages. To tell the browser a file is not meant to be downloaded, you can set the `:disposition` option to "inline". The opposite and default value for this option is "attachment".

### Sending Files

If you want to send a file that already exists on disk, use the `send_file` method.

```ruby
class ClientsController < ApplicationController
  # Stream a file that has already been generated and stored on disk.
  def download_pdf
    client = Client.find(params[:id])
    send_file("#{Rails.root}/files/clients/#{client.id}.pdf",
              filename: "#{client.name}.pdf",
              type: "application/pdf")
  end
end
```

This will read and stream the file 4kB at the time, avoiding loading the entire file into memory at once. You can turn off streaming with the `:stream` option or adjust the block size with the `:buffer_size` option.

If `:type` is not specified, it will be guessed from the file extension specified in `:filename`. If the content type is not registered for the extension, `application/octet-stream` will be used.

WARNING: Be careful when using data coming from the client (params, cookies, etc.) to locate the file on disk, as this is a security risk that might allow someone to gain access to files they are not meant to.

TIP: It is not recommended that you stream static files through Rails if you can instead keep them in a public folder on your web server. It is much more efficient to let the user download the file directly using Apache or another web server, keeping the request from unnecessarily going through the whole Rails stack.

### RESTful Downloads

While `send_data` works just fine, if you are creating a RESTful application having separate actions for file downloads is usually not necessary. In REST terminology, the PDF file from the example above can be considered just another representation of the client resource. Rails provides an easy and quite sleek way of doing "RESTful downloads". Here's how you can rewrite the example so that the PDF download is a part of the `show` action, without any streaming:

```ruby
class ClientsController < ApplicationController
  # The user can request to receive this resource as HTML or PDF.
  def show
    @client = Client.find(params[:id])

    respond_to do |format|
      format.html
      format.pdf { render pdf: generate_pdf(@client) }
    end
  end
end
```

In order for this example to work, you have to add the PDF MIME type to Rails. This can be done by adding the following line to the file `config/initializers/mime_types.rb`:

```ruby
Mime::Type.register "application/pdf", :pdf
```

NOTE: Configuration files are not reloaded on each request, so you have to restart the server in order for their changes to take effect.

Now the user can request to get a PDF version of a client just by adding ".pdf" to the URL:

```bash
GET /clients/1.pdf
```

### Live Streaming of Arbitrary Data

Rails allows you to stream more than just files. In fact, you can stream anything
you would like in a response object. The `ActionController::Live` module allows
you to create a persistent connection with a browser. Using this module, you will
be able to send arbitrary data to the browser at specific points in time.

#### Incorporating Live Streaming

Including `ActionController::Live` inside of your controller class will provide
all actions inside of the controller the ability to stream data. You can mix in
the module like so:

```ruby
class MyController < ActionController::Base
  include ActionController::Live

  def stream
    response.headers['Content-Type'] = 'text/event-stream'
    100.times {
      response.stream.write "hello world\n"
      sleep 1
    }
  ensure
    response.stream.close
  end
end
```

The above code will keep a persistent connection with the browser and send 100
messages of `"hello world\n"`, each one second apart.

There are a couple of things to notice in the above example. We need to make
sure to close the response stream. Forgetting to close the stream will leave
the socket open forever. We also have to set the content type to `text/event-stream`
before we write to the response stream. This is because headers cannot be written
after the response has been committed (when `response.committed` returns a truthy
value), which occurs when you `write` or `commit` the response stream.

#### Example Usage

Let's suppose that you were making a Karaoke machine and a user wants to get the
lyrics for a particular song. Each `Song` has a particular number of lines and
each line takes time `num_beats` to finish singing.

If we wanted to return the lyrics in Karaoke fashion (only sending the line when
the singer has finished the previous line), then we could use `ActionController::Live`
as follows:

```ruby
class LyricsController < ActionController::Base
  include ActionController::Live

  def show
    response.headers['Content-Type'] = 'text/event-stream'
    song = Song.find(params[:id])

    song.each do |line|
      response.stream.write line.lyrics
      sleep line.num_beats
    end
  ensure
    response.stream.close
  end
end
```

The above code sends the next line only after the singer has completed the previous
line.

#### Streaming Considerations

Streaming arbitrary data is an extremely powerful tool. As shown in the previous
examples, you can choose when and what to send across a response stream. However,
you should also note the following things:

* Each response stream creates a new thread and copies over the thread local
  variables from the original thread. Having too many thread local variables can
  negatively impact performance. Similarly, a large number of threads can also
  hinder performance.
* Failing to close the response stream will leave the corresponding socket open
  forever. Make sure to call `close` whenever you are using a response stream.
* WEBrick servers buffer all responses, and so including `ActionController::Live`
  will not work. You must use a web server which does not automatically buffer
  responses.

13. Log Filtering
---------------------

Rails 為每個環境都存有 log 檔案，放在 `log` 目錄下。這些 log 檔案拿來 debug 非常有用，可以瞭解應用程式當下究竟在幹嘛。但正式運行的應用程式，可能不想要記錄所有的資訊。

### Parameters Filtering

可以從 log 檔案過濾掉特定的 Request 參數，在 `config/application.rb` 裡的 `config.filter_parameters` 設定。

```ruby
config.filter_parameters << :password
```

設定過的參數在 log 裡會被改成 `[FILTERED]`，確保 log 外洩時，輸入的密碼不會跟著外洩。

### Redirects Filtering

Sometimes it's desirable to filter out from log files some sensible locations your application is redirecting to.
You can do that by using the `config.filter_redirect` configuration option:

```ruby
config.filter_redirect << 's3.amazonaws.com'
```

You can set it to a String, a Regexp, or an array of both.

```ruby
config.filter_redirect.concat ['s3.amazonaws.com', /private_path/]
```

Matching URLs will be marked as '[FILTERED]'.

14. Rescue
---------------

> Exception 異常

每個應用程式都可能有 bugs，或是拋出異常，這些都需要處理。舉例來說，使用者點了一個連結，該連結的 resource 已經不在資料庫了，Active Record 會拋出 `ActiveRecord::RecordNotFound` exception。

Rails 預設處理 exception 的方式是 `"500 Internal Server Error"`。若 Request 是從 local 端發出，會有 backtrace 資訊，讓你來查找錯誤究竟在哪裡。若 Request 是從 Remote 端而來，則 Rails 僅顯示 `"500 Internal Server Error"`。若是使用者試圖存取不存在的路徑，Rails 則會回 `"404 Not Found"`。有時你會想自定這些錯誤的處理及顯示方式。接著讓我們看看 Rails 當中，處理錯誤與異常的幾個層級：

### The Default 500, 404 and 422 Templates

跑在 production 環境的應用程式，預設會 `render` 404、500 或 422 錯誤訊息，分別在 `public` 目錄下面的 `404.html`、`500.html` 與 `422.html`。你可以修改 `404.html` 或是 `500.html` 或 `422.html`。**注意這些是靜態文件。**

### `rescue_from`

若想要對捕捉錯誤做些更複雜的事情，可以使用 `rescue_from`。`rescue_from` 在整個 Controller 與 Controller 的 subclass 下，處理特定類型的異常（或多種類型的異常）。

當異常發生被 `rescue_from` 捕捉時，exception 物件會傳給 Handler。Handler 可以是有著 `:with` 選項的 `Proc` 物件，也可以直接使用區塊。

以下是使用 `rescue_from` 來攔截所有 `ActiveRecord::RecordNotFound` 的錯誤示範：

```ruby
class ApplicationController < ActionController::Base
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  private

    def record_not_found
      render text: "404 Not Found", status: 404
    end
end
```

上例跟預設的處理方式沒什麼兩樣，只是演示給你看如何捕捉異常，捕捉到之後，你想做任何事都可以。舉例來說，可以創建一個自定義的異常類別，在使用者沒有權限存取應用程式的某一部分時拋出：

```ruby
class ApplicationController < ActionController::Base
  rescue_from User::NotAuthorized, with: :user_not_authorized

  private

    def user_not_authorized
      flash[:error] = "You don't have access to this section."
      redirect_to :back
    end
end

class ClientsController < ApplicationController
  # 檢查使用者是否有正確的權限可以存取。
  before_action :check_authorization

  # 注意到 action 不需要處理授權問題，因為已經在 before_action 裡處理了。
  def edit
    @client = Client.find(params[:id])
  end

  private

    # 若使用者沒有授權，拋出異常。
    def check_authorization
      raise User::NotAuthorized unless current_user.admin?
    end
end
```

注意！特定的異常只有在 `ApplicationController` 裡面可以捕捉的到，因為他們在 Controller 被實例化出來之前，或 action 執行之前便發生了。參考 Pratik Naik 的[文章](http://m.onkey.org/2008/7/20/rescue-from-dispatching)來了解更多關於這個問題的細節。

15. Force HTTPS protocol
-----------------------------------

有時候出於安全性考量，可能想讓特定的 Controller 只可以透過 HTTPS 來存取。可以在 Controller 使用 `force_ssl` 方法：

```ruby
class DinnerController
  force_ssl
end
```

和 `filter` 的用法相同，可以傳入 `:only` 與 `except` 選項來決定哪幾個 Action 要用 HTTPS：

```ruby
class DinnerController
  force_ssl only: :cheeseburger
  # or
  force_ssl except: :cheeseburger
end
```

請注意，若你發現要給許多 Controller 都加上 `force_ssl`，可以在環境設定檔開啟 `config.force_ssl` 選項。

16. 延伸閱讀
------------------------------

[ActionController | Ruby on Rails 實戰聖經](http://ihower.tw/rails3/actioncontroller.html)

[#395 Action Controller Walkthrough (pro) - RailsCasts](http://railscasts.com/episodes/395-action-controller-walkthrough)