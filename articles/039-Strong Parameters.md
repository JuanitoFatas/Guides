# [Strong Parameters](https://github.com/rails/strong_parameters)

Rails 4 引進了一個新的保護機制：Strong Parameters，譯作健壯參數、強壯參數等。

但我認為譯作“安全參數”、“允許參數”較好。

## 什麼是 Strong Parameter?

在建模或更新 Active Record 物件時，會有 Mass assignment 的問題。

Mass assignment 就是建模或更新時，傳入 hash 參數，一次給多個欄位賦值：

```ruby
# params[:book] => { name: 'Ruby on Rails 4', author: 'Juanito Fatas', role: :reviewer }

def create
  @ruby_on_rails4 = Book.create(params[:book])
end

def update
  @ruby_on_rails4 = Book.update(params[:book])
end
```

這裡看到角色是 Reviewer，若角色被惡意改成擁有最高權限，如作者，則會有安全性問題。

此時便需要建立白名單機制 ＋ `attr_accessible` 或是 `attr_protected` 來確保允許哪些參數、哪些不允許。

但由於許多原因，後繼者為 Strong Parameter。

更詳細的內容可以參考業界先進張文鈿（_ihower_）先生於 [《Ruby on Rails 實戰聖經》網路安全](http://ihower.tw/rails3/security.html)一章，關於大量賦值（Mass assignment）的說明。

現在所有參數的核定，交由 Controller 處理，由 Controller 決定，哪些參數可以大量賦值。

Rails 4 怎麼做？

```ruby
class PeopleController < ActionController::Base
  def create
    Person.create(person_params)
  end

  def update
    person = current_account.people.find(params[:id])
    person.update!(person_params)
    redirect_to person
  end

  private

    def person_params
      params.require(:person).permit(:name, :age)
    end
end
```

看到 private 方法有一個 `person_params`，這裡你先 require 需要核可哪個 model，並允許哪些欄位。


__params.需要核可(:model_name).允許(:欄位_1, :欄位_2)__

```
params.require(:person).permit(:name, :age)
```

基本上就是這樣用。
