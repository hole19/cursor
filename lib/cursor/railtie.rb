module Cursor
  class Railtie < ::Rails::Railtie #:nodoc:
    initializer 'cursor' do |_app|
      # load configuration methods before they are called
      # (devised to load the Rails testing environment correctly)
      Cursor::Hooks.before_init

      config.after_initialize do
        Cursor::Hooks.init
      end
    end
  end
end
