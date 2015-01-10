module MotionStoreKit

  class Product

    attr_reader :currency,
                :description,
                :formatted_price,
                :id,
                :price,
                :store_controller,
                :title

    def initialize(args = {}, store_controller)
      unless args[:id]
        raise ArgumentError, "MotionStorekit Warning: You must pass an id for each product. You cannot sell a product without passing it an id."
      end

      @id = args[:id]

      @store_controller = WeakRef.new(store_controller)

      @event_handlers = {}
    end

    def update_attributes(attributes)
      attributes.each_pair do |key, value|
        self.send(:instance_variable_set, "@#{key}", value)
      end
    end

    def purchase
      @store_controller.purchase(@id)
    end

    def purchased?
      @store_controller.purchased?(@id)
    end

    def on(event_name, handler_proc = nil, &block)
      raise ArgumentError unless handler_proc || block

      @event_handlers[event_name] ||= []
      @event_handlers[event_name] << handler_proc if handler_proc
      @event_handlers[event_name] << block if block
    end

    def off(event_name, &block)
      @event_handlers[event_name] = []
    end

    def trigger(event_name, *args)
      if handlers = @event_handlers[event_name]
        handlers.each do |handler|
          handler.call(*args)
        end
      end
    end

  end

end
