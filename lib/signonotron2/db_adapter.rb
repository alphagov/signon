module Signonotron2
  class DbAdapter
    include Singleton

    def mysql?
      adapter == "mysql"
    end

    def postgresql?
      adapter == "postgresql"
    end

  private

    def adapter
      @adapter ||= ENV.fetch("SIGNONOTRON2_DB_ADAPTER", "mysql")
    end
  end
end
