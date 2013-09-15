# 使用 Thor 打造命令行工具

## [Thor][thor] 是什麼?

用來建造命令行的工具包，其實就是個 gem。超過 200+ 以上的 Gems 皆選擇採用 Thor 來打造命令行工具：如 Rails Generator、Vagrant、Bundler ..等。

## 安裝

```ruby
gem install thor
```

## 起步

一個 Thor 類別會成為可執行檔，類別內公有的 instance method 便是子命令。

```ruby
class MyCLI < Thor
  desc "hello NAME", "say hello to NAME"
  def hello(name)
    puts "Hello #{name}"
  end
end
```

用 `MyCLI.start(ARGV)` 來啟動命令行工具，通常會將它放在 Gem 的 `bin/` 目錄下。

若沒傳參數給 start，則預設會印出類別裡的 help 訊息。

舉例，先創一個 `cli` 檔案：

`touch cli`，內容如下：

```ruby
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

```bash
$ ruby ./cli

Tasks:
  cli hello NAME   # say hello to NAME
  cli help [TASK]  # Describe available tasks or one specific task
```

傳個參數看看：

```bash
$ ruby ./cli hello Juanito
Hello Juanito
```

參數數目不對怎麼辦？

```bash
$ ruby ./cli hello
"hello" was called incorrectly. Call as "test.rb hello NAME".
```

Thor 會幫你印出有用的錯誤訊息。

也可讓參數變成選擇性傳入。

```ruby
class MyCLI < Thor
  desc "hello NAME", "say hello to NAME"
  def hello(name, from=nil)
    puts "from: #{from}" if from
    puts "Hello #{name}"
  end
end
```

執行看看：

```bash
$ ruby ./cli hello "Juanito Fatas"
Hello Juanito Fatas

$ ruby ./cli hello "Juanito Fatas" "Ana Aguilar"
from: Ana Aguilar
Hello Juanito Fatas
```

## 長說明 `long_desc`

預設 Thor 使用命令上方的 `desc` 作為命令的簡短說明。你也可以提供更完整的說明。使用 `long_desc` 即可。

```ruby
class MyCLI < Thor
  desc "hello NAME", "say hello to NAME"
  long_desc <<-LONGDESC
    `cli hello` will print out a message to a person of your
    choosing.

    You can optionally specify a second parameter, which will print
    out a from message as well.

    > $ cli hello "Juanito Fatas" "Ana Aguilar"

    > from: Ana Aguilar
  LONGDESC
  def hello(name, from=nil)
    puts "from: #{from}" if from
    puts "Hello #{name}"
  end
end
```

預設 `long_desc` 會根據終端寬度斷行，可以在行首加入 `\x5` ，如此便會在行與行之間加入 hard break。

```ruby
class MyCLI < Thor
  desc "hello NAME", "say hello to NAME"
  long_desc <<-LONGDESC
    `cli hello` will print out a message to a person of your
    choosing.

    You can optionally specify a second parameter, which will print
    out a from message as well.

    > $ cli hello "Juanito Fatas" "Ana Aguilar"

    \x5> from: Ana Aguilar
  LONGDESC
  def hello(name, from=nil)
    puts "from: #{from}" if from
    puts "Hello #{name}"
  end
end
```

多數情況下可將完整說明存至別的文件，並使用 `File.read` 讀進來，這樣可大幅提高整個 CLI 程式的可讀性。

## 選項與旗幟 (Options and Flags)

```ruby
class MyCLI < Thor
  desc "hello NAME", "say hello to NAME"
  option :from
  def hello(name)
    puts "from: #{options[:from]}" if options[:from]
    puts "Hello #{name}"
  end
end
```

使用者便可透過 `--from` 傳入參數。

```ruby
$ ruby ./cli hello --from "Ana Aguilar" Juanito
from: Ana Aguilar
Hello Juanito

$ ruby ./cli hello Juanito --from "Ana Aguilar"
from: Ana Aguilar
Hello Juanito
```

Option 也可有類型。

```ruby
class MyCLI < Thor
  option :from
  option :yell, :type => :boolean
  desc "hello NAME", "say hello to NAME"
  def hello(name)
    output = []
    output << "from: #{options[:from]}" if options[:from]
    output << "Hello #{name}"
    output = output.join("\n")
    puts options[:yell] ? output.upcase : output
  end
end
```

比如 `--yell` 是一個布林選項。即使用者有給 `--yell` 時，`options[:yell]` 為真、沒給入時 `options[:yell]` 為假。

```bash
$ ./cli hello --yell juanito --from "Ana Aguilar"
FROM: ANA AGUILAR
HELLO JUANITO

$ ./cli hello juanito --from "Ana Aguilar" --yell
FROM: ANA AGUILAR
HELLO JUANTIO
```

位置可放前面或後面。

亦可指定某個參數是必須傳入的。

```ruby
class MyCLI < Thor
  option :from, :required => true
  option :yell, :type => :boolean
  desc "hello NAME", "say hello to NAME"
  def hello(name)
    output = []
    output << "from: #{options[:from]}" if options[:from]
    output << "Hello #{name}"
    output = output.join("\n")
    puts options[:yell] ? output.upcase : output
  end
