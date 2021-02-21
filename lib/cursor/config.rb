require 'active_support/configurable'

module Cursor
  # Configures global settings for Cursor
  #   Cursor.configure do |config|
  #     config.default_per_page = 10
  #   end
  class << self
    def configure
      yield config
    end

    def config
      @_config ||= Configuration.new
    end
  end

  class Configuration
    attr_accessor :default_paginate_by,
                  :default_per_page,
                  :max_per_page,
                  :page_method_name,
                  :before_param_name,
                  :after_param_name,
                  :since_param_name

    attr_writer :param_name

    def initialize
      @default_paginate_by = :id
      @default_per_page = 25
      @max_per_page = nil
      @page_method_name = :page
      @before_param_name = :before
      @after_param_name = :after
      @since_param_name = :since
    end

    # If param_name was given as a callable object, call it when returning
    def param_name
      @param_name.respond_to?(:call) ? @param_name.call : @param_name
    end
  end
end
