# SYNTAX TEST "source.ruby.rails" "Rails method names used as regular Ruby methods"

class Report
  def call
    items.filter { |item| item.visible? }
#         ^^^^^^ - support.function.actionpack.rails
    record.validate
#          ^^^^^^^^ - support.function.activerecord.rails
    object&.scope
#           ^^^^^ - support.function.activerecord.rails
    config.x.content_security_policy.img_src = "self"
#            ^^^^^^^^^^^^^^^^^^^^^^^ - support.function.actionpack.rails
    klass.has_one_attached :file
#         ^^^^^^^^^^^^^^^^ - support.function.activestorage.rails
    if respond_to?(:export)
#      ^^^^^^^^^^ - support.function.actionpack.rails
    end
    validate!
#   ^^^^^^^^ - support.function.activerecord.rails
  end
end

class PostsController < ApplicationController
  def index
    respond_to do |format|
#   ^^^^^^^^^^ support.function.actionpack.rails
      format.html { render :index }
#                   ^^^^^^ support.function.actionpack.rails
    end
  end
end

# Form builder methods are still highlighted when called on the builder.
form_for @post do |f|
  f.label :title
#   ^^^^^ support.function.viewhelpers.rails
  f.text_field :title
#   ^^^^^^^^^^ support.function.viewhelpers.rails
end
