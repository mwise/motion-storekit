module MotionStoreKit

  class ProductInfoFetcher

    class <<self

      def fetch(*products, &block)
        new(*products, &block)
      end

      def cache
        Dispatch.once { @cache ||= {} }
        @cache
      end

      def clear_cache
        queue.async { @cache = {} }
      end

      def queue
        Dispatch::Queue.new("motion-storekit")
      end

    end

    def initialize(*product_ids, &block)
      raise LocalJumpError, "block expected" if block.nil?
      @callback = block
      @product_ids = product_ids.flatten

      if all_product_ids_cached?
        @callback.call(cached_info_for_product_ids)
      else
        create_products_request
      end

      self
    end

    def productsRequest(req, didReceiveResponse: response)
      if response.nil?
        @callback.call(nil)
      else
        products_hash = response.products.inject({}) { |memo, sk_product|
          memo.merge(sk_product_to_hash(sk_product))
        }
        self.class.queue.async { cache.merge!(products_hash) }
        @callback.call(products_hash)
      end
    end

    private

    def all_product_ids_cached?
      (cache.keys & @product_ids).sort == @product_ids.sort
    end

    def cache
      self.class.cache
    end

    def cached_info_for_product_ids
      @product_ids.inject({}) { |memo, id| memo[id] = cache[id]; memo }
    end

    def create_products_request
      @products_request = SKProductsRequest.alloc
        .initWithProductIdentifiers(@product_ids)
      @products_request.delegate = self
      @products_request.start
    end

    def formatted_price(sk_product)
      formatter = NSNumberFormatter.alloc.init
      formatter.setFormatterBehavior(NSNumberFormatterBehavior10_4)
      formatter.setNumberStyle(NSNumberFormatterCurrencyStyle)
      formatter.setLocale(sk_product.priceLocale)

      formatter.stringFromNumber(sk_product.price)
    end

    def sk_product_to_hash(sk_product)
      {
        sk_product.productIdentifier => {
          title: sk_product.localizedTitle,
          description: sk_product.localizedDescription,
          price: sk_product.price,
          currency: sk_product.priceLocale.objectForKey(NSLocaleCurrencyCode),
          formatted_price: formatted_price(sk_product)
        }
      }
    end

  end

end
