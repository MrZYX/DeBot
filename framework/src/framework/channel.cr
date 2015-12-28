require "thread/repository"
require "irc/message"

require "./message"
require "./bot"

module Framework
  class Channel
    getter name
    getter context

    @@channels = Repository(String, Channel).new

    def self.from_name(name : String, context)
      @@channels.fetch(name) { new(name, context) }
    end

    private def initialize(@name : String, @context : Bot)
    end

    def membership(user : User)
      membership user.nick
    end

    def membership(nick : String)
      channel = @context.connection.channels[@name]
      @context.connection.users.find_membership(IRC::Mask.parse(nick), channel)
    end

    def send(text : String)
      Message.new(@context, @name, text).send
    end

    def action(text : String)
      Message.new(@context, @name, text).as_action.send
    end

    def has?(user : User)
      has? user.nick
    end

    def has?(nick : String)
      !membership(nick).nil?
    end

    def opped?(user : User)
      opped? user.nick
    end

    def opped?(nick : String)
      membership(nick).try(&.op?) || false
    end

    def voiced?(user : User)
      voiced? user.nick
    end

    def voiced?(nick : String)
      membership(nick).try(&.voiced?) || false
    end

    def ban(user : User)
      ban user.mask
    end

    def ban(mask : IRC::Mask)
      ban mask.to_s
    end

    def ban(mask : String)
      mode mask, "+b"
    end

    def unban(user : User)
      unban user.mask
    end

    def unban(mask : IRC::Mask)
      unban mask.to_s
    end

    def unban(mask : String)
      mode mask, "-b"
    end

    def kick(user : User, reason=nil)
      kick user.nick, reason
    end

    def kick(nick : String, reason=nil)
      params = [@name, nick]
      params << reason if reason
      @context.connection.send IRC::Message::KICK, params
    end

    def op(user : User)
      op user.nick
    end

    def op(nick : String)
      mode nick, "+o"
    end

    def deop(user : User)
      deop user.nick
    end

    def deop(nick : String)
      mode nick, "-o"
    end

    def mode(param : String, mode : String)
      @context.connection.send IRC::Message::MODE, @name, mode, param
    end
  end
end
