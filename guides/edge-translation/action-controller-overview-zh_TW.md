# Action Controller 概覽

__特別要強調的翻譯名詞__

> application 應用程式。

本篇介紹 Controller 的工作原理、Controller 與如何應用程式的 Request 生命週期結合在一起。

讀完本篇可能會學到.....

* Request 進到 Controller 的流程。
* 限制傳入 Controller 的參數。
* 為何、如何把資料存在 Session 或 Cookie 裡。
* 如何在處理 Request 時使用 Filters 來執行程式碼。
* 如何使用 Action Controller 內建的 HTTP 驗證。
* 如何用串流方式將資料傳給使用者的瀏覽器。
* 如何在應用程式的 Log 裡過濾敏感資料。
* 如何處理 Request 處理週期可能拋出的異常。

## 目錄

# 1. Controller 做了什麼？

Action Controller 是 MVC 的 C，Controller。一個 Request 進來，路由決定是那個 Controller 的工作後，便把工作指派給 Controller，Controller 負責處理該 Request，給出對應的 Output。幸運的是 Action Controller 把大部分的苦力都給您辦好了，您只需按照一些規範來寫代碼，事情便豁然開朗。

對多數按照 [RESTful](http://en.wikipedia.org/wiki/Representational_state_transfer) 規範來編寫的應用程式來說，Controller 的工作便是接收 Request，按照 Request 的請求，去 Model 取或寫資料，並將資料交給 View，來產生出 HTML。

Controller 因此可以想成是 Model 與 View 的中間人。負責替 Model 將資料傳給 View，讓 View 可以顯示資料給使用者。Controller 也將使用者更新或儲存的資料，存回 Model。


路由過程的細節可以查閱 [Rails Routing From the Outside In](http://edgeguides.rubyonrails.org/routing.html)。

# 2. Controller 命名規範

Rails 偏好 Controller 以複數結尾，但也是有例外，比如 `ApplicationController`。舉例來說：

偏好 `ClientsController` 勝過 `ClientController`。

偏好 `SiteAdminsController` 勝過 `SitesAdminsController`。

遵循規範便可使用內建的路由產生器：`resources`、`resource` 等，而無需特地修飾 `:path`、`controller`，並可保持 URL 與 path Helpers 的一致性。細節請參考 [Layouts & Rendering Guide](/guides/edge/layouts_and_rendering.md) 一篇。

注意：Controller 的命名規範與 Model 的命名規範不同，Model 預期的是單數形式。

# 3. Methods 與 Actions

Controller 從 `ApplicationController` 繼承而來，但 Controller 其實跟普通的 Ruby Class 一樣，都有 methods。當應用程式收到 Request 時，Routing 會決定這要交給那個 Controller 的那個 Action 來處理，接著 Rails 創造出該 Controller 的 instance，執行與 Action 名稱相同的 Method。

```ruby
class ClientsController < ApplicationController
  def new
  end
end
```

假設使用者跑去 `/clients/new`，想要新增 `client` 時，Rails 創出 `ClientsController` 的 instance，並呼叫 `new` 來處理。注意 `new` 雖沒有內容，但 Rails 預設會 `render` `new.html.erb`。先前提到 Controller 可以從 Model 取資料給 View，要怎麼做呢？

```ruby
def new
  @client = Client.new
end
```

更多細節請參考 [Layouts & Rendering Guide](layouts_and_rendering.html) 一篇。

`ApplicationController`從 `ActionController::Base` 繼承而來，`ActionController::Base` 定義了許多有用的 Methods。本篇會提到一些，但要是好奇定義了些什麼方法，可參考 [ActionController::Base 的 API 文件](http://edgeapi.rubyonrails.org/classes/ActionController/Base.html)，或是閱讀 [ActionController::Base 原始碼](https://github.com/rails/rails/blob/master/actionpack/lib/action_controller/base.rb)。

只有公有方法可以被外部作為 action 呼叫。所以輔助方法啦、Filter 啦，最好藏在 `protected` 或 `private` 裡。

# 4. 參數

通常會想在 Controller 裡，存取由使用者傳入的資料或是其他的參數。Web 應用程式有兩種參數。第一種是由 URL 的部份組成，這種叫做 “query string parameters”。Query string 是 URL `?` 後面的任何字串，通常是透過 HTTP `GET` 傳遞。第二種參數是 “POST data”，透過 HTTP `POST` 傳遞，故得名 “POST data”。這通常是使用者從表單填入的訊息。叫做 POST data 的原因是只能作為 HTTP POST Request 的一部分來傳遞。Rails 並不區分 Query String Parameter 或 POST Parameter，兩者皆可在 Controller 裡，從 `params` hash 裡取出：

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

`params` hash 不侷限於一維的 hash。可以是巢狀的 Hash，裡面包有 Array，都可以。要將數值包裝在 Array 裡傳遞，在 key 的名稱後方附加 `[]`：

```
GET /clients?ids[]=1&ids[]=2&ids[]=3
```

注意：上例 URL 會編碼為 `"/clients?ids%5B%5D=1&ids%5B%5D=2&ids%5B%5D=3"`，因為 `[]` 對 URL 來說是非法字元。多數情況下，瀏覽器會幫我們處理好檢查字元合法性的問題，自動幫我們編碼，Rails 收到時會在解碼。但當你要手動將 Request 發給 Server 時，要記得自己處理好這件事。

`params[:ids]` 現在會是 `["1", "2", "3"]`。注意參數的值永遠是 String。Rails 不會試著去臆測或是轉換類型。

要送出 hash，在中括號裡聲明 key 的名稱：

```html
<form accept-charset="UTF-8" action="/clients" method="post">
  <input type="text" name="client[name]" value="Acme" />
  <input type="text" name="client[phone]" value="12345" />
  <input type="text" name="client[address][postcode]" value="12345" />
  <input type="text" name="client[address][city]" value="Carrot City" />
</form>
```

這個表單送出時，`params[:client]` 的數值會是 `{ "name" => "Acme", "phone" => "12345", "address" => { "postcode" => "12345", "city" => "Carrot City" } }`

注意 `params[:client][:address]` 是巢狀的結構。

`params` hash 其實是 `ActiveSupport::HashWithIndifferentAccess` 的 instance，`ActiveSupport::HashWithIndifferentAccess` 與一般 hash 相同，不同的是 hash 的 key 可以用字串與符號。

`params[:foo]` 等同於 `params["foo"]`

### JSON 參數

在撰寫 Web Service 的應用程式時，通常接受 JSON 格式的參數會比較簡單。若 Request 的 `"Content-Type"` header 是 `"application/json"`，Rails 會自動將參數轉換好，存至 `params` hash 裡。

送出

```json
{ "company": { "name": "acme", "address": "123 Carrot Street" } }
```

取得

`params[:company]` ＝ `{ "name" => "acme", "address" => "123 Carrot Street" }`

除此之外，如果開啟了 `config.wrap_parameters` 選項，或是在 Controller 呼叫了 `wrap_parameters`，可以忽略掉 JSON 參數的 root element，JSON 參數的內容會被拷貝到 `params` 裡，有著對應的 key：

```json
{ "name": "acme", "address": "123 Carrot Street" }
```

傳給 `CompaniesController`，會被包在 `:company` key 裡：

```ruby
{ name: "acme", address: "123 Carrot Street", company: { name: "acme", address: "123 Carrot Street" } }
```

關於如何客製化 key 名稱，或是對某些特殊的參數執行 wrap，請查閱 [ActionController::ParamsWrapper 的 API 文件](http://edgeapi.rubyonrails.org/classes/ActionController/ParamsWrapper.html)。


解析 XML 的功能已被抽離至 [actionpack-xml_parser](https://github.com/rails/actionpack-xml_parser) Gem。

### Routing 參數

The `params` hash will always contain the `:controller` and `:action` keys, but you should use the methods `controller_name` and `action_name` instead to access these values. Any other parameters defined by the routing, such as `:id` will also be available. As an example, consider a listing of clients where the list can show either active or inactive clients. We can add a route which captures the `:status` parameter in a "pretty" URL:

```ruby
get '/clients/:status' => 'clients#index', foo: 'bar'
```

In this case, when a user opens the URL `/clients/active`, `params[:status]` will be set to "active". When this route is used, `params[:foo]` will also be set to "bar" just like it was passed in the query string. In the same way `params[:action]` will contain "index".

### `default_url_options`

You can set global default parameters for URL generation by defining a method called `default_url_options` in your controller. Such a method must return a hash with the desired defaults, whose keys must be symbols:

```ruby
class ApplicationController < ActionController::Base
  def default_url_options
    { locale: I18n.locale }
  end
end
```

These options will be used as a starting point when generating URLs, so it's possible they'll be overridden by the options passed in `url_for` calls.

If you define `default_url_options` in `ApplicationController`, as in the example above, it would be used for all URL generation. The method can also be defined in one specific controller, in which case it only affects URLs generated there.

### Strong Parameters

With strong parameters, Action Controller parameters are forbidden to
be used in Active Model mass assignments until they have been
whitelisted. This means you'll have to make a conscious choice about
which attributes to allow for mass updating and thus prevent
accidentally exposing that which shouldn't be exposed.

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

Given

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

You can also use permit on nested parameters, like:

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

The strong parameter API was designed with the most common use cases
in mind. It is not meant as a silver bullet to handle all your
whitelisting problems. However you can easily mix the API with your
own code to adapt to your situation.

Imagine a scenario where you want to whitelist an attribute
containing a hash with any keys. Using strong parameters you can't
allow a hash with any keys but you can use a simple assignment to get
the job done:

```ruby
def product_params
  params.require(:product).permit(:name, data: params[:product][:data].try(:keys))
end
```

# 5. Session

Your application has a session for each user in which you can store small amounts of data that will be persisted between requests. The session is only available in the controller and the view and can use one of a number of different storage mechanisms:

* `ActionDispatch::Session::CookieStore` - Stores everything on the client.
* `ActionDispatch::Session::CacheStore` - Stores the data in the Rails cache.
* `ActionDispatch::Session::ActiveRecordStore` - Stores the data in a database using Active Record. (require `activerecord-session_store` gem).
* `ActionDispatch::Session::MemCacheStore` - Stores the data in a memcached cluster (this is a legacy implementation; consider using CacheStore instead).

All session stores use a cookie to store a unique ID for each session (you must use a cookie, Rails will not allow you to pass the session ID in the URL as this is less secure).

For most stores, this ID is used to look up the session data on the server, e.g. in a database table. There is one exception, and that is the default and recommended session store - the CookieStore - which stores all session data in the cookie itself (the ID is still available to you if you need it). This has the advantage of being very lightweight and it requires zero setup in a new application in order to use the session. The cookie data is cryptographically signed to make it tamper-proof. And it is also encrypted so anyone with access to it can't read its contents. (Rails will not accept it if it has been edited).

The CookieStore can store around 4kB of data - much less than the others - but this is usually enough. Storing large amounts of data in the session is discouraged no matter which session store your application uses. You should especially avoid storing complex objects (anything other than basic Ruby objects, the most common example being model instances) in the session, as the server might not be able to reassemble them between requests, which will result in an error.

If your user sessions don't store critical data or don't need to be around for long periods (for instance if you just use the flash for messaging), you can consider using ActionDispatch::Session::CacheStore. This will store sessions using the cache implementation you have configured for your application. The advantage of this is that you can use your existing cache infrastructure for storing sessions without requiring any additional setup or administration. The downside, of course, is that the sessions will be ephemeral and could disappear at any time.

Read more about session storage in the [Security Guide](security.html).

If you need a different session storage mechanism, you can change it in the `config/initializers/session_store.rb` file:

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

In your controller you can access the session through the `session` instance method.

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

To store something in the session, just assign it to the key like a hash:

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

To remove something from the session, assign that key to be `nil`:

```ruby
class LoginsController < ApplicationController
  # "Delete" a login, aka "log the user out"
  def destroy
    # Remove the user id from the session
    @_current_user = session[:current_user_id] = nil
    redirect_to root_url
  end
end
```

To reset the entire session, use `reset_session`.

### The Flash

The flash is a special part of the session which is cleared with each request. This means that values stored there will only be available in the next request, which is useful for passing error messages etc.

It is accessed in much the same way as the session, as a hash (it's a [FlashHash](http://api.rubyonrails.org/classes/ActionDispatch/Flash/FlashHash.html) instance).

Let's use the act of logging out as an example. The controller can send a message which will be displayed to the user on the next request:

```ruby
class LoginsController < ApplicationController
  def destroy
    session[:current_user_id] = nil
    flash[:notice] = "You have successfully logged out."
    redirect_to root_url
  end
end
```

Note that it is also possible to assign a flash message as part of the redirection. You can assign `:notice`, `:alert` or the general purpose `:flash`:

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

This way, if an action sets a notice or an alert message, the layout will display it automatically.

You can pass anything that the session can store; you're not limited to notices and alerts:

```erb
<% if flash[:just_signed_up] %>
  <p class="welcome">Welcome to our site!</p>
<% end %>
```

If you want a flash value to be carried over to another request, use the `keep` method:

```ruby
class MainController < ApplicationController
  # Let's say this action corresponds to root_url, but you want
  # all requests here to be redirected to UsersController#index.
  # If an action sets the flash and redirects here, the values
  # would normally be lost when another redirect happens, but you
  # can use 'keep' to make it persist for another request.
  def index
    # Will persist all flash values.
    flash.keep

    # You can also use a key to keep only some kind of value.
    # flash.keep(:notice)
    redirect_to users_url
  end
end
```

#### `flash.now`

By default, adding values to the flash will make them available to the next request, but sometimes you may want to access those values in the same request. For example, if the `create` action fails to save a resource and you render the `new` template directly, that's not going to result in a new request, but you may still want to display a message using the flash. To do this, you can use `flash.now` in the same way you use the normal `flash`:

```ruby
class ClientsController < ApplicationController
  def create
    @client = Client.new(params[:client])
    if @client.save
      # ...
    else
      flash.now[:error] = "Could not save client"
      render action: "new"
    end
  end
end
```

# 6. Cookies

Your application can store small amounts of data on the client - called cookies - that will be persisted across requests and even sessions. Rails provides easy access to cookies via the `cookies` method, which - much like the `session` - works like a hash:

```ruby
class CommentsController < ApplicationController
  def new
    # Auto-fill the commenter's name if it has been stored in a cookie
    @comment = Comment.new(author: cookies[:commenter_name])
  end

  def create
    @comment = Comment.new(params[:comment])
    if @comment.save
      flash[:notice] = "Thanks for your comment!"
      if params[:remember_name]
        # Remember the commenter's name.
        cookies[:commenter_name] = @comment.author
      else
        # Delete cookie for the commenter's name cookie, if any.
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

# 7. Rendering XML and JSON data

ActionController makes it extremely easy to render `XML` or `JSON` data. If you've generated a controller using scaffolding, it would look something like this:

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

You may notice in the above code that we're using `render xml: @users`, not `render xml: @users.to_xml`. If the object is not a String, then Rails will automatically invoke `to_xml` for us.

# 8. Filters

Filters are methods that are run before, after or "around" a controller action.

Filters are inherited, so if you set a filter on `ApplicationController`, it will be run on every controller in your application.

"Before" filters may halt the request cycle. A common "before" filter is one which requires that a user is logged in for an action to be run. You can define the filter method this way:

```ruby
class ApplicationController < ActionController::Base
  before_action :require_login

  private

  def require_login
    unless logged_in?
      flash[:error] = "You must be logged in to access this section"
      redirect_to new_login_url # halts request cycle
    end
  end
end
```

The method simply stores an error message in the flash and redirects to the login form if the user is not logged in. If a "before" filter renders or redirects, the action will not run. If there are additional filters scheduled to run after that filter, they are also cancelled.

In this example the filter is added to `ApplicationController` and thus all controllers in the application inherit it. This will make everything in the application require the user to be logged in in order to use it. For obvious reasons (the user wouldn't be able to log in in the first place!), not all controllers or actions should require this. You can prevent this filter from running before particular actions with `skip_before_action`:

```ruby
class LoginsController < ApplicationController
  skip_before_action :require_login, only: [:new, :create]
end
```

Now, the `LoginsController`'s `new` and `create` actions will work as before without requiring the user to be logged in. The `:only` option is used to only skip this filter for these actions, and there is also an `:except` option which works the other way. These options can be used when adding filters too, so you can add a filter which only runs for selected actions in the first place.

### After Filters and Around Filters

In addition to "before" filters, you can also run filters after an action has been executed, or both before and after.

"After" filters are similar to "before" filters, but because the action has already been run they have access to the response data that's about to be sent to the client. Obviously, "after" filters cannot stop the action from running.

"Around" filters are responsible for running their associated actions by yielding, similar to how Rack middlewares work.

For example, in a website where changes have an approval workflow an administrator could be able to preview them easily, just apply them within a transaction:

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

Note that an "around" filter also wraps rendering. In particular, if in the example above, the view itself reads from the database (e.g. via a scope), it will do so within the transaction and thus present the data to preview.

You can choose not to yield and build the response yourself, in which case the action will not be run.

### Other Ways to Use Filters

While the most common way to use filters is by creating private methods and using *_action to add them, there are two other ways to do the same thing.

The first is to use a block directly with the *_action methods. The block receives the controller as an argument, and the `require_login` filter from above could be rewritten to use a block:

```ruby
class ApplicationController < ActionController::Base
  before_action do |controller|
    redirect_to new_login_url unless controller.send(:logged_in?)
  end
end
```

Note that the filter in this case uses `send` because the `logged_in?` method is private and the filter is not run in the scope of the controller. This is not the recommended way to implement this particular filter, but in more simple cases it might be useful.

The second way is to use a class (actually, any object that responds to the right methods will do) to handle the filtering. This is useful in cases that are more complex and can not be implemented in a readable and reusable way using the two other methods. As an example, you could rewrite the login filter again to use a class:

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

Again, this is not an ideal example for this filter, because it's not run in the scope of the controller but gets the controller passed as an argument. The filter class has a class method `filter` which gets run before or after the action, depending on if it's a before or after filter. Classes used as around filters can also use the same `filter` method, which will get run in the same way. The method must `yield` to execute the action. Alternatively, it can have both a `before` and an `after` method that are run before and after the action.

# 9. Request Forgery Protection

Cross-site request forgery is a type of attack in which a site tricks a user into making requests on another site, possibly adding, modifying or deleting data on that site without the user's knowledge or permission.

The first step to avoid this is to make sure all "destructive" actions (create, update and destroy) can only be accessed with non-GET requests. If you're following RESTful conventions you're already doing this. However, a malicious site can still send a non-GET request to your site quite easily, and that's where the request forgery protection comes in. As the name says, it protects from forged requests.

The way this is done is to add a non-guessable token which is only known to your server to each request. This way, if a request comes in without the proper token, it will be denied access.

If you generate a form like this:

```erb
<%= form_for @user do |f| %>
  <%= f.text_field :username %>
  <%= f.text_field :password %>
<% end %>
```

You will see how the token gets added as a hidden field:

```html
<form accept-charset="UTF-8" action="/users/1" method="post">
<input type="hidden"
       value="67250ab105eb5ad10851c00a5621854a23af5489"
       name="authenticity_token"/>
<!-- fields -->
</form>
```

Rails adds this token to every form that's generated using the [form helpers](form_helpers.html), so most of the time you don't have to worry about it. If you're writing a form manually or need to add the token for another reason, it's available through the method `form_authenticity_token`:

The `form_authenticity_token` generates a valid authentication token. That's useful in places where Rails does not add it automatically, like in custom Ajax calls.

The [Security Guide](security.html) has more about this and a lot of other security-related issues that you should be aware of when developing a web application.

# 10. The Request and Response Objects

In every controller there are two accessor methods pointing to the request and the response objects associated with the request cycle that is currently in execution. The `request` method contains an instance of `AbstractRequest` and the `response` method returns a response object representing what is going to be sent back to the client.

### The `request` Object

The request object contains a lot of useful information about the request coming in from the client. To get a full list of the available methods, refer to the [API documentation](http://api.rubyonrails.org/classes/ActionDispatch/Request.html). Among the properties that you can access on this object are:

| Property of `request`                     | Purpose                                                                          |
| ----------------------------------------- | -------------------------------------------------------------------------------- |
| host                                      | The hostname used for this request.                                              |
| domain(n=2)                               | The hostname's first `n` segments, starting from the right (the TLD).            |
| format                                    | The content type requested by the client.                                        |
| method                                    | The HTTP method used for the request.                                            |
| get?, post?, patch?, put?, delete?, head? | Returns true if the HTTP method is GET/POST/PATCH/PUT/DELETE/HEAD.               |
| headers                                   | Returns a hash containing the headers associated with the request.               |
| port                                      | The port number (integer) used for the request.                                  |
| protocol                                  | Returns a string containing the protocol used plus "://", for example "http://". |
| query_string                              | The query string part of the URL, i.e., everything after "?".                    |
| remote_ip                                 | The IP address of the client.                                                    |
| url                                       | The entire URL used for the request.                                             |

#### `path_parameters`, `query_parameters`, and `request_parameters`

Rails collects all of the parameters sent along with the request in the `params` hash, whether they are sent as part of the query string or the post body. The request object has three accessors that give you access to these parameters depending on where they came from. The `query_parameters` hash contains parameters that were sent as part of the query string while the `request_parameters` hash contains parameters sent as part of the post body. The `path_parameters` hash contains parameters that were recognized by the routing as being part of the path leading to this particular controller and action.

### The `response` Object

The response object is not usually used directly, but is built up during the execution of the action and rendering of the data that is being sent back to the user, but sometimes - like in an after filter - it can be useful to access the response directly. Some of these accessor methods also have setters, allowing you to change their values.

| Property of `response` | Purpose                                                                                             |
| ---------------------- | --------------------------------------------------------------------------------------------------- |
| body                   | This is the string of data being sent back to the client. This is most often HTML.                  |
| status                 | The HTTP status code for the response, like 200 for a successful request or 404 for file not found. |
| location               | The URL the client is being redirected to, if any.                                                  |
| content_type           | The content type of the response.                                                                   |
| charset                | The character set being used for the response. Default is "utf-8".                                  |
| headers                | Headers used for the response.                                                                      |

#### Setting Custom Headers

If you want to set custom headers for a response then `response.headers` is the place to do it. The headers attribute is a hash which maps header names to their values, and Rails will set some of them automatically. If you want to add or change a header, just assign it to `response.headers` this way:

```ruby
response.headers["Content-Type"] = "application/pdf"
```

Note: in the above case it would make more sense to use the `content_type` setter directly.

# 11. HTTP Authentications

Rails comes with two built-in HTTP authentication mechanisms:

* Basic Authentication
* Digest Authentication

### HTTP Basic Authentication

HTTP basic authentication is an authentication scheme that is supported by the majority of browsers and other HTTP clients. As an example, consider an administration section which will only be available by entering a username and a password into the browser's HTTP basic dialog window. Using the built-in authentication is quite easy and only requires you to use one method, `http_basic_authenticate_with`.

```ruby
class AdminsController < ApplicationController
  http_basic_authenticate_with name: "humbaba", password: "5baa61e4"
end
```

With this in place, you can create namespaced controllers that inherit from `AdminController`. The filter will thus be run for all actions in those controllers, protecting them with HTTP basic authentication.

### HTTP Digest Authentication

HTTP digest authentication is superior to the basic authentication as it does not require the client to send an unencrypted password over the network (though HTTP basic authentication is safe over HTTPS). Using digest authentication with Rails is quite easy and only requires using one method, `authenticate_or_request_with_http_digest`.

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

As seen in the example above, the `authenticate_or_request_with_http_digest` block takes only one argument - the username. And the block returns the password. Returning `false` or `nil` from the `authenticate_or_request_with_http_digest` will cause authentication failure.

# 12. Streaming and File Downloads

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

# 13. Log Filtering

Rails keeps a log file for each environment in the `log` folder. These are extremely useful when debugging what's actually going on in your application, but in a live application you may not want every bit of information to be stored in the log file.

### Parameters Filtering

You can filter certain request parameters from your log files by appending them to `config.filter_parameters` in the application configuration. These parameters will be marked [FILTERED] in the log.

```ruby
config.filter_parameters << :password
```

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

# 14. Rescue

Most likely your application is going to contain bugs or otherwise throw an exception that needs to be handled. For example, if the user follows a link to a resource that no longer exists in the database, Active Record will throw the `ActiveRecord::RecordNotFound` exception.

Rails' default exception handling displays a "500 Server Error" message for all exceptions. If the request was made locally, a nice traceback and some added information gets displayed so you can figure out what went wrong and deal with it. If the request was remote Rails will just display a simple "500 Server Error" message to the user, or a "404 Not Found" if there was a routing error or a record could not be found. Sometimes you might want to customize how these errors are caught and how they're displayed to the user. There are several levels of exception handling available in a Rails application:

### The Default 500 and 404 Templates

By default a production application will render either a 404 or a 500 error message. These messages are contained in static HTML files in the `public` folder, in `404.html` and `500.html` respectively. You can customize these files to add some extra information and layout, but remember that they are static; i.e. you can't use RHTML or layouts in them, just plain HTML.

### `rescue_from`

If you want to do something a bit more elaborate when catching errors, you can use `rescue_from`, which handles exceptions of a certain type (or multiple types) in an entire controller and its subclasses.

When an exception occurs which is caught by a `rescue_from` directive, the exception object is passed to the handler. The handler can be a method or a `Proc` object passed to the `:with` option. You can also use a block directly instead of an explicit `Proc` object.

Here's how you can use `rescue_from` to intercept all `ActiveRecord::RecordNotFound` errors and do something with them.

```ruby
class ApplicationController < ActionController::Base
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  private

    def record_not_found
      render text: "404 Not Found", status: 404
    end
end
```

Of course, this example is anything but elaborate and doesn't improve on the default exception handling at all, but once you can catch all those exceptions you're free to do whatever you want with them. For example, you could create custom exception classes that will be thrown when a user doesn't have access to a certain section of your application:

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
  # Check that the user has the right authorization to access clients.
  before_action :check_authorization

  # Note how the actions don't have to worry about all the auth stuff.
  def edit
    @client = Client.find(params[:id])
  end

  private

    # If the user is not authorized, just throw the exception.
    def check_authorization
      raise User::NotAuthorized unless current_user.admin?
    end
end
```

NOTE: Certain exceptions are only rescuable from the `ApplicationController` class, as they are raised before the controller gets initialized and the action gets executed. See Pratik Naik's [article](http://m.onkey.org/2008/7/20/rescue-from-dispatching) on the subject for more information.

# 15. Force HTTPS protocol

Sometime you might want to force a particular controller to only be accessible via an HTTPS protocol for security reasons. You can use the `force_ssl` method in your controller to enforce that:

```ruby
class DinnerController
  force_ssl
end
```

Just like the filter, you could also pass `:only` and `:except` to enforce the secure connection only to specific actions:

```ruby
class DinnerController
  force_ssl only: :cheeseburger
  # or
  force_ssl except: :cheeseburger
end
```

Please note that if you find yourself adding `force_ssl` to many controllers, you may want to force the whole application to use HTTPS instead. In that case, you can set the `config.force_ssl` in your environment file.
