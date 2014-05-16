require 'mechanize'
require 'json'
require 'nokogiri'
require 'open-uri'

class GeneralScraper
  def initialize(scrapesite, input)
   @input = input
   @scrapesite = scrapesite
   @output = Array.new
   @startindex = 10
  end

  # Searches for links on Google
  def search
    agent = Mechanize.new
    agent.user_agent_alias = 'Linux Firefox'
    gform = agent.get("http://google.com").form("f")
    gform.q = "site:" + @scrapesite + " " + @input
    page = agent.submit(gform, gform.buttons.first)
    examine(page)
  end
 
  # Examines a search page
  def examine(page)
    page.links.each do |link|
      if (link.href.include? @scrapesite) && (!link.href.include? "webcache") && (!link.href.include? "site:"+@scrapesite)
        saveurl = link.href.split("?q=")
        
        if saveurl[1]
          url = saveurl[1].split("&")
          getPage(url[0])
        end
      end

      if (link.href.include? "&sa=N") && (link.href.include? "&start=")
        url1 = link.href.split("&start=")
        url2 = url1[1].split("&sa=N")

        if url2[0].to_i == @startindex
          sleep(rand(30..90))
          @startindex += 10
          agent = Mechanize.new
          examine(agent.get("http://google.com" + link.href))
        end
      end
    end
  end

  # Scrape the page content
  def getPage(url)
    pagehash = Hash.new
    begin
      url.gsub!("%3F", "?")
      url.gsub!("%3D", "=")
      pagehash[:url] = url
      pagehash[:date_retrieved] = Time.now
      html = Nokogiri::HTML(open(url))
      pagehash[:title] = html.css("title").text
      html.css("meta").each do |m|
        if m
          pagehash[m['name']] = m['content']
        end
      end
      pagehash[:page] = html.css("body").text
      @output.push(pagehash)
    rescue
      puts "URL: " + url
    end
  end

  # Gets all data and returns in JSON
  def getData
    search
    return JSON.pretty_generate(@output)
  end
end

