# 如何撰寫簡單的 Rake 任務

## 最簡單的例子

```ruby
task :hello_wold do
  puts 'Hello World!'
end
```

怎麼用？

```bash
$ rake hello_world
Hello World!
```

## 這種 `rake db:migrate` 有兩層的怎麼做?

```ruby
namespace :db do
  task :migrate do
  # ...
  end
end
```

## `rake -T` 看到的簡短敘述哪來的？

```ruby
desc "A hello world example!"
task :hello_wold do
  puts 'Hello World!'
end
```

## 怎麼在 B 任務執行之前先執行 A?

_A = :first, B = :second_

```ruby
namespace :dev do
  desc "first"
  task :first do
    puts "first do this."
  end

  desc "second"
  task :second => :first do
    puts "then do this"
  end
end
```

如何讓 C 任務在 A, B 都執行完後再執行？

_C = :third_

```ruby
namespace :dev do
  desc "first"
  task :first do
    puts "first do this."
  end

  desc "second"
  task :second => :first do
    puts "then do this"
  end

  task :third => [:second]
end
```

或是寫成這樣

```ruby
namespace :dev do
  desc "first"
  task :first do
    puts "first do this."
  end

  desc "second"
  task :second do
    puts "then do this"
  end

  task :third => [:first, :second]
end
```

注意到區塊是可選的，即 `:third` 任務無需使用 `do…end`。

## 延伸閱讀

[Rails Custom Rake Tasks](http://edgeguides.rubyonrails.org/command_line.html#custom-rake-tasks)
