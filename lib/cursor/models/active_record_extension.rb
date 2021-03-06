require 'cursor/models/active_record_model_extension'

module Cursor
  module ActiveRecordExtension
    extend ActiveSupport::Concern

    module ClassMethods #:nodoc:
      # Future subclasses will pick up the model extension
      def inherited(kls) #:nodoc:
        super
        kls.send(:include, Cursor::ActiveRecordModelExtension) if kls.superclass == ::ActiveRecord::Base
      end
    end

    included do
      # Existing subclasses pick up the model extension as well
      descendants.each do |kls|
        kls.send(:include, Cursor::ActiveRecordModelExtension) if kls.superclass == ::ActiveRecord::Base
      end
    end
  end
end
