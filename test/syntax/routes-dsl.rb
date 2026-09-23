# SYNTAX TEST "source.ruby.rails" "routing DSL"

Rails.application.routes.draw do
  root "posts#index"
# ^^^^ support.function.actiondispatch.rails
  resources :posts, shallow: true do
# ^^^^^^^^^ support.function.actiondispatch.rails
    resource :publication, only: %i[ create destroy ]
#   ^^^^^^^^ support.function.actiondispatch.rails
    member do
#   ^^^^^^ support.function.actiondispatch.rails
      post :archive
#     ^^^^ support.function.actiondispatch.rails
    end
    collection do
#   ^^^^^^^^^^ support.function.actiondispatch.rails
      get :drafts
#     ^^^ support.function.actiondispatch.rails
    end
    concerns :commentable
#   ^^^^^^^^ support.function.actiondispatch.rails
  end

  concern :commentable do
# ^^^^^^^ support.function.actiondispatch.rails
    resources :comments
  end

  namespace :admin do
# ^^^^^^^^^ support.function.actiondispatch.rails
    scope module: :reports do
#   ^^^^^ support.function.actiondispatch.rails
      patch "sync", to: "sync#update"
#     ^^^^^ support.function.actiondispatch.rails
      put "reset", to: "sync#reset"
#     ^^^ support.function.actiondispatch.rails
      delete "purge", to: "sync#purge"
#     ^^^^^^ support.function.actiondispatch.rails
    end
  end

  constraints subdomain: "api" do
# ^^^^^^^^^^^ support.function.actiondispatch.rails
    defaults format: :json do
#   ^^^^^^^^ support.function.actiondispatch.rails
      controller :status do
#     ^^^^^^^^^^ support.function.actiondispatch.rails
        match "ping", via: :all
#       ^^^^^ support.function.actiondispatch.rails
      end
    end
  end

  shallow do
# ^^^^^^^ support.function.actiondispatch.rails
    resources :boards
  end
  nested do
# ^^^^^^ support.function.actiondispatch.rails
  end
  get "old", to: redirect("/new")
#                ^^^^^^^^ support.function.actiondispatch.rails
  mount ActionCable.server => "/cable"
# ^^^^^ support.function.actiondispatch.rails
  direct(:homepage) { "https://rubyonrails.org" }
# ^^^^^^ support.function.actiondispatch.rails
  resolve("Basket") { [:basket] }
# ^^^^^^^ support.function.actiondispatch.rails
  draw :admin
# ^^^^ support.function.actiondispatch.rails
end

# Outside routes these are regular names.
class Client
  def fetch
    get "/posts"
#   ^^^ - support.function.actiondispatch.rails
    root = Pathname.new("/")
#   ^^^^ - support.function.actiondispatch.rails
  end
end
