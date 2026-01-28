module Components
  module TableHelper
    def self.helper(context, caption = nil, opt = {})
      builder = TableBuilder.new(context.tag)

      classes = %w[app-c-table govuk-table]
      classes << "govuk-table--sortable" if opt[:sortable]
      classes << opt[:classes] if opt[:classes]

      caption_classes = %w[govuk-table__caption]
      caption_classes << opt[:caption_classes] if opt[:caption_classes]

      context.tag.table class: classes, id: opt[:table_id] do
        context.concat context.tag.caption caption, class: caption_classes
        yield(builder)
      end
    end

    class TableBuilder
      include ActionView::Helpers::UrlHelper
      include ActionView::Helpers::TagHelper

      attr_reader :tag

      def initialize(tag)
        @tag = tag
      end

      def head
        tag.thead class: "govuk-table__head" do
          tag.tr class: "govuk-table__row", role: "row" do
            yield(self)
          end
        end
      end

      def body
        tag.tbody class: "govuk-table__body" do
          yield(self)
        end
      end

      def row
        tag.tr class: "govuk-table__row js-govuk-table__row", role: "row" do
          yield(self)
        end
      end

      def header(str, opt = {})
        classes = %w[govuk-table__header]
        classes << opt[:classes] if opt[:classes]
        classes << "govuk-table__header--#{opt[:format]}" if opt[:format]
        classes << "govuk-table__header--active" if opt[:sort_direction]
        link_classes = %w[app-table__sort-link]
        link_classes << "app-table__sort-link--#{opt[:sort_direction]}" if opt[:sort_direction]
        str = link_to str, opt[:href], class: link_classes, data: opt[:data_attributes] if opt[:href]
        tag.th str, class: classes, scope: opt[:scope] || "col", role: "columnheader"
      end

      def cell(str, opt = {}, &block)
        classes = %w[govuk-table__cell]
        classes << opt[:classes] if opt[:classes]
        classes << "govuk-table__cell--#{opt[:format]}" if opt[:format]
        classes << "govuk-table__cell--empty" unless str || block_given?
        str ||= "Not set"

        if block_given?
          tag.td class: classes, role: "cell", &block
        else
          tag.td str, class: classes, role: "cell"
        end
      end
    end
  end
end
