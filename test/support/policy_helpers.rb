module PolicyHelpers
  def permit?(user, record, action)
    self.class.to_s.gsub(/Test/, "").constantize.new(user, record).public_send("#{action}?")
  end

  def forbid?(*args)
    !permit?(*args)
  end
end
