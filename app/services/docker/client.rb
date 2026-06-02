# frozen_string_literal: true

require 'excon'
require 'json'

module Docker
  # HTTP client for the Docker Engine API over a Unix socket.
  class Client
    class Error < StandardError
    end

    DEFAULT_SOCKET = '/var/run/docker.sock'

    def initialize(socket_path: ENV.fetch('DOCKER_SOCKET', DEFAULT_SOCKET))
      @connection = Excon.new(
        'http://docker',
        socket: socket_path,
        middlewares: Excon.defaults[:middlewares] - [Excon::Middleware::RedirectFollower]
      )
    end

    def list_containers(all: true)
      get_json('/containers/json', query: { all: all })
    end

    def container_logs(id, **options)
      response = connection.get(path: "/containers/#{id}/logs", query: log_query(options))
      raise Error, error_message(response) unless response.status == 200

      response.body
    end

    private

    attr_reader :connection

    def log_query(options)
      query = {
        stdout: options.fetch(:stdout, true),
        stderr: options.fetch(:stderr, true),
        timestamps: options.fetch(:timestamps, true),
        tail: options.fetch(:tail, 'all')
      }
      since = options[:since]
      query[:since] = since.to_i if since
      query
    end

    def get_json(path, query: {})
      response = connection.get(path: path, query: query)
      raise Error, error_message(response) unless response.status == 200

      JSON.parse(response.body)
    end

    def error_message(response)
      body = response.body.to_s.strip
      body.presence || "Docker API request failed with status #{response.status}"
    end
  end
end
