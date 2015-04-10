module Cursor
  module ConfigurationMethods
    extend ActiveSupport::Concern

    module ClassMethods
      # Overrides the default +per_page+ value per model
      #   class Article < ActiveRecord::Base
      #     paginates_per 10
      #   end
      def paginates_per(val)
        @_default_per_page = val
      end

      # This model's default +per_page+ value
      # returns +default_per_page+ value unless explicitly overridden via <tt>paginates_per</tt>
      def default_per_page
        (defined?(@_default_per_page) && @_default_per_page) || Cursor.config.default_per_page
      end

      # Overrides the max +per_page+ value per model
      #   class Article < ActiveRecord::Base
      #     max_paginates_per 100
      #   end
      def max_paginates_per(val)
        @_max_per_page = val
      end

      # This model's max +per_page+ value
      # returns +max_per_page+ value unless explicitly overridden via <tt>max_paginates_per</tt>
      def max_per_page
        (defined?(@_max_per_page) && @_max_per_page) || Cursor.config.max_per_page
      end

      # Overrides the default +paginate_by+ field per model
      #   class Article < ActiveRecord::Base
      #     paginate_by :created_at, { processors: [:to_i] }
      #   end
      def paginate_by(field, options = {})
        if column_names.include?(field.to_s)
          @_default_paginate_by = field
          @_cursor_processors   = options[:processors]
        else
          raise ArgumentError.new('Field is not a model column')
        end
      end

      # This model's default +paginate_by+ field
      # returns +default_paginate_by+ value unless explicitly overridden via <tt>paginate_by</tt>
      def default_paginate_by
        (defined?(@_default_paginate_by) && @_default_paginate_by) || Cursor.config.default_paginate_by
      end

      # This model's cursor field +processors+
      # returns +nil+ unless explicitly overridden via <tt>paginate_by</tt>
      def cursor_processors
        (defined?(@_cursor_processors) && @_cursor_processors) || []
      end
    end
  end
end
