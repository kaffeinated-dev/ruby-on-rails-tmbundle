# SYNTAX TEST "source.ruby.rails" "controllers"

class UsersController < ApplicationController
# <----- meta.rails.controller keyword.control.class.ruby
  before_filter :authenticate
# ^^^^^^^^^^^^^ meta.rails.controller support.function.actionpack.rails
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
# ^^^^^^^^^^^ meta.rails.controller support.function.actionpack.rails
  helper_method :current_user
# ^^^^^^^^^^^^^ meta.rails.controller support.function.actionpack.rails

  def show
    redirect_to root_path
#   ^^^^^^^^^^^ meta.rails.controller support.function.actionpack.rails
  end
end
