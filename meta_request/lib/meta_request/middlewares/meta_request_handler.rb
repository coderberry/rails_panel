# frozen_string_literal: true

module MetaRequest
  module Middlewares
    class MetaRequestHandler
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
          request_id = env['PATH_INFO'][%r{/__meta_request/(.+)\.json$}, 1]
          if request_id
            events_json(request_id)
          else
            @app.call(env)
          end
        end
      end

      private

      def events_json(request_id)
        events_json = Storage.new(request_id).read
        [200, { 'Content-Type' => 'text/plain; charset=utf-8' }, [events_json]]
      end
    end
  end
end
