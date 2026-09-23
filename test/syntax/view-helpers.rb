# SYNTAX TEST "source.ruby.rails" "view helpers in Ruby files"

module PostsHelper
  def post_title(post)
    content_tag :h1, truncate(post.title, length: 60)
#   ^^^^^^^^^^^ meta.rails.helper support.function.viewhelpers.rails
#                    ^^^^^^^^ meta.rails.helper support.function.viewhelpers.rails
  end

  def post_link(post)
    link_to post.title, post, class: class_names("post", draft: post.draft?)
#   ^^^^^^^ support.function.viewhelpers.rails
#                                    ^^^^^^^^^^^ support.function.viewhelpers.rails
  end
end

class NotificationsController < ApplicationController
  def create
    flash[:notice] = helpers.link_to("View", @notification)
#                            ^^^^^^^ support.function.viewhelpers.rails
  end
end

# Outside views and helpers, generic names are regular methods.
class Status < ApplicationRecord
  def to_s
    label
#   ^^^^^ - support.function.viewhelpers.rails
    truncate
#   ^^^^^^^^ - support.function.viewhelpers.rails
    status.label
#          ^^^^^ - support.function.viewhelpers.rails
    job.submit
#       ^^^^^^ - support.function.viewhelpers.rails
  end
end
