# frozen_string_literal: true

require 'test_helper'

module Docker
  class ClientTest < ActiveSupport::TestCase
    test 'connects over a unix socket rather than resolving a hostname' do
      socket_path = '/var/run/docker.sock'
      captured = {}
      original_new = Excon.method(:new)
      Excon.define_singleton_method(:new) do |url, **options|
        captured[:url] = url
        captured[:options] = options
        original_new.call(url, **options)
      end

      Client.new(socket_path: socket_path)

      assert_equal "unix://#{socket_path}", captured[:url]
      assert_equal socket_path, captured[:options][:socket]
    ensure
      Excon.define_singleton_method(:new, original_new)
    end

    test 'wraps excon errors' do
      client = Client.new(socket_path: '/var/run/docker.sock')
      client.define_singleton_method(:connection) do
        Object.new.tap do |connection|
          connection.define_singleton_method(:request) do |**|
            raise Excon::Error, 'connection failed'
          end
        end
      end

      error = assert_raises Client::Error do
        client.send(:get_json, '/containers/json')
      end

      assert_includes error.message, 'connection failed'
    end
  end
end
