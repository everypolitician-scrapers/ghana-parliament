#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'

# require 'open-uri/cached'
# OpenURI::Cache.cache_path = '.cache'
require 'scraped_page_archive/open-uri'

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def datefrom(date)
  return if date.empty?
  Date.parse(date)
end

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

class MemberPage < Scraped::HTML
  decorator Scraped::Response::Decorator::AbsoluteUrls

  field :id do
    url[/(\d+)$/, 1]
  end

  field :name do
    box.at_css('.left_subheaders').text
  end

  field :image do
    # The profile <img> for two MPs has an erroneous src attribute
    # http://www.parliament.gh/parliamentarians/105
    # src="/userfiles/mps/404error.php.txt.txt" and
    # "http://www.parliament.gh/userfiles/mps/"
    # They don't point to the member's image, so we don't want
    image_src unless image_src.include?('404error') ||
                     image_src == 'http://www.parliament.gh/userfiles/mps/'
  end

  field :constituency do
    box.at_css('div.content_subheader').text.tidy.match(/MP\s+for\s+(.*)\s+constituency,\s*(.*)/).captures.join(', ')
  end

  field :party do
    box.xpath('//strong[contains(text(),"Party")]/ancestor::td').last.css('span.content_txt').last.text.gsub(/\s*\(\s*M(ajor|inor)ity\s*\)\s*/, '').tidy
  end

  field :religion do
    following_td('Religion').first.text
  end

  field :birth_date do
    datefrom(following_td('Date of Birth').first.text).to_s
  end

  field :email do
    following_td('Email').first.text
  end

  field :term do
    6
  end

  private

  def box
    noko.css('.content_text_column')
  end

  def following_td(text)
    box.xpath('//strong[contains(text(),"%s")]/following::td' % text)
  end

  def image_src
    box.at_css('img[src*="/userfiles/"]/@src').text
  end
end

def scrape_list(url)
  warn "Getting #{url}"
  page = MembersPage.new(response: Scraped::Request.new(url: url).response)
  page.mp_urls.each do |mp_url|
    scrape_mp(mp_url)
  end

  scrape_list(page.next_page) unless page.next_page.empty?
end

def scrape_mp(url)
  data = MemberPage.new(response: Scraped::Request.new(url: url).response).to_h
  # puts data
  ScraperWiki.save_sqlite(%i[id term], data)
end

ScraperWiki.sqliteexecute('DELETE FROM data') rescue nil
scrape_list 'http://www.parliament.gh/parliamentarians'
