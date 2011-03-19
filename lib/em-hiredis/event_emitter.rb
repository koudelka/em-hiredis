module EM::Hiredis
  module EventEmitter

    def on(event, &listener)
      listeners[event] << listener
    end

    def emit(event, *args)
      listeners[event].each { |l| l.call(*args) }
    end

    def remove_listener(event, &listener)
      listeners[event].delete(listener)
    end

    def remove_all_listeners(event)
      listeners.delete(event)
    end

    def listeners(event)
      listeners[event]
    end

    def listeners
      @listeners ||= Hash.new { |h,k| h[k] = [] }
    end
    private :listeners

  end
end
