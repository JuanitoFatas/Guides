# Gem Version Practice

```ruby
module YourGemName
  module VERSION
    MAJOR = 0
    MINOR = 0
    TINY  = 1
    PRE   = nil

    STRING = [MAJOR, MINOR, TINY, PRE].compact.join(".")
  end
end
```