end
```

如此例的 `option :from, :required => true`，沒給的話會有提示如下錯誤：

```bash
$ ./cli hello Juanito
No value provided for required options '--from'
```

option 可傳入的 metadata 清單：

* `:desc` option 的描述。使用 help 查看命令說明時，這裡給入的文字，出現在 option 之後。

* `:banner` option 的短描述。沒給的話，使用 help 查看命令說明時，會輸出 flag 的大寫，如 `from` 就輸出 `FROM`。

* `:required` 表示這個選項是必要的。

* `:default` 若 option 沒給時的預設值。注意，`:default` 與 `required` 互相衝突，不能一起用。


* `:type` 有這五種：`:string`、`:hash`、`:array`、`:numeric`、`:boolean`。

* `:aliases:` 此選項的別名。如 `--version` 提供 `-v`。

上例若選項僅需指定類型時，可以寫成一行：

```ruby
  option :from, :required => true
  option :yell, :type => :boolean

```

等同於

```ruby
  option :from, :required, :yell => :boolean
```

`:type` 可用 `:required` 聲明，會自動變成 `:string`。

## Class Options

可以用 `class_option` 指定整個類共用的選項。跟一般選項接受的參數一樣，但 `class_option` 對所有命令都生效。


```ruby
class MyCLI < Thor
  class_option :verbose, :type => :boolean

  desc "hello NAME", "say hello to NAME"
  options :from => :required, :yell => :boolean
  def hello(name)
    puts "> saying hello" if options[:verbose]
    output = []
    output << "from: #{options[:from]}" if options[:from]
    output << "Hello #{name}"
    output = output.join("\n")
    puts options[:yell] ? output.upcase : output
    puts "> done saying hello" if options[:verbose]
  end

  desc "goodbye", "say goodbye to the world"
  def goodbye
    puts "> saying goodbye" if options[:verbose]
    puts "Goodbye World"
    puts "> done saying goodbye" if options[:verbose]
  end
end
```

## 子命令

命令日趨複雜時，會想拆成子命令，像 `git remote` 這樣，`git remote` 是主命令、下面還有 `add`、`rename`、`rm`、`prune`、`set-head` 等子命令。

像 `git remote` 便可這麼實現：

```ruby
module GitCLI
  class Remote < Thor
    desc "add <name> <url>", "Adds a remote named <name> for the repository at <url>"
    long_desc <<-LONGDESC
      Adds a remote named <name> for the repository at <url>. The command git fetch <name> can then be used to create and update
      remote-tracking branches <name>/<branch>.

      With -f option, git fetch <name> is run immediately after the remote information is set up.

      With --tags option, git fetch <name> imports every tag from the remote repository.

      With --no-tags option, git fetch <name> does not import tags from the remote repository.

      With -t <branch> option, instead of the default glob refspec for the remote to track all branches under $GIT_DIR/remotes/<name>/, a
      refspec to track only <branch> is created. You can give more than one -t <branch> to track multiple branches without grabbing all
      branches.

      With -m <master> option, $GIT_DIR/remotes/<name>/HEAD is set up to point at remote's <master> branch. See also the set-head
      command.

      When a fetch mirror is created with --mirror=fetch, the refs will not be stored in the refs/remotes/ namespace, but rather
      everything in refs/ on the remote will be directly mirrored into refs/ in the local repository. This option only makes sense in
      bare repositories, because a fetch would overwrite any local commits.

      When a push mirror is created with --mirror=push, then git push will always behave as if --mirror was passed.
    LONGDESC
    option :t, :banner => "<branch>"
    option :m, :banner => "<master>"
    options :f => :boolean, :tags => :boolean, :mirror => :string
    def add(name, url)
      # implement git remote add
    end

    desc "rename <old> <new>", "Rename the remote named <old> to <new>"
    def rename(old, new)
    end
  end

  class Git < Thor
    desc "fetch <repository> [<refspec>...]", "Download objects and refs from another repository"
    options :all => :boolean, :multiple => :boolean
    option :append, :type => :boolean, :aliases => :a
    def fetch(respository, *refspec)
      # implement git fetch here
    end

    desc "remote SUBCOMMAND ...ARGS", "manage set of tracked repositories"
    subcommand "remote", Remote
  end
end
```

在 `Git` 類別中：

```ruby
subcommand "remote", Remote
```

指定了 `remote` 為 `Git` 的子命令。

`Remote` 類別裡的命令，可以透過 `parent_options` 選項來存取父命令的選項。

## 延伸閱讀

可以去研究 [Bundler](https://github.com/bundler/bundler) 的代碼。

## 其它相同的工具

### Ruby 官方

* [OptionParser](http://ruby-doc.org/stdlib-2.0.0/libdoc/optparse/rdoc/OptionParser.html)

### 第三方

* [Trollop](https://rubygems.org/gems/trollop)

* [Gli](https://rubygems.org/gems/gli)

* [Choice](https://rubygems.org/gems/choice)

* [Optiflag](https://rubygems.org/gems/optiflag)

[thor]: http://whatisthor.com