module Abilities
  Dir[File.dirname(__FILE__) + "/abilities/*.rb"].sort.each { |file| require file }
end
