module MotionStoreKit

  class StoreController

    attr_reader :manifest
    attr_reader :purchases_directory

    def self.fetch_product_info(product_ids, &block)
      @fetcher = ProductInfoFetcher.fetch(product_ids, &block)
    end

    def initialize(manifest = [], args = {}, &block)
      @manifest = manifest

      open
      @storage = LocalStorage.new
      @products = {}
      @purchases_directory = args[:purchases_directory]

      add_products_from_manifest

      @verbose = false

      fetch(&block) if block
    end

    def add_product(manifest_entry, &block)
      return @products[manifest_entry[:id]] if @products[manifest_entry[:id]]

      @products[manifest_entry[:id]] = Product.new(manifest_entry, self)

      fetch(&block) if block
    end

    def add_products(manifest, &block)
      @manifest += manifest
      add_products_from_manifest

      fetch(&block) if block
    end

    def can_make_payments?
      SKPaymentQueue.canMakePayments
    end

    def close
      payment_queue.removeTransactionObserver(self)
    end

    def fetch(&block)
      self.class.fetch_product_info(@products.keys) do |product_info|
        update_product_attributes(product_info)

        block.call(products) if block
      end
    end

    def manifest=(manifest)
      @manifest = manifest
      add_products_from_manifest
    end

    def products
      ordered = []

      product_ids_from_manifest.map do |product_id|
        if product = @products[product_id]
          ordered << product
        end
      end

      ordered
    end

    def open
      payment_queue.removeTransactionObserver(self)
      payment_queue.addTransactionObserver(self)
    end

    def paymentQueue(queue, updatedTransactions:transactions)
      transactions.each do |transaction|
        process_transaction(transaction)
      end
    end

    def paymentQueue(queue, updatedDownloads:downloads)
      downloads.each do |download|
        process_download(download)
      end
    end

    def paymentQueueRestoreCompletedTransactionsFinished(queue)
      ids = []
      queue.transactions.each do |transaction|
        product_id = transaction.payment.productIdentifier
        ids << product_id
        log_message("restored #{product_id}")
      end
    end

    def purchase(product_id)
      payment = SKPayment.paymentWithProductIdentifier(product_id)
      payment_queue.addPayment(payment)
    end

    def purchased?(product_id)
      @storage.all.include?(product_id)
    end

    def restore_purchases
      payment_queue.restoreCompletedTransactions
    end

    private

    def add_products_from_manifest
      @manifest.each { |entry| add_product(entry) } if @manifest
    end

    def complete_transaction(transaction)
      product_id = transaction.payment.productIdentifier
      finish_transaction(transaction, wasSuccessful:true)
      trigger_event(product_id, :purchase_finished, transaction)
    end

    def manifest_from_product_ids(product_ids)
      product_ids.map do |product_id|
        { product_id: product_id }
      end
    end

    def payment_queue
      SKPaymentQueue.defaultQueue
    end

    def process_download(download)
      product_id = download.contentIdentifier

      case download.downloadState
      when SKDownloadStateActive
        trigger_event(product_id, :download_active, download)
      when SKDownloadStateCancelled
        trigger_event(product_id, :download_cancelled, download)
      when SKDownloadStateFailed
        trigger_event(product_id, :download_failed, download)
      when SKDownloadStateFinished
        purchase_path = DownloadProcessor.process(download,
                                                  verbose: @verbose,
                                                  purchases_directory: @purchases_directory)
        trigger_event(product_id, :download_finished, download, purchase_path)

        complete_transaction(download.transaction)
      when SKDownloadStatePaused
        trigger_event(product_id, :download_paused, download)
      when SKDownloadStateWaiting
        trigger_event(product_id, :download_waiting, download)
      end
    end

    def process_transaction(transaction)
      case transaction.transactionState
        when SKPaymentTransactionStateFailed
          process_transaction_failed(transaction)
        when SKPaymentTransactionStatePurchased
          process_transaction_purchased(transaction)
        when SKPaymentTransactionStatePurchasing
          process_transaction_purchasing(transaction)
        when SKPaymentTransactionStateRestored
          process_transaction_restored(transaction)
        else
      end
    end

    def process_transaction_purchased(transaction)
      product_id = transaction.payment.productIdentifier

      trigger_event(product_id, :purchase_succeeded, transaction)

      log_message("purchased: #{product_id}")
      if transaction.downloads
        log_message("downloads starting for #{product_id}")
        payment_queue.startDownloads(transaction.downloads)
        trigger_event(product_id, :purchase_downloading, transaction)
      else
        complete_transaction(transaction)
      end
    end

    def process_transaction_purchasing(transaction)
      product_id = transaction.payment.productIdentifier

      trigger_event(product_id, :purchase_purchasing, transaction)
    end

    def process_transaction_failed(transaction)
      product_id = transaction.payment.productIdentifier

      if transaction.error && (transaction.error.code != SKErrorPaymentCancelled)
        finish_transaction(transaction, wasSuccessful:false)
        trigger_event(product_id, :purchase_failed, transaction)
      elsif transaction.error && (transaction.error.code == SKErrorPaymentCancelled)
        trigger_event(product_id, :purchase_cancelled, transaction)
        finish_transaction(transaction, wasSuccessful:false)
      else
        trigger_event(product_id, :purchase_failed, transaction)
        payment_queue.finishTransaction(transaction)
      end
    end

    def process_transaction_restored(transaction)
      product_id = transaction.payment.productIdentifier

      if transaction.downloads
        payment_queue.startDownloads(transaction.downloads)
        trigger_event(product_id, :purchase_downloading, transaction)
      end

      finish_transaction(transaction, wasSuccessful:true)
      trigger_event(product_id, :purchase_restored, transaction.originalTransaction)
    end

    def product_ids_from_manifest
      @manifest.map { |entry| entry[:id] }
    end

    def finish_transaction(transaction, wasSuccessful:wasSuccessful)
      product_id = transaction.payment.productIdentifier
      payment_queue.finishTransaction(transaction)
      @storage.add(product_id) if wasSuccessful
    end

    def trigger_event(product_id, event_name, *args)
      if product = @products[product_id]
        product.trigger(event_name, *args)
      end
    end

    def update_product_attributes(product_info)
      product_info.each_pair do |id, attributes|
        if product = @products[id]
          product.update_attributes(attributes)
        end
      end
    end

    #def receipt_data
      #receipt_url = NSBundle.mainBundle.appStoreReceiptURL

      #NSData.dataWithContentsOfURL(receipt_url)
    #end

    def log_message(message)
      NSLog(message) if @verbose
    end

    class LocalStorage

      def clean
        defaults.setObject(nil, forKey: key_for_defaults)
        defaults.synchronize
      end

      def add(product_id)
        if all
          defaults.setObject([all, product_id].flatten, forKey: key_for_defaults)
        else
          defaults.setObject([product_id], forKey: key_for_defaults)
        end

        defaults.synchronize
      end

      def all
        return [] if defaults.valueForKey(key_for_defaults) == nil
        defaults.valueForKey(key_for_defaults)
      end

      private

      def key_for_defaults
        "motion_storekit_products"
      end

      def defaults
        NSUserDefaults.standardUserDefaults
      end

    end

  end

end
