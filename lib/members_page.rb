# frozen_string_literal: true

require 'scraped'
require_relative './member_card'

class MembersPage < Scraped::HTML
  field :member_cards do
    noko.css('.card').map do |card|
      (fragment card => MemberCard).to_h
    end
  end

  field :next_page do
    noko.css('span.content_txt').xpath('.//a[contains(text(),">")]/@href').text
  end
end
