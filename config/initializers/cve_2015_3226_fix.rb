raise "Check monkey patch for CVE-2015-3226 is still needed" unless Rails::VERSION::STRING == '3.2.22'
module ActiveSupport
  module JSON
    module Encoding
      private
      class EscapedString
        def to_s
          self
        end
      end
    end
  end
end
