# frozen_string_literal: true

module ViewComponent
  module TestHelpers
    begin
      require "capybara/minitest"
      include Capybara::Minitest::Assertions

      def page
        Capybara::Node::Simple.new(@rendered_component)
      end

      def refute_component_rendered
        assert_no_selector("body")
      end
    rescue LoadError
      # We don't have a test case for running an application without capybara installed.
      # It's probably fine to leave this without coverage.
      # :nocov:
      warn "WARNING in `ViewComponent::TestHelpers`: You must add `capybara` to your Gemfile to use Capybara assertions." if ENV["DEBUG"]
      # :nocov:
    end

    attr_reader :rendered_component

    def render_inline(component, **args, &block)
      @rendered_component =
        if Rails.version.to_f >= 6.1
          controller.view_context.render(component, args, &block)
        else
          controller.view_context.render_component(component, &block)
        end

      Nokogiri::HTML.fragment(@rendered_component)
    end

    def controller
      @controller ||= build_controller(Base.test_controller.constantize)
    end

    def request
      @request ||= ActionDispatch::TestRequest.create
    end

    def with_variant(variant)
      old_variants = controller.view_context.lookup_context.variants

      controller.view_context.lookup_context.variants = variant
      yield
    ensure
      controller.view_context.lookup_context.variants = old_variants
    end

    def with_controller_class(klass)
      old_controller = defined?(@controller) && @controller

      @controller = build_controller(klass)
      yield
    ensure
      @controller = old_controller
    end

    def with_request_url(path)
      old_request_path_parameters = request.path_parameters
      old_controller = defined?(@controller) && @controller

      request.path_parameters = Rails.application.routes.recognize_path(path)
      yield
    ensure
      request.path_parameters = old_request_path_parameters
      @controller = old_controller
    end

    def build_controller(klass)
      klass.new.tap { |c| c.request = request }.extend(Rails.application.routes.url_helpers)
    end
  end
end
