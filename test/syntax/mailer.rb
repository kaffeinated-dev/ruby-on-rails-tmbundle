# SYNTAX TEST "source.ruby.rails" "mailers"

class ApplicationMailer < ActionMailer::Base
# <----- meta.rails.mailer
  default from: "from@example.com"
# ^^^^^^^ meta.rails.mailer support.function.actionmailer.rails
  layout "mailer"
# ^^^^^^ meta.rails.mailer support.function.actionpack.rails
end

class UserMailer < ApplicationMailer
# <----- meta.rails.mailer
  before_deliver :set_headers
# ^^^^^^^^^^^^^^ support.function.actionmailer.rails
  after_deliver :x
# ^^^^^^^^^^^^^ support.function.actionmailer.rails
  around_deliver :x
# ^^^^^^^^^^^^^^ support.function.actionmailer.rails

  def welcome
    attachments["terms.pdf"] = File.read("terms.pdf")
#   ^^^^^^^^^^^ meta.rails.mailer support.function.actionmailer.rails
    headers["X-Campaign"] = "welcome"
#   ^^^^^^^ meta.rails.mailer support.function.actionmailer.rails
    mail to: email_address_with_name(@user.email, @user.name), subject: "Welcome"
#   ^^^^ meta.rails.mailer support.function.actionmailer.rails
#            ^^^^^^^^^^^^^^^^^^^^^^^ meta.rails.mailer support.function.actionmailer.rails
  end
end

class DigestMailer < BaseMailer
# <----- meta.rails.mailer
end

# ‘default’, ‘mail’, ‘headers’, and ‘attachments’ are only highlighted in mailers.
class Settings
  def defaults
    default = {}
#   ^^^^^^^ - support.function.actionmailer.rails
    headers = {}
#   ^^^^^^^ - support.function.actionmailer.rails
    mail = Mail.new
#   ^^^^ - support.function.actionmailer.rails
  end
end

# Mailer tests and previews are not mailers.
class UserMailerTest < ActionMailer::TestCase
# <----- - meta.rails.mailer
# <----- meta.rails.unit_test
end

class UserMailerPreview < ActionMailer::Preview
# <----- - meta.rails.mailer
end
