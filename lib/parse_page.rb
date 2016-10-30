require 'uploadconvert'

module ParsePage
  # Get both page metadata and text
  def getPageData(url)
    page = @requests.get_page(url)
    html = Nokogiri::HTML(page)
    pagehash = getMetadata(url, html)
    pagehash = getContent(url, pagehash, html)
    return pagehash
  end

  # Get the page content by type of page
  def getContent(url, pagehash, html)
    if url.include? ".pdf"
      begin
        return getPDF(url, pagehash)
      rescue
        report_status("PDF parsing failed for "+url.to_s)
        return nil
      end
    else
      return getHTMLText(url, pagehash, html)
    end
  end

  # Download the page text
  def getHTMLText(url, pagehash, html)
    pagehash[:text] = fixEncode(html.css("body").text)
    return pagehash
  end

  # Download and extract text from PDF
  def getPDF(url, pagehash)
    `wget --tries=2 -P public/uploads #{url}`
    path = url.split("/")

    # OCR PDF and save fields
    u = UploadConvert.new("public/uploads/" + path[path.length-1].chomp.strip)
    pdfparse = JSON.parse(u.handleDoc)
    pdfparse.each{|k, v| pagehash[k] = fixEncode(v)}
    return pagehash
  end

  # Get the page metadata
  def getMetadata(url, html)
    pagehash = Hash.new

    # Save URL and date retreived
    url.gsub!("%3F", "?")
    url.gsub!("%3D", "=")
    pagehash[:url] = url
    pagehash[:date_retrieved] = Time.now

    # Get title and meta tag info
    pagehash[:page_title] = fixEncode(html.css("title").text)
    html.css("meta").each do |m|
      if m
        pagehash[m['name']] = fixEncode(m['content'])
      end
    end

    return pagehash
  end

  def fixEncode(str)
    if str.is_a?(String)
      return str.unpack('C*').pack('U*')
    else
      return str
    end
  end
end
