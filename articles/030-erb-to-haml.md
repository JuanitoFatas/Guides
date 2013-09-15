# ERB 轉換至 HAML

在 Rails 專案裡使用：

Gemfile:

    gem 'erb2haml'

記得安裝

    bundle install

看看 `erb2haml` 提供了什麼功能:

    rake -T


```
rake haml:convert_erbs      # Perform bulk conversion of all html.erb files to Haml in views folder
rake haml:replace_erbs      # Perform bulk conversion of all html.erb files to Haml in views folder, then remove the converted html.erb files
```

開始轉換

```
$ rake haml:replace_erbs
Looking for ERB files to convert to Haml...
Converting: app/views/layouts/application.html.erb... Done!
Removing: app/views/layouts/application.html.erb... Removed!
```

轉換成功！