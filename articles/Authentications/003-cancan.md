# [CanCan](https://github.com/ryanb/cancan) 簡介

CanCan 是由 Rails 社群知名的 RailsCasts 作者 Ryan Bates 所開發的 authorization gem。

## Rails 4 Ready?

Rails 3+ 請用 1.6.x 的版本。

Rails 4+ CanCan 目前提供了 2.0 這個 branch。(尚未修正完畢）

## CanCan 快速導覽

CanCan 兩個重點：

* （一）權限管控定義在 `Ability.rb` (`/app/model`)

* （二）Controller 裡有 `current_user` 方法

CanCan 1.5+ 實作了 Rails generator，用來產生 `Ability.rb`:

```bash
$ rails g cancan:ability
```

cancan 主要在 view 與 controller 提供了 `can?`、`cannot?` 幾個簡單的方法。

## controller 檢查使用者有無權限 `authorize!`:

```ruby
def show
  @article = Article.find(params[:id])
  authorize! :read, @article
end
```

每個方法都要用，很繁瑣，故 CanCan 實作了：`load_and_authorize_resource`

會把以 RESTful style 實作的 controller 的每個 action，檢查有沒有權限，並加載:

> RESTful actions: index, show, edit, new, create, update, destroy

```ruby
class ArticlesController < ApplicationController
  load_and_authorize_resource

  def show
    # @article is already loaded and authorized
  end
end
```

## 未授權的處理

未授權會拋出 `CanCan::AccessDenied`，要在 `ApplicationController` 裡把它處理掉：

```
class ApplicationController < ActionController::Base
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end
end
```

## 檢查每個 action 有無權限 `check_authorization`

```ruby
class ApplicationController < ActionController::Base
  check_authorization
end
```

若某個 controller 無需檢查權限，使用 `skip_authorization_check`

## [定義 Ability](https://github.com/ryanb/cancan/wiki/Authorizing-Controller-Actions)

如何撰寫 Ability.rb

## [檢查 Ability](https://github.com/ryanb/cancan/wiki/Checking-Abilities)

Ability.rb 定義完後，用 `can?`、`cannot?` 檢查 Ability.rb 有無設錯。

## [Ability 優先權](https://github.com/ryanb/cancan/wiki/Ability-Precedence)

## [測試 Ability](https://github.com/ryanb/cancan/wiki/Testing-Abilities)

## [除錯 Ability](https://github.com/ryanb/cancan/wiki/Debugging-Abilities)

## [授權 Controller Actions](https://github.com/ryanb/cancan/wiki/Authorizing-Controller-Actions)

RSpec、Cucumber、測試 Controller。

## [處理異常](https://github.com/ryanb/cancan/wiki/Exception-Handling)

如何自定 `authorize!` 噴的訊息，丟出異常的行為，把 HTTP Status code 改成 403 等。

## [更改預設值](https://github.com/ryanb/cancan/wiki/Changing-Defaults)

## 延伸閱讀

有點舊的影片教學，但可以看到當初 Ryan Bates 開發 CanCan 的理念。

[Railscasts 192 Authorization with CanCan](http://railscasts.com/episodes/192-authorization-with-cancan)

[CanCan Wiki](https://github.com/ryanb/cancan/wiki)