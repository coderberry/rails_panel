# frozen_string_literal: true

require 'json'

module MetaRequest
  module Middlewares
    class AppRequestHandler
      def initialize(app)
        @app = app
      end

      def call(env)
        req = Rack::Request.new(env)

        # Only handle requests if the query param is set
        if req.params["rails_panel"] != "true" || env["ENABLE_RAILS_PANEL"].to_s == "true"
          @app.call(env)
        else
          # original code below
          begin
            app_request = AppRequest.new env['action_dispatch.request_id']
            app_request.current!
            @app.call(env)
          rescue StandardError => e
            if defined?(ActionDispatch::ExceptionWrapper)
              wrapper = if ActionDispatch::ExceptionWrapper.method_defined? :env
                          ActionDispatch::ExceptionWrapper.new(env, e)
                        else
                          ActionDispatch::ExceptionWrapper.new(env['action_dispatch.backtrace_cleaner'],
                                                               e)
                        end
              app_request.events.push(*Event.events_for_exception(wrapper))
            else
              app_request.events.push(*Event.events_for_exception(e))
            end
            raise
          ensure
            Storage.new(app_request.id).write(app_request.events.to_json) unless app_request.events.empty?
          end
        end
      end
    end
  end
end
