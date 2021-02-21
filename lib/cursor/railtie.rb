module Cursor
  class Railtie < ::Rails::Railtie #:nodoc:
    # Doesn't actually do anything. Just keeping this hook point, mainly for compatibility
    initializer 'cursor' do
    end
  end
end
