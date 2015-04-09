
module Cursor
  module ActiveRecordModelExtension
    extend ActiveSupport::Concern

    included do
      self.send(:include, Cursor::ConfigurationMethods)

      # Fetch the values at the specified page edge
      #   Model.page(after: 5)
      eval <<-RUBY
        def self.#{Cursor.config.page_method_name}(options={})
          (options || {}).to_hash.symbolize_keys!
          options[:direction] = options.keys.include?(Cursor.config.after_param_name) ? Cursor.config.after_param_name : Cursor.config.before_param_name

          on_cursor(options[options[:direction]], options[:direction]).
          on_since(options[Cursor.config.since_param_name]).
          in_direction(options[:direction]).
          limit(default_per_page).extending do
            include Cursor::PageScopeMethods
          end
        end
      RUBY

      def self.on_cursor cursor_value, direction
        if cursor_value.nil?
          where(nil)
        else
          where(["#{self.table_name}.#{self.default_page_by} #{direction == Cursor.config.after_param_name ? '>' : '<'} ?", cursor_value])
        end
      end

      def self.on_since since_value
        if since_value.nil?
          where(nil)
        else
          where("#{self.table_name}.#{self.default_page_by} > ?", since_value)
        end
      end

      def self.in_direction direction
        reorder("#{self.table_name}.#{self.default_page_by} #{direction == Cursor.config.after_param_name ? 'asc' : 'desc'}")
      end
    end
  end
end
