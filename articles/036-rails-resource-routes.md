
`config/routes.rb`

加入：

```ruby
resources :pages
```

輸入 `$ rake routes`：

| routing helper | http verb | route | controller#action
|:--:|:--:|:--:|:--:|
| pages | GET | /pages(.:format) | pages#index
| - | POST | /pages(.:format) | - | pages#create |
| new_page | GET | /pages/new(.:format) | pages#new |
| edit_page | GET | /pages/:id/edit(.:format) | pages#edit |
| page | GET | /pages/:id(.:format) | pages#show |
| - | PUT | /pages/:id(.:format) | pages#update |
| - | DELETE | /pages/:id(.:format) | pages#destroy |