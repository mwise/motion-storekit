#class Transaction
  #def payment
    #self
  #end

  #def productIdentifier
  #end
#end

class FakeQueue

  attr_accessor :added_observer, :payment_sent, :restoring

  def self.instance
    Dispatch.once{ @instance ||= new }
    @instance
  end

  def addTransactionObserver(object)
  end

  def addPayment(product)
  end

  def finishTransaction(transaction)
  end

  def restoreCompletedTransactions
  end

  def removeTransactionObserver(object)
  end

end

class SKPaymentQueue

  def self.canMakePayments
    true
  end

  def self.defaultQueue
    FakeQueue.instance
  end

end

class SKPayment

  def self.paymentWithProductIdentifier(id)
  end

end
