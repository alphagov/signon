module CucumberRailsDebug
  def where
#    puts "#{@request.env["SERVER_NAME"]}#{@request.env["REQUEST_URI"]}"
  end

  def how
#    puts @request.parameters.inspect
  end

  def html
    puts page.html
#    puts @response.body.gsub("\n", "\n           ")
  end

  def display(decoration = "\n#{'*' * 80}\n\n")
    puts decoration
    yield
    puts decoration
  end
end

World(CucumberRailsDebug)

Then /debug/ do
  require 'ruby-debug'
  debugger
  stop_here = 1
end

Then /what\?/ do
  display do
    where
    html
    how
    where
  end
end
