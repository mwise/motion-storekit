# motion-storekit

Manage your In-App Purchases in RubyMotion

## Installation

From the command line:
```
$ gem install motion-storekit
```

In your Gemfile:
```
gem 'motion-storekit'
```

## Usage

### MotionStoreKit::StoreController
```ruby
# Create an instance of MotionStoreKit::StoreController
# Pass In-App Purchase product IDs
product_ids ["com.example.MyProduct1", "com.example.MyProduct2"]
@store_controller = MotionStoreKit::StoreController.new(product_ids)

# Optionally set a manifest for your store
# The manifest should be an array of Hashes
# Each element should have at least a product_id
# The manifest determines the order in which your returns products
@store_controller.manifest = [
  { product_id: "com.example.MyProduct1", name: "My Product 1" },
  { product_id: "com.example.MyProduct2", name: "My Product 2" }
]

@store_controller.fetch_product_info do
  # do something with @store_controller.products here
  # @store_controller.products will be an array of MotionStoreKit::Product instances
end
```

### MotionStoreKit::Product

```ruby
@store_controller = MotionStoreKit::StoreController.new

product_id = "com.example.MyProduct3"
@product = @store_controller.add_product(product_id)

# ask the App Store for product information
@store_controller.fetch_product_info do

  # retrieve product information
  @product.title            # String (e.g. "My Product 3")
  @product.description      # String (e.g. "This is my third product!")
  @product.price            # Float (e.g. 1.99)
  @product.product_id       # In-App Purchase Product ID (e.g. "com.example.MyProduct3"
  @product.currency         # String (e.g. "USD")
  @product.formatted_price  # String (e.g. "$1.99")

  # attach a listener for a product lifecycle event
  # see 'Events' below for the complete list of events and their handler arguments
  @product.on(:purchase_finished) do |transaction|
    # update your UI, unlock a feature, etc.
  end

  # initiate a purchase
  @product.purchase
end

```

### Events

#### Adding event listeners
```ruby
# using a block
@product.on(:purchase_succeeded) do |transaction|
  # `transaction` will be an SKPaymentTransaction
end

# using a proc
def my_failure_handler
  lambda { |transaction|
    #do something here
  }
end
@product.on(:purchase_failed, my_failure_handler)

# using both proc and a block
def my_cancel_handler
  ->(transaction){
    # this will get called the purchase is cancelled
  }
end
@product.on(:purchase_cancelled, my_cancel_handler) do |transaction|
  # this will also get called when the purchase is cancelled
end
```

#### Removing event listeners

```ruby
# remove all event listeners for the given event
@product.off(:purchase_succeeded)
```

#### Catalog of Events

Here's the complete list of MotionStoreKit::Product events with the arguments to be expected

Note: you *must* use the correct arguments for your handler proc or block

* **purchase_cancelled**: `->(transaction){ }`
  * triggered when the user cancels the purchase modal
* **purchase_downloading**: `->(transaction){ }`
  * triggered when a downloadable purchase starts downloading
* **purchase_failed**: `->(transaction){ }`
  * triggered when a purchase fails for some reason other than the user canceling
* **purchase_finished**: `->(transaction){ }`
  * triggered when the purchase is fully complete, including any downloads
* **purchase_purchasing**: `->(transaction){ }`
  * triggered when the user initiates the purchase process
* **purchase_succeeded**: `->(transaction){ }`
  * triggered when the user successfully purchases a product
* **download_active**: `->(download){ }`
  * triggered during download progress
* **download_cancelled**: `->(download){ }`
  * triggered when a download is cancelled
* **download_failed**: `->(download){ }`
  * triggered when a download fails
* **download_finished**: `->(download, purchase_path){ }`
  * triggered when a download is finished
  * `purchase_path` is a string where the download contents are stored
  * see "Downloadable Purchases" below
* **download_paused**: `->(download){ }`
  * triggered when a download is paused
* download_waiting: `->(download_waiting){ }`
  * triggered when a download is waiting

### Downloadable Purchases

TODO
