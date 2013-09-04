# Active Admin Guides

完整文件請移步：http://www.activeadmin.info/

## 安裝

```
# Gemfile
gem 'activeadmin'
```

### 用 Generator 安裝 active_admin 到 Rails

    $ rails g active_admin:install

預設會安裝 Devise user/model，並取名為 `AdminUser`，要換成別的名字，只消在後面加個參數即可。

    $ rails g active_admin:install User

也可以不產生

    $ rails generate active_admin:install --skip-users

但得自己在 `config/intializers/active_admin.rb ` 設定一堆東西：

安裝完畢記得

    rake db:migrate

將剛剛產生的模型遷移到資料庫。

### will_pageinate 兼容性設定

將下面這段加入 `config/initializers/kaminari.rb`：

```
Kaminari.configure do |config|
  config.page_method_name = :per_page_kaminari
end
```

## 通用設定

關於 Active Admin 設定幾乎都在這裡：

__config/initializers/active_admin.rb__

### Authentication

兩個東西要設定。要是安裝時產生非預設的 Model 名稱，可能要自己改一下設定。預設是用 Devise 產生的 AdminUser Model。

__設定用來在 controller 裡驗證 current user 的方法__

```
# config/initializers/active_admin.rb
config.authentication_method = :authenticate_admin_user!
```

__設定用來在 view 裡面呼叫 current admin user 的方法__

```
# config/initializers/active_admin.rb
config.current_user_method = :current_admin_user
```

也可以把驗證都關掉：

```
config.authentication_method = false
config.current_user_method   = false
```

### 設定網站標題等

```
config.site_title = "My Admin Site"
config.site_title_link = "/"    ## Rails url helpers do not work here
config.site_title_image = "site_log_image.png"
```

### i18n

複製 `lib/active_admin/locales/en.yml` 到 `config/locales`，開始翻譯。

### Namespaces

在 Active Admin 註冊一個 RESTful 資源時，預設會被載入到一個 namespace 裡，`"admin"`。

```
# app/admin/posts.rb
ActiveAdmin.register Post do
  # ...
end
```

Post 會被放到 admin namespace 下面：`/admin/posts/`。

每個 namespace 都有自己一份設定檔，預設會繼承 application 的設定檔。

實際的例子，application 網站預設的標題為 "My Default Site Title"，每個 namespace 都有自己不一樣的標題：

```
ActiveAdmin.setup do |config|
  config.site_title = "My Default Site Title"

  config.namespace :admin do |admin|
    admin.site_title = "Admin Site"
  end

  config.namespace :super_admin do |super_admin|
    super_admin.site_title = "Super Admin Site"
  end
end
```

### Load Path

預設 Active Admin 的檔案都放在 `/app/admin/` 下，可以換地方放：

```
ActiveAdmin.setup do |config|
  config.load_paths = [File.join(Rails.root, "app", "ui")]
end
```
### Comment Path

預設 Active Admin 包含了 comments 與 resources。你不要的話，可以這樣關掉：

```
ActiveAdmin.setup do |config|
  config.allow_comments = false
end
```

針對特定 namespace 停用啟用：

```
ActiveAdmin.setup do |config|
  config.namespace :admin do |admin|
    admin.allow_comments = false
  end
end
```

也可以針對特定 resource 停用評論：

```
ActiveAdmin.register Post do
  config.comments = false
end
```
### Utility Navigation

Active Admin 預設當登入後會顯示登入的 email 以及登出連結，這完全可以改成你想要的樣子：

```
ActiveAdmin.setup do |config|
  config.namespace :admin do |admin|
    admin.build_menu :utility_navigation do |menu|
      menu.add label: "ActiveAdmin.info", url: "http://www.activeadmin.info", html_options: { target: :blank }
      admin.add_logout_button_to_menu menu # can also pass priority & html_options for link_to to use
    end
  end
end
```

## Customize Resource

## Customize Index Page

## Customize CSV

## Customize Show Screen

## Sidebar Sections

## Custom Controller Actions

## Index Batch Actions

## Custom Pages

## Decorators

## Arbre Components

## Authorization Adapter
