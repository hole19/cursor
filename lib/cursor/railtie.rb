module Cursor
  class Railtie < ::Rails::Railtie #:nodoc:
    initializer 'cursor' do |_app|
      if Rails.env.test?
        ActiveSupport.on_load(:active_record) do
          ::ActiveRecord::Base.send :include, Cursor::ConfigurationMethods
        end
      end

      config.after_initialize do
        Cursor::Hooks.init
      end
    end
  end
end
