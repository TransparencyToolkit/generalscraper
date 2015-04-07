require 'active_support/time'
require 'mechanize'

module ProxyManager 
  # Get the page with a proxy
  def getPage(url, form_input = nil)
    agent = Mechanize.new do |a|
      a.user_agent_alias = "Linux Firefox"
      a.set_proxy(getRandomProxy, 80)
    end

    if form_input
      gform = agent.get(url).form("f")
      gform.q = form_input
      return agent.submit(gform, gform.buttons.first)
    else
      return agent.get(url)
    end
  end

  # Choose a random proxy
  def getRandomProxy
    max = @proxylist.length
    chosen = @proxylist[Random.rand(max)]

    # Only use proxy if it hasn't been used in last 20 seconds
    if !@usedproxies[chosen] || @usedproxies[chosen] < Time.now-20
      @usedproxies[chosen] = Time.now
      return chosen
    else
      sleep(0.5)
      getRandomProxy
    end
  end
end
