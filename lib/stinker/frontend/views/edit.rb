module MyPrecious
  module Views
    class Edit < Layout
      include Editable

      attr_reader :page, :content

      def title
        "#{@page.title}"
      end

      def page_name
        @page.title || @page.name.gsub('-', ' ')
      end

      def footer
        if @footer.nil?
          if page = @page.footer
            @footer = page.raw_data
          else
            @footer = false
          end
        end
        @footer
      end

      def meta_fields
        fields = @site.content_types[content_type] || {}
        fields.collect do |field, value_type|
          my_val =  (@page.meta_data ? (@page.meta_data[field] || "") : "")
          {"field_name" => field, 
            "human_field_name" => field.capitalize, 
            "field_value" => my_val
          }.merge(field_info(value_type, my_val))
        end
      end

      def field_info(type, val = nil)
        case type
        when "text"
          {"is_text" => true, "field_type" => "text"}
        when "fulltext"
          {"is_fulltext" => true, "field_type" => "fulltext"}
        when "image"
          {"is_image" => true, "field_type" => "image", "field_image_list" => image_list(val)}
        when "asset"
          {"is_asset" => true, "field_type" => "asset", "field_assets_list" => assets_list(val)}
        else
          {"field_type" => "unknown"}
        end
      end

      def has_meta_fields
        meta_fields.size > 0
      end

      def sidebar
        if @sidebar.nil?
          if page = @page.sidebar
            @sidebar = page.raw_data
          else
            @sidebar = false
          end
        end
        @sidebar
      end

      def is_create_page
        false
      end

      def is_edit_page
        true
      end

      def format
        @format = (@page.format || false) if @format.nil?
        @format.to_s.downcase
      end
    end
  end
end
