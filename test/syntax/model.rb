# SYNTAX TEST "source.ruby.rails" "models"

class User < ApplicationRecord
# <----- meta.rails.model keyword.control.class.ruby
  has_many :posts
# ^^^^^^^^ meta.rails.model support.function.activerecord.rails
  belongs_to :account
# ^^^^^^^^^^ meta.rails.model support.function.activerecord.rails
  validates :email, presence: true
# ^^^^^^^^^ meta.rails.model support.function.activerecord.rails
  scope :active, -> { where(active: true) }
# ^^^^^ meta.rails.model support.function.activerecord.rails
  enum :status, [:draft, :published]
# ^^^^ meta.rails.model support.function.activerecord.rails
  normalizes :email, with: -> email { email.strip.downcase }
# ^^^^^^^^^^ meta.rails.model support.function.activerecord.rails
  after_initialize :set_defaults
# ^^^^^^^^^^^^^^^^ meta.rails.model support.function.activerecord.rails
  has_many :comments, scope: nil
#                     ^^^^^ - support.function.activerecord.rails
end

class LegacyUser < ActiveRecord::Base
# <----- meta.rails.model keyword.control.class.ruby
end
