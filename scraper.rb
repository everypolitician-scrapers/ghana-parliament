#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'
# require 'scraped_page_archive/open-uri'

require_rel 'lib'

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
  puts data.reject { |_, v| v.to_s.empty? }.sort_by { |k, _| k }.to_h if ENV['MORPH_DEBUG']
  ScraperWiki.save_sqlite(%i[id term], data)
end

ScraperWiki.sqliteexecute('DROP TABLE data') rescue nil
scrape_list 'http://www.parliament.gh/parliamentarians'
