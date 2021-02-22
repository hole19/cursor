module Cursor
  class Railtie < ::Rails::Railtie #:nodoc:
    initializer 'cursor' do |_app|
      # load static non-evaluated extensions methods before they are called
      # (devised to load the Rails testing environment correctly)
      Cursor::Hooks.before_init

      # evaluate dynamic extensions after Rails initialization
      # to enable custom configuration for gem defined models
      config.after_initialize do
        Cursor::Hooks.init
      end
    end
  end
end
