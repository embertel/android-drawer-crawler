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
    puts "This may take a moment..."
    `phantomjs load_ajax.js #{drawer_search_url} search_results.html`
    begin
      page = Nokogiri::HTML(open("search_results.html"))
    rescue OpenURI::HTTPError
      puts "Error: HTTP error in the given URL: #{play_store_url}."
      exit
    rescue OpenURI::HTTPRedirect
      puts "Error: HTTP redirect error in the given URL: #{play_store_url}."
      exit
    end
    page.css('div.gs-title a')
  end

  def scrape_result(app, result_url)
    puts "Fetching #{result_url}"
    begin
      page = Nokogiri::HTML(open(result_url))
    rescue OpenURI::HTTPError
      puts "Error: HTTP error in the given URL: #{play_store_url}."
      exit
    rescue OpenURI::HTTPRedirect
      puts "Error: HTTP redirect error in the given URL: #{play_store_url}."
      exit
    end
    app_info = App.new(app.name)
    title = page.css('h1.entry-title').text.split(' ')
    app_info.title = title.first(title.length - 1).join(' ')
    app_info.creator = page.css('a.devlink').text
    # issue: developer is sometimes abbreviated on androiddrawer (eg Corporation -> Corp.)
    if app_info.title.include? app.title #and app_info.creator == app.creator
      app_info.url = page.css('a.download-btn')[0]["href"]
      app_info.version = title.last
      puts "#{app_info.title} #{app_info.version}: #{app_info.url}"
      app_info
    else
      puts "#{app_info.title} does not include #{app.title}"
    end
  end

  def start_main(apk_name)
    page = download_file(apk_name)
    app = extract_features(apk_name, page)
    search_results = search_drawer(app.title)
    search_results.each do |result|
        #result['data-ctorig'] is the url to the app page
        if !result['data-ctorig'].nil? and result['data-ctorig'].include? app.title.downcase
            # issue: scrape_result is executing twice for each result
            # could be an issue in search_drawer
            apk = scrape_result(app, result['data-ctorig'])
            `wget '#{apk.url}' -O #{apk.title}-#{apk.version}.apk -P #{apk_name}`
        end
    end
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
