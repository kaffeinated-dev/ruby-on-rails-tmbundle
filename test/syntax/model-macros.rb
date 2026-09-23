# SYNTAX TEST "source.ruby.rails" "model macros (Rails 7–8)"

class User < ApplicationRecord
  primary_abstract_class
# ^^^^^^^^^^^^^^^^^^^^^^ support.function.activerecord.rails
  connects_to database: { writing: :primary, reading: :replica }
# ^^^^^^^^^^^ support.function.activerecord.rails
  query_constraints :tenant_id, :id
# ^^^^^^^^^^^^^^^^^ support.function.activerecord.rails

  has_secure_password
# ^^^^^^^^^^^^^^^^^^^ support.function.activerecord.rails
  has_secure_token :api_key
# ^^^^^^^^^^^^^^^^ support.function.activerecord.rails
  generates_token_for :password_reset, expires_in: 15.minutes
# ^^^^^^^^^^^^^^^^^^^ support.function.activerecord.rails
  encrypts :ssn, deterministic: true
# ^^^^^^^^ support.function.activerecord.rails
  store_accessor :settings, :theme
# ^^^^^^^^^^^^^^ support.function.activerecord.rails
  delegated_type :entryable, types: %w[Message Comment]
# ^^^^^^^^^^^^^^ support.function.activerecord.rails

  validates_with EmailValidator
# ^^^^^^^^^^^^^^ support.function.activerecord.rails
  validates_absence_of :spam
# ^^^^^^^^^^^^^^^^^^^^ support.function.activerecord.rails
  validates_comparison_of :ends_at, greater_than: :starts_at
# ^^^^^^^^^^^^^^^^^^^^^^^ support.function.activerecord.rails

  around_save :log_timing
# ^^^^^^^^^^^ support.function.activerecord.rails
  around_create :x
# ^^^^^^^^^^^^^ support.function.activerecord.rails
  around_update :x
# ^^^^^^^^^^^^^ support.function.activerecord.rails
  around_destroy :x
# ^^^^^^^^^^^^^^ support.function.activerecord.rails
  after_find :x
# ^^^^^^^^^^ support.function.activerecord.rails
  after_touch :x
# ^^^^^^^^^^^ support.function.activerecord.rails
  after_commit :x, on: :create
# ^^^^^^^^^^^^ support.function.activerecord.rails
  after_rollback :x
# ^^^^^^^^^^^^^^ support.function.activerecord.rails
  after_create_commit :x
# ^^^^^^^^^^^^^^^^^^^ support.function.activerecord.rails
  after_update_commit :x
# ^^^^^^^^^^^^^^^^^^^ support.function.activerecord.rails
  after_destroy_commit :x
# ^^^^^^^^^^^^^^^^^^^^ support.function.activerecord.rails
  after_save_commit :x
# ^^^^^^^^^^^^^^^^^ support.function.activerecord.rails

  has_one_attached :avatar
# ^^^^^^^^^^^^^^^^ support.function.activestorage.rails
# ^^^^^^^^^^^^^^^^ - support.function.activerecord.rails
  has_many_attached :photos
# ^^^^^^^^^^^^^^^^^ support.function.activestorage.rails
  has_rich_text :bio
# ^^^^^^^^^^^^^ support.function.actiontext.rails

  broadcasts
# ^^^^^^^^^^ support.function.turbo.rails
  broadcasts_to ->(user) { [user.account, :users] }
# ^^^^^^^^^^^^^ support.function.turbo.rails
  broadcasts_refreshes
# ^^^^^^^^^^^^^^^^^^^^ support.function.turbo.rails
  broadcasts_refreshes_to :account
# ^^^^^^^^^^^^^^^^^^^^^^^ support.function.turbo.rails
end

class Preferences < ApplicationRecord
  # ‘attribute’ and ‘store’ are common variable names, so they are only
  # highlighted as the first word on a line, followed by an argument.
  attribute :theme, :string, default: "light"
# ^^^^^^^^^ support.function.activerecord.rails
  store :settings, accessors: [:color], coder: JSON
# ^^^^^ support.function.activerecord.rails

  def first_attribute
    attribute = attributes.first
#   ^^^^^^^^^ - support.function.activerecord.rails
    store = Store.find(1)
#   ^^^^^ - support.function.activerecord.rails
    cache.store :key, attribute
#         ^^^^^ - support.function.activerecord.rails
#                     ^^^^^^^^^ - support.function.activerecord.rails
  end
end
