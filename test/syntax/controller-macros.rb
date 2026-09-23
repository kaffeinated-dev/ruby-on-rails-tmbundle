# SYNTAX TEST "source.ruby.rails" "controller macros (Rails 5–8)"

class PostsController < ApplicationController
  before_action :set_post, only: %i[ show edit ]
# ^^^^^^^^^^^^^ support.function.actionpack.rails
  after_action :x
# ^^^^^^^^^^^^ support.function.actionpack.rails
  around_action :x
# ^^^^^^^^^^^^^ support.function.actionpack.rails
  skip_before_action :x
# ^^^^^^^^^^^^^^^^^^ support.function.actionpack.rails
  skip_after_action :x
# ^^^^^^^^^^^^^^^^^ support.function.actionpack.rails
  skip_around_action :x
# ^^^^^^^^^^^^^^^^^^ support.function.actionpack.rails
  prepend_before_action :x
# ^^^^^^^^^^^^^^^^^^^^^ support.function.actionpack.rails
  prepend_after_action :x
# ^^^^^^^^^^^^^^^^^^^^ support.function.actionpack.rails
  prepend_around_action :x
# ^^^^^^^^^^^^^^^^^^^^^ support.function.actionpack.rails
  append_before_action :x
# ^^^^^^^^^^^^^^^^^^^^ support.function.actionpack.rails
  append_after_action :x
# ^^^^^^^^^^^^^^^^^^^ support.function.actionpack.rails
  append_around_action :x
# ^^^^^^^^^^^^^^^^^^^^ support.function.actionpack.rails

  protect_from_forgery with: :exception
# ^^^^^^^^^^^^^^^^^^^^ support.function.actionpack.rails
  skip_forgery_protection
# ^^^^^^^^^^^^^^^^^^^^^^^ support.function.actionpack.rails
  http_basic_authenticate_with name: "dhh", password: "secret"
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ support.function.actionpack.rails
  allow_browser versions: :modern
# ^^^^^^^^^^^^^ support.function.actionpack.rails
  rate_limit to: 10, within: 3.minutes, only: :create
# ^^^^^^^^^^ support.function.actionpack.rails
  content_security_policy { |policy| policy.base_uri :self }
# ^^^^^^^^^^^^^^^^^^^^^^^ support.function.actionpack.rails
  content_security_policy_report_only
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ support.function.actionpack.rails
  permissions_policy { |policy| policy.camera :none }
# ^^^^^^^^^^^^^^^^^^ support.function.actionpack.rails
  wrap_parameters format: [:json]
# ^^^^^^^^^^^^^^^ support.function.actionpack.rails
  add_flash_types :warning
# ^^^^^^^^^^^^^^^ support.function.actionpack.rails
  default_form_builder AdminFormBuilder
# ^^^^^^^^^^^^^^^^^^^^ support.function.actionpack.rails
  param_encoding :show, :file_path, Encoding::ASCII_8BIT
# ^^^^^^^^^^^^^^ support.function.actionpack.rails
  skip_parameter_encoding :show
# ^^^^^^^^^^^^^^^^^^^^^^^ support.function.actionpack.rails
  append_view_path "app/views/themes"
# ^^^^^^^^^^^^^^^^ support.function.actionpack.rails
  prepend_view_path "app/views/overrides"
# ^^^^^^^^^^^^^^^^^ support.function.actionpack.rails
  view_cache_dependency { "theme" }
# ^^^^^^^^^^^^^^^^^^^^^ support.function.actionpack.rails
  log_at :debug, if: -> { cookies[:debug] }
# ^^^^^^ support.function.actionpack.rails
  etag { current_user&.id }
# ^^^^ support.function.actionpack.rails

  def show
    fresh_when @post
#   ^^^^^^^^^^ support.function.actionpack.rails
    if stale?(@post)
#      ^^^^^^ support.function.actionpack.rails
      expires_in 3.minutes, public: true
#     ^^^^^^^^^^ support.function.actionpack.rails
    end
    expires_now
#   ^^^^^^^^^^^ support.function.actionpack.rails
    http_cache_forever(public: true) { render }
#   ^^^^^^^^^^^^^^^^^^ support.function.actionpack.rails
    no_store
#   ^^^^^^^^ support.function.actionpack.rails
    html = render_to_string(partial: "post")
#          ^^^^^^^^^^^^^^^^ support.function.actionpack.rails
  end

  def update
    redirect_back fallback_location: root_path
#   ^^^^^^^^^^^^^ support.function.actionpack.rails
    redirect_back_or_to root_path
#   ^^^^^^^^^^^^^^^^^^^ support.function.actionpack.rails
    head :no_content
#   ^^^^ support.function.actionpack.rails
    respond_to { |format| format.json { head 204 } }
#                                       ^^^^ support.function.actionpack.rails
  end

  def download
    send_file @post.attachment_path
#   ^^^^^^^^^ support.function.actionpack.rails
    send_data @post.to_csv, filename: "post.csv"
#   ^^^^^^^^^ support.function.actionpack.rails
  end

  def authenticate
    authenticate_or_request_with_http_basic { |name, password| true }
#   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ support.function.actionpack.rails
    authenticate_with_http_basic { |name, password| true }
#   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ support.function.actionpack.rails
    request_http_basic_authentication
#   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ support.function.actionpack.rails
    http_basic_authenticate_or_request_with name: "a", password: "b"
#   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ support.function.actionpack.rails
    authenticate_or_request_with_http_token { |token, options| true }
#   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ support.function.actionpack.rails
    authenticate_with_http_token { |token, options| true }
#   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ support.function.actionpack.rails
    request_http_token_authentication
#   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ support.function.actionpack.rails
    authenticate_or_request_with_http_digest { |name| "secret" }
#   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ support.function.actionpack.rails
    authenticate_with_http_digest { |name| "secret" }
#   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ support.function.actionpack.rails
    request_http_digest_authentication
#   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ support.function.actionpack.rails
  end

  # ‘head’, ‘etag’, and ‘stale’ are also common names, so they are only
  # highlighted when used as controller methods.
  def not_macros
    head = nodes.head
#   ^^^^ - support.function.actionpack.rails
#                ^^^^ - support.function.actionpack.rails
    etag = compute_etag
#   ^^^^ - support.function.actionpack.rails
    stale = true
#   ^^^^^ - support.function.actionpack.rails
    Rails.cache.fetch(key, expires_in: 1.hour)
#                          ^^^^^^^^^^ - support.function.actionpack.rails
  end
end
