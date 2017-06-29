# frozen_string_literal: true

require 'scraped'

class MembersPage < Scraped::HTML
  field :mp_urls do
    noko.css('#mid_content_conteiner .mp_repeater').map do |mpbox|
      mpbox.at_css('a[@href*="/parliamentarians/"]/@href').text
    end
  end

  field :next_page do
    noko.css('span.content_txt').xpath('.//a[contains(text(),">")]/@href').text
  end
end
