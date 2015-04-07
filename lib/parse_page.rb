require 'uploadconvert'

module ParsePage
  # Get both page metadata and text
  def getPageData(url)
    begin
      pagehash = getMetadata(url)
      pagehash = getContent(url, pagehash)
      @output.push(pagehash)
    rescue
    end
  end

  # Get the page content by type of page
  def getContent(url, pagehash)
    if url.include? ".pdf"
      return getPDF(url, pagehash)
    else
      return getHTMLText(url, pagehash)
    end
  end

  # Download the page text
  def getHTMLText(url, pagehash)
    html = Nokogiri::HTML(getPage(url).body)
    pagehash[:text] = html.css("body").text.encode("UTF-8")
    return pagehash
  end

  # Download and extract text from PDF
  def getPDF(url, pagehash)
    `wget -P public/uploads #{url}`
    path = url.split("/")

    # OCR PDF and save fields
    u = UploadConvert.new("public/uploads/" + path[path.length-1].chomp.strip)
    pdfparse = JSON.parse(u.handleDoc)
    pdfparse.each{|k, v| pagehash[k] = v.encode("UTF-8")}
    return pagehash
  end

  # Get the page metadata
  def getMetadata(url)
    pagehash = Hash.new

    # Save URL and date retreived
    url.gsub!("%3F", "?")
    url.gsub!("%3D", "=")
    pagehash[:url] = url
    pagehash[:date_retrieved] = Time.now

    # Get title and meta tag info
    html = Nokogiri::HTML(getPage(url).body) # Eventually modify this
    pagehash[:title] = html.css("title").text.encode("UTF-8")
    html.css("meta").each do |m|
      if m
        pagehash[m['name']] = m['content']
      end
    end

    return pagehash
  end
end
