module FlashHelpers
  def assert_flash_content(content)
    flash = find_flash

    case content
    when String
      assert flash.has_content?(content)
    when Array
      content.each { |item| assert flash.has_content?(item) }
    end
  end

  def refute_flash_content(content)
    flash = find_flash

    case content.class
    when String
      assert_not flash.has_content?(content)
    when Array
      content.each { |item| assert_not flash.has_content?(item) }
    end
  end

private

  def find_flash
    find("div[role='alert']")
  end
end
