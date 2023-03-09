# frozen_string_literal: true

module Turnstile
  class Railtie < Rails::Railtie
    ActiveSupport.on_load(:action_view) do
      include Turnstile::Adapters::ViewMethods
    end

    ActiveSupport.on_load(:action_controller) do
      include Turnstile::Adapters::ControllerMethods
    end

    initializer 'turnstile' do |app|
      Turnstile::Railtie.instance_eval do
        pattern = pattern_from app.config.i18n.available_locales

        add("rails/locales/#{pattern}.yml")
      end
    end

    class << self
      protected

      def add(pattern)
        files = Dir[File.join(File.dirname(__FILE__), '../..', pattern)]
        I18n.load_path.concat(files)
      end

      def pattern_from(args)
        array = Array(args || [])
        array.blank? ? '*' : "{#{array.join ','}}"
      end
    end
  end
end
