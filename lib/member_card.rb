# frozen_string_literal: true

require 'scraped'

class MemberCard < Scraped::HTML
  field :id do
    noko.at_css('button @onclick').text[/\d+/]
  end

  field :name do
    noko.at_css('header h5').text.tidy
  end

  field :party do
    noko.xpath('div/p/child::text()').last.text.split.first.tidy
  end

  field :constituency do
    noko.at_css('center b').text.tidy
  end

  field :source do
    url.split('?').first + '?mp=' + id
  end
end
