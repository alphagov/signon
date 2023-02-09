module HtmlTableHelpers
  def index_of_column_with_header(column_name)
    page.all(:css, "th").map(&:text).find_index(column_name)
  end

  def find_row_by_column_contents(column_name, text_to_match)
    selected_column_index = index_of_column_with_header(column_name)
    page.find(:css, "tbody")
        .all(:css, "tr")
        .map { |row| row.all(:css, "td") }
        .find { |row| row[selected_column_index].text == text_to_match }
  end
end
