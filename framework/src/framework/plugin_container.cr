require "json"

require "./plugin"

module Framework
  class PluginContainer(T, C)
    module Workaround; end
    include Workaround

    getter config : C?
    delegate channels, wants?, to: config

    def config
      (@config ||= T.config_class.empty).tap do |config|
        config.name = name
      end
    end

    def name
      T.to_s
    end

    def read_config(pull : JSON::PullParser)
      (@config = T.config_class.new pull).tap do |config|
        config.name = name
        T.config_loaded(config)
      end
    end

    def instance(context)
      T.new(context, config)
    end

    def handle(event)
      return unless wants? event
      return if filter? event

      if event.type == :message
        plugin = instance event.context
        handle_message event.message, plugin
      else
        return unless T.events.includes? event.type
      end

      plugin ||= instance event.context

      handle_event event, plugin
    end

    def filter?(event)
      event.context.filter? event
    end

    private def handle_event(event, plugin)
      plugin.react_to(event) if plugin.responds_to?(:react_to)
    rescue e
      puts "Couldn't run plugin #{self} for #{event}:"
      puts e
      puts e.backtrace.join("\n")
    end

    private def handle_message(message, plugin)
      T.matchers.each do |regex|
        match = message.message.match regex
        if match
          begin
            plugin.execute(message, match) if plugin.responds_to?(:execute)
          rescue e
            puts "Couldn't run plugin #{self} for #{message} matched by #{regex}:"
            puts e
            puts e.backtrace.join("\n")
          end
          break
        end
      end
    end
  end

  class PluginError < Exception
  end
end
