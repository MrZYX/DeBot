module Framework
  class Limiter
    @time_span : Time::Span

    def initialize(@limit = 5, time_span = 60)
      @time_span = time_span.is_a?(Time::Span) ? time_span : Time::Span.new(seconds: time_span)
      @hits = [] of Time
    end

    # Returns true if the next hit would be allowed
    def pass?
      cleanup_hits

      @hits.size < @limit
    end

    # Returns true if the limit is exceeded
    #
    # This returns false in the border case, meaning the next hit could
    # exceed the limit
    def exceeded?
      cleanup_hits

      @hits.size > @limit
    end

    # Tracks a hit and returns true if that hit exceeded the limit
    def hit
      @hits << Time.local

      exceeded?
    end

    private def cleanup_hits
      now = Time.local
      @hits.reject! { |hit| now - hit > @time_span }
    end
  end

  struct LimiterCollection(T)
    def initialize(@limit = 5, @time_span = 60)
      @limiters = {} of T => Limiter
    end

    def pass?(key : T)
      fetch(key).pass?
    end

    def exceeded?(key : T)
      fetch(key).exceeded?
    end

    def hit(key : T)
      fetch(key).hit
    end

    private def fetch(key)
      @limiters.rehash
      @limiters.fetch(key) { @limiters[key] = Limiter.new(@limit, @time_span) }
    end
  end
end
