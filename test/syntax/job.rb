# SYNTAX TEST "source.ruby.rails" "jobs"

class ApplicationJob < ActiveJob::Base
# <----- meta.rails.job
  retry_on ActiveRecord::Deadlocked
# ^^^^^^^^ meta.rails.job support.function.activejob.rails
  discard_on ActiveJob::DeserializationError
# ^^^^^^^^^^ meta.rails.job support.function.activejob.rails
end

class ExportJob < ApplicationJob
# <----- meta.rails.job
  queue_as :default
# ^^^^^^^^ support.function.activejob.rails
  queue_with_priority 10
# ^^^^^^^^^^^^^^^^^^^ support.function.activejob.rails
  limits_concurrency to: 1, key: ->(export) { export.account }
# ^^^^^^^^^^^^^^^^^^ support.function.activejob.rails
  after_discard { |job, error| report(error) }
# ^^^^^^^^^^^^^ support.function.activejob.rails
  before_enqueue :x
# ^^^^^^^^^^^^^^ support.function.activejob.rails
  after_enqueue :x
# ^^^^^^^^^^^^^ support.function.activejob.rails
  around_enqueue :x
# ^^^^^^^^^^^^^^ support.function.activejob.rails
  before_perform :x
# ^^^^^^^^^^^^^^ support.function.activejob.rails
  after_perform :x
# ^^^^^^^^^^^^^ support.function.activejob.rails
  around_perform :x
# ^^^^^^^^^^^^^^ support.function.activejob.rails

  def perform(export)
    export.build
  end
end

# Job tests are not jobs.
class ExportJobTest < ActiveJob::TestCase
# <----- - meta.rails.job
# <----- meta.rails.unit_test
end
