class Propagator
  def initialize(user, applications, updater, on_success)
    @user, @applications, @updater, @on_success = user, applications, updater, on_success
  end

  def attempt
    results = { successes: [], failures: [] }
    @applications.each do |application|
      begin
        @updater.call(@user, application)
        @on_success.call(@user, application)
      end
    end
    results
  end
end
