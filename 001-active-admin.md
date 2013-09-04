# Active Admin Guides

完整文件請移步：http://www.activeadmin.info/

## 安裝

```
# Gemfile
gem 'activeadmin'
```

### 用 Generator 安裝 active_admin 到 Rails

    $ rails g active_admin:install

預設會安裝 Devise user/model，並取名為 `AdminUser`，要換成別的名字，只消在後面加入個參數即可。

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
