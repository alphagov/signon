module RootHelper
  def application_name
    if @application.present?
      @application.name
    else
      "this application"
    end
  end
end
