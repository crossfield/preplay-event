require 'shellwords'

module PrePlay

  def self.Event(event_type, data = {}, context = {}, opts = nil)
    e = Event.new(
      {
        'type' => event_type
      }.merge(filter(data, event_type)),
      context,
      {
        'dyno'=> $dyno_name,
        'created_at'=> Time.now.to_s
      }
    )
    e.to_scrolls(opts)
  end

  #will filter the hash that was given to keep only the data that we want to display on the logs depending on the data type
  def self.filter(data, event_type)
    return {} unless PrePlay::Event.configuration.field_whitelist.has_key?(event_type)
    data.select {|k| PrePlay::Event.configuration.field_whitelist[event_type].include?(k)}
  end


  class Event < Struct.new :data, :context, :metadata

    class Configuration
      attr_accessor :field_whitelist
      def initialize
        yield self if block_given?

        @field_whitelist ||= {}
      end
    end

    def self.configure(&block)
      configuration(&block)
    end

    def self.configuration(&block)
      @@configuration ||= Configuration.new(&block)
    end



    def to_scrolls(opts = nil)
      event = {
        'd' => data,
        'c' => context,
        'm' => metadata
      }
      flatten_keys(event).merge!(preplay_event: true)
    end

    private

    #this "flatten" a hash in order to use it on a Scrolls.log line
    # {
    #   data: {
    #     foo: 'bar',
    #     baz: 42
    #   }
    # }
    # become :
    # {
    #   :'data.foo' => 'bar',
    #   :'data.baz' => 42
    # }
    def flatten_keys(hash, namespace = nil)
      namespace = namespace.nil? ? '' : "#{namespace}."
      hash.inject(Hash.new) do |result, key, value|

        hash.each do |k, v|
          if v.is_a? Hash
            # recursive call with the new namespace
            result.merge! flatten_keys(v, namespace + k.to_s)
          else
            # direct set in the hash of the v
            result["#{namespace}#{k}".to_sym] = v
          end
        end
        result
      end
    end

    def self.parse(log_line)
      data = ::Shellwords.shellsplit(log_line)
      from_hash Hash[data.map{|el| el.split('=')}]
    end

    def self.from_hash(hash)
      @data = {
        'data' => {},
        'context' => {},
        'metadata' => {}
      }

      hash.each do |k, v|
        prefix, key = k.to_s.split('.', 2)
        next unless %w(d c m).include? prefix

        event_part = case prefix
                     when 'd' then @data['data']
                     when 'c' then @data['context']
                     when 'm' then @data['metadata']
                     end

        event_part[key] = v
      end

      Event.new(@data['data'], @data['context'], @data['metadata'])
    end

  end

end
