module ServiceSupport
  extend ActiveSupport::Concern

  included do
    class << self
      def execute *args
        new(*args).execute
      end
    end
  end
end
