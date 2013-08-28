# coding: utf-8

require 'faraday'
require 'faraday_middleware'

module Yandex
  module Disk
    class Client

      def initialize options={}
        @timeout = options[:timeout] || 300
        @http = Faraday.new(:url => 'https://webdav.yandex.ru') do |builder|
          builder.request :authorization, "OAuth", options[:access_token]

          builder.response :follow_redirects

          if faraday_configurator = options[:faraday_configurator]
            faraday_configurator.call(builder)
          else
            builder.adapter :excon
          end
        end
      end

      def put src, dest
        put_response(src, dest).success?
      end

      def put! src, dest
        res = put_response(src, dest)
        raise res.body unless res.success?
      end

      def mkcol path
        mkcol_response(path).success?
      end

      def mkcol!
        res = mkcol_response(path)
        raise res.body unless res.success?
      end

      def get path
        @http.get(path)
      end

      alias_method :mkdir, :mkcol

      def mkdir_p path
        path_parts = []
        path.split('/').each do |part|
          path_parts << part
          mkdir(path_parts.join('/'))
        end
      end

      def copy src, dest
        file_operation_response('COPY', src, dest).success?
      end

      def copy! src, dest
        res = file_operation_response('COPY', src, dest)
        raise res.body unless res.success?
      end

      def move src, dest
        file_operation_response('MOVE', src, dest).success?
      end

      def move! src, dest
        res = file_operation_response('MOVE', src, dest)
        raise res.body unless res.success?
      end

      def delete path
        delete_response(path).success?
      end

      def delete! path
        res = delete_response(path)
        raise res.body unless res.success?
      end

      private

      def put_response src, dest
        @http.put do |req|
          req.url dest
          req.headers['Content-Type'] = 'application/binary'
          req.options[:timeout] = @timeout
          req.body = Faraday::UploadIO.new(src, '')
        end
      end

      def mkcol_response path
        request = @http.build_request('MKCOL') do |req|
          req.url(path)
        end

        env = request.to_env(@http)
        @http.app.call(env)
      end

      def file_operation_response op, src, dest
        request = @http.build_request(op) do |req|
          req.url(path)
          req.headers['Destination'] = dest
        end

        env = request.to_env(@http)
        res = @http.app.call(env)
        res.success?
      end

      def delete_response path
        @http.delete(path)
      end
    end
  end
end