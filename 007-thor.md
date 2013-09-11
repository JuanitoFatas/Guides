# 使用 Thor 打造命令行工具

## [Thor][thor] 是什麼?

用來建造命令行的工具包，其實就是個 gem。超過 200+ 以上的 Gems 皆選擇採用 Thor 來打造命令行工具：如 Rails Generator、Vagrant、Bundler ..等。

## 安裝

```ruby
gem install thor
```

## 起步

一個 Thor 類別便是一個可執行檔，Public instance method 便是子命令。

```ruby
class MyCLI < Thor
  desc "hello NAME", "say hello to NAME"
  def hello(name)
    puts "Hello #{name}"
  end
end
```

`MyCLI.start(ARGV)` 來啟動命令行工具，通常你會將它放在 Gem 的 `bin/` 目錄下。

倘若沒傳參數給 start，則預設會印出類別裡的 help 訊息。

以下的範例，先創一個 `cli` 檔案：

`touch cli`，內容如下：

```
require "thor"

class MyCLI < Thor
  desc "hello NAME", "say hello to NAME"
  def hello(name)
    puts "Hello #{name}"
  end
end

MyCLI.start(ARGV)
```

執行這個檔案：

```
$ ruby ./cli

Tasks:
  cli hello NAME   # say hello to NAME
  cli help [TASK]  # Describe available tasks or one specific task
```

傳個參數看看：

```
$ ruby ./cli hello Juanito
Hello Juanito
```


[thor]: http://whatisthor.com