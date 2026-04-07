class NewsletterSubscription < ApplicationRecord
  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: { case_sensitive: false }

  before_create { self.subscribed_at = Time.current }
  before_save   { email.downcase! }
end
