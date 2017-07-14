# frozen_string_literal: true

require 'scraped'

class MemberCard < Scraped::HTML
  field :id do
    member_link[/(\d+)/, 1]
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
    URI.join(url, member_link).to_s
  end

  private

  def member_link
    noko.at_css('button @onclick').text[/'(.*?)'/, 1]
  end
end
