module ApplicationHelper
  def nav_link(text, link)
    recognized = Rails.application.routes.recognize_path(link)
    if recognized[:controller] == params[:controller] &&
       recognized[:action] == params[:action]
        content_tag(:li, :class => "active") do
          link_to( text, link)
        end
    else
      content_tag(:li) do
        link_to( text, link)
      end
    end
  end
end
