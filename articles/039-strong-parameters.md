# [Strong Parameters](https://github.com/rails/strong_parameters)

Rails 4 引進了一個新的保護機制：Strong Parameters，譯作健壯參數、強壯參數等。

但我認為譯作“安全參數”、“允許參數”較好。

## 什麼是 Strong Parameters?

在建模或更新 Active Record 物件時，會有 Mass assignment 的問題。

Mass assignment 就是建模或更新時，傳入 hash 參數，一次給多個欄位賦值：

```ruby
# params[:book] => { name: 'Ruby on Rails 4', who: 'Juanito Fatas', role: :reviewer }

def create
  @ruby_on_rails4 = Book.create(params[:book])
end

def update
  @ruby_on_rails4 = Book.update(params[:book])
end
```

這裡看到角色是 Reviewer，若角色被惡意改成擁有最高權限的角色，如作者，則會有安全性問題。

此時便需要建立白名單機制 ＋ `attr_accessible` 或是 `attr_protected` 來確保允許哪些參數可以大量賦值。

更詳細的內容可以參考業界先進[張文鈿（_ihower_）先生](https://ihower.tw/)於 [《Ruby on Rails 實戰聖經》網路安全](http://ihower.tw/rails3/security.html)一章，關於大量賦值（Mass assignment）的說明。

Rails 4 推出了 Strong Parameters。

現在所有參數的核定，交由 Controller 處理，由 Controller 決定，哪些參數可以大量賦值：

```ruby
class BookController < ActionController::Base
  def create
    Book.create(person_params)
  end

  def update
    book = Book.find(params[:id])
    book.update(book_params)
    redirect_to book
  end

  private

    def person_params
      params.require(:book).permit(:name, :who)
    end
end
```

原本的

看到 private 方法有一個 `book_params`，需要（`require`）用到那個 `:book` model，並允許（`permit`）哪些欄位做大量賦值。


__params.需要(:model_name).允許(:欄位_1, :欄位_2)__

```
params.require(:person).permit(:name, :age)
```

基本上就是這樣用，依此類推。
