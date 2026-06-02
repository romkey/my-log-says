# frozen_string_literal: true

module DockerLogs
  # Parses Docker multiplexed log streams into timestamped lines.
  class StreamDemuxer
    STREAM_STDOUT = 1
    STREAM_STDERR = 2

    Entry = Data.define(:stream, :timestamp, :message, :observed_at)

    def self.call(data)
      new(data).call
    end

    def initialize(data)
      @data = data.to_s
    end

    def call
      return [] if data.empty?
      return parse_raw_lines(data, 'stdout') unless multiplexed_stream?

      demux_multiplexed
    end

    private

    attr_reader :data

    def multiplexed_stream?
      [STREAM_STDOUT, STREAM_STDERR].include?(data.bytes.first)
    end

    def demux_multiplexed
      entries = []
      offset = 0
      offset, entries = read_frame(offset, entries) while offset + 8 <= data.bytesize

      entries
    end

    def read_frame(offset, entries)
      header = data.byteslice(offset, 8)
      stream_type, = header.unpack('C')
      size = header.byteslice(4, 4).unpack1('N')
      payload = data.byteslice(offset + 8, size)
      stream = stream_type == STREAM_STDERR ? 'stderr' : 'stdout'
      [offset + 8 + size, entries + parse_raw_lines(payload, stream)]
    end

    def parse_raw_lines(payload, stream)
      payload.each_line.filter_map do |line|
        parsed = parse_line(line, stream)
        next if parsed.message.blank?

        parsed
      end
    end

    def parse_line(line, stream)
      timestamp, message = line.strip.split(/\s+/, 2)
      Entry.new(
        stream: stream,
        timestamp: timestamp,
        message: message.to_s,
        observed_at: parse_timestamp(timestamp)
      )
    end

    def parse_timestamp(timestamp)
      Time.zone.parse(timestamp)
    rescue ArgumentError, TypeError
      Time.current
    end
  end
end
