# SYNTAX TEST "source.ruby.rails" "routes.rb"

Rails.application.routes.draw do
# <----- meta.rails.routes support.class.ruby
  resources :posts do
# ^^^^^^^^^ meta.rails.routes
    member do
#   ^^^^^^ meta.rails.routes
      get :preview
#     ^^^ meta.rails.routes
    end
  end

  root "posts#index"
# ^^^^ meta.rails.routes
end

Blog::Application.routes.draw do
# <---- meta.rails.routes
  resources :comments
# ^^^^^^^^^ meta.rails.routes
end

MyEngine::Engine.routes.draw do
# <-------- meta.rails.routes
  resources :widgets
# ^^^^^^^^^ meta.rails.routes
end
