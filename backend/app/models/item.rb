# frozen_string_literal: true
require "ruby/openai"

class Item < ApplicationRecord
  belongs_to :user
  has_many :favorites, dependent: :destroy
  has_many :comments, dependent: :destroy

  scope :sellered_by, ->(username) { where(user: User.where(username: username)) }
  scope :favorited_by, ->(username) { joins(:favorites).where(favorites: { user: User.where(username: username) }) }

  acts_as_taggable

  validates :title, presence: true, allow_blank: false
  validates :description, presence: true, allow_blank: false
  validates :slug, uniqueness: true, exclusion: { in: ['feed'] }

  before_validation do
    self.slug ||= "#{title.to_s.parameterize}-#{rand(36**6).to_s(36)}"
    unless self.image
      openai = OpenAI::Client.new(access_token: "#{ENV["OPENAI_API_KEY"]}")
      response = openai.Image.create(
        prompt="#{title.to_s}",
        n=1,
        size="256x256"
      )
      self.image = response['data'][0]['url']
    end
  end
end
