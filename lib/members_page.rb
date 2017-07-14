# frozen_string_literal: true

require 'scraped'
require_relative './member_card'

class MembersPage < Scraped::HTML
  decorator Scraped::Response::Decorator::CleanUrls

  field :member_cards do
    noko.css('.card').map do |card|
      (fragment card => MemberCard).to_h
    end
  end

  field :members_pages_urls do
    noko.css('.square @href').map(&:text)
  end
end
