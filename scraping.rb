#!/usr/bin/env ruby
require 'yaml'
require 'json'
require 'optparse'
require 'date'
require 'nokogiri'
require 'open-uri'
require_relative 'app'

class Scraping
  @@usage = "Usage: #{$PROGRAM_NAME} apk_name"
  BASE_URL = 'https://play.google.com'
  APPS_PATH = '/store/apps'
  QUERY_STRING = '/details?id='

  private
  def download_file(apk_name)
    play_store_url = BASE_URL + APPS_PATH + QUERY_STRING + apk_name
    puts "Fetching #{play_store_url}"
    begin
      page = Nokogiri::HTML(open(play_store_url))
    rescue OpenURI::HTTPError
      puts "Error: HTTP error in the given URL: #{play_store_url}."
      exit
    rescue OpenURI::HTTPRedirect
      puts "Error: HTTP redirect error in the given URL: #{play_store_url}."
      exit
    end
  end

  def extract_features(apk_name, page)
    app = App.new(apk_name)
    app.title = page.css('div.info-container div.document-title').text.strip
    title_arr = page.css('div.info-container .document-subtitle')
    app.creator = title_arr[0].text.strip
    puts "app.title: #{app.title}"
    puts "app.creator: #{app.creator}"
    app
  end

  def search_drawer(app_title)
    drawer_search_url = "http://www.androiddrawer.com/search-results/?q=" + app_title
    puts "Fetching #{drawer_search_url}"
    begin
      page = Nokogiri::HTML(open(drawer_search_url))
    rescue OpenURI::HTTPError
      puts "Error: HTTP error in the given URL: #{play_store_url}."
      exit
    rescue OpenURI::HTTPRedirect
      puts "Error: HTTP redirect error in the given URL: #{play_store_url}."
      exit
    end

    #the following would work if the search results weren't loaded dynamically...
    result_urls = page.css('div.gs-title a')
    puts "search result url: #{result_urls[0]['data-ctorig']}"
  end


  def start_main(apk_name)
    page = download_file(apk_name)
    app = extract_features(apk_name, page)
    search_drawer(app.title)
  end

  public
  def start_command_line(argv)
    begin
      opt_parser = OptionParser.new do |opts|
        opts.banner = @@usage
        opts.on('-h','--help', 'Show this help message and exit.') do
          puts opts
          exit
        end
      end
      opt_parser.parse!
    rescue OptionParser::AmbiguousArgument
      puts "Error: illegal command line argument."
      puts opt_parser.help()
      exit
    rescue OptionParser::InvalidOption
      puts "Error: illegal command line option."
      puts opt_parser.help()
      exit
    end
    if(argv[0].nil?)
      puts "Error: apk name is not specified."
      abort(@@usage)
    end
    start_main(argv[0])
  end
end

if __FILE__ ==$PROGRAM_NAME
  scraping = Scraping.new
  scraping.start_command_line(ARGV)
end
