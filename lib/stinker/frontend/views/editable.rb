module MyPrecious
  module Editable

    def escaped_name
      @page ? @page.fullname : @name
    end

    def content_type
      @meta ||= {}
      (@meta["content_type"].nil? || @meta["content_type"].empty?) ? "page" : @meta["content_type"] 
    end

    def content_types
      @site.content_types.map{|key, val| {"val" => key, "human" => key.capitalize}}
    end
    
    def image_list(selected = nil)
      @site.assets.select do |f|
        f.image?
      end.map do |f|
        my_path = f.path.gsub(/^#{@site.page_file_dir}/, '')
        {:path => my_path, :name => f.name, :selected => my_path == selected}
      end
    end

    def assets_list(selected = nil)
      @site.assets.map do |f|
        my_path = f.path.gsub(/^#{@site.page_file_dir}/, '')
        {:path => my_path, :name => f.name, :selected => my_path == selected}
      end
    end


    
    def formats(selected = @page.format)
      Stinker::Page::FORMAT_NAMES.select do |k, v|
        k == :markdown
      end.map do |key, val|
        { :name     => val,
          :id       => key.to_s,
          :selected => selected == key}
      end.sort do |a, b|
        a[:name].downcase <=> b[:name].downcase
      end
    end
  end
end
