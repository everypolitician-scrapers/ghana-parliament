# frozen_string_literal: true

require 'scraped'

class MemberPage < Scraped::HTML
  decorator Scraped::Response::Decorator::CleanUrls

  field :id do
    url[/(\d+)$/, 1]
  end

  field :name do
    box.at_css('h4').text.sub('HON.', '').tidy
  end

  field :image do
    box.at_css('img @src').text
  end

  field :constituency do
    box.css('center').text[/MP for (.*)/, 1].tidy.chomp('.')
  end

  field :party do
    record_for('Party').split('(').first.tidy
  end

  field :religion do
    record_for('Religion')
  end

  field :birth_date do
    Date.parse(record_for('Date of Birth'))
  end

  field :email do
    record_for('Email')
  end

  private

  def box
    noko.css('#content')
  end

  def record_for(text)
    box.xpath('//b[contains(text(),"%s")]/following::td' % text).first.text
  end

  def datefrom(date)
    return if date.empty?
    Date.parse(date)
  end
end
