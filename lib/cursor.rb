require 'active_support/lazy_load_hooks'

ActiveSupport.on_load :active_record do
  module Cursor
  end

  # load Rails/Railtie
  begin
    require 'rails'
  rescue LoadError
    #do nothing
  end

  # load Cursor components
  require 'cursor/config'
  require 'cursor/models/page_scope_methods'
  require 'cursor/models/configuration_methods'

  if defined? ::Rails::Railtie
    require 'cursor/railtie'
    require 'cursor/engine'
  end

  require 'cursor/models/active_record_extension'
  ::ActiveRecord::Base.send :include, Cursor::ActiveRecordExtension
end
