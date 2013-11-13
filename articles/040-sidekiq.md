# Sidekiq

Sidekiq 用 threads 處理 background jobs。

* Compatible with Resque

要是有很多 backgroun jobs 但不是 thread-safe 的情況，用 Resque。

要是有很多 backgroun jobs ，且是 thread-safe 的情況，用 Sidekiq。

* 根據官方說法，Sidekiq 記憶體跟 Resque 比起來省 33 倍。

* [Sidekiq vs Rescue or delayed_job](https://github.com/mperham/sidekiq/wiki/FAQ#how-does-sidekiq-compare-to-resque-or-delayed_job)

* Sidekiq vs girl_friday

girl_friday run 在 Rails process

Sidekiq run 在 system process

* "Can't find ModelName with ID=12345" errors with Sidekiq?

Sidekiq job creation 移到 `after_commit :on => :create`

* Sidekiq 環境需求

Redis 2.4+

Rails 3.2+

