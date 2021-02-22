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
require 'cursor/hooks'


if defined? ::Rails::Railtie
  require 'cursor/railtie'
  require 'cursor/engine'
end
