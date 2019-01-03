module Healthcheck
  class ApiTokens
    WARNING_THRESHOLD = 1.year.to_i
    CRITICAL_THRESHOLD = 1.month.to_i

    QUERY = <<-SQL.freeze
      SELECT users.name, oauth_applications.name FROM oauth_access_tokens
      INNER JOIN users ON users.id = resource_owner_id
      INNER JOIN oauth_applications ON oauth_applications.id = application_id
      WHERE oauth_access_tokens.revoked_at IS NULL
      AND users.api_user = TRUE
      AND (oauth_access_tokens.expires_in -
          (unix_timestamp(now()) -
           unix_timestamp(oauth_access_tokens.created_at))) < %<threshold>s
    SQL

    def name
      :api_tokens
    end

    def details
      { warnings: warnings - criticals, criticals: criticals }
    end

    def status
      return GovukHealthcheck::CRITICAL if criticals.any?

      return GovukHealthcheck::WARNING if warnings.any?

      GovukHealthcheck::OK
    end

  private

    def warnings
      @warnings ||= connection.execute(QUERY % { threshold: WARNING_THRESHOLD }).to_a
    end

    def criticals
      @criticals ||= connection.execute(QUERY % { threshold: CRITICAL_THRESHOLD }).to_a
    end

    def connection
      ActiveRecord::Base.connection
    end
  end
end
