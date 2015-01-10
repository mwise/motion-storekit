describe MotionStoreKit::StoreController do

  describe "initialization" do
    before do
      @manifest = [{ id: "foo", name: "bar" }]
    end

    context "when a manifest is provided" do
      before do
        @subject = MotionStoreKit::StoreController.new(@manifest)
      end

      it "assigns the manifest" do
        expect(@subject.manifest).to be(@manifest)
      end

      it "adds a product for each entry in the manifest" do
        @products = @subject.instance_variable_get(:@products)
        expect(@subject.products.size).to be(1)
      end
    end

    context "when options are provided" do
      before do
        @options = { foo: "bar" }
        @subject = MotionStoreKit::StoreController.new([], @options)
      end

      it "saves the options" do
        options = @subject.instance_variable_get(:@options)
        expect(options[:foo]).to eq(@options[:foo])
      end
    end

    context "when a block is provided" do
      before do
        @product_info = {
          "foo" => {
            id: "foo",
            title: "inapp_localized_title",
            description: "inapp_localized_description",
            price: "0.99",
            currency: "USD",
            price_str: "$0.89"
          }
        }
        MotionStoreKit::StoreController.stub!(:fetch_product_info) do |ids, &block|
          block.call(@product_info) if block
        end
        @subject = MotionStoreKit::StoreController.new(@manifest) do |products|
          @products = products
        end
      end

      it "calls the block once products have been fetched" do
        expect(@products.first.class).to be(MotionStoreKit::Product)
      end
    end
  end

  describe "instance methods" do
    before do
      @subject = MotionStoreKit::StoreController.new([])
    end

    describe "#add_product" do
      before do
        @manifest_entry = { id: "foo", name: "bar" }
      end

      context "when the manifest is empty" do
        before do
          @subject.add_product(@manifest_entry)
        end

        it "adds an entry to the manifest" do
          expect(@subject.manifest).to include(@manifest_entry)
        end

        it "adds a product" do
          expect(@subject.products.size).to eq(1)
        end
      end

      context "when the manifest contains the entry already" do
        before do
          @subject.add_product(@manifest_entry)
          @subject.add_product(@manifest_entry)
        end

        it "doesn't re-add the entry to the manifest" do
          expect(@subject.manifest).to eq([@manifest_entry])
        end

        it "doesn't add an additional product" do
          expect(@subject.products.size).to eq(1)
        end
      end

      context "when the manifest contains a different entry" do
        before do
          @other_manifest_entry = { id: "baz", name: "bat" }
          @subject.add_product(@other_manifest_entry)
          @subject.add_product(@manifest_entry)
        end

        it "adds an entry to the manifest" do
          expect(@subject.manifest).to eq([
            @other_manifest_entry,
            @manifest_entry
          ])
        end

        it "adds a product" do
          expect(@subject.products.size).to eq(2)
        end
      end

      context "when a block is provided" do
        before do
          @fake_products = ["1", "2"]
          @subject.stub!(:fetch, yield: ["blah"]) do |&block|
            block.call(@fake_products) if block
          end

          @subject.add_product(@manifest_entry) do |products|
            @block_called = products
          end
        end

        it "fetches the product info and yields the products to the block" do
          expect(@block_called).to eq(@fake_products)
        end
      end
    end

    describe "#add_products" do
      before do
        @manifest_entries = [{ id: "foo" }, { id: "bar" }]
        @subject = MotionStoreKit::StoreController.new([])
      end

      context "when the manifest is empty" do
        before do
          @subject.add_products(@manifest_entries)
        end

        it "adds entries to the manifest" do
          expect(@subject.manifest).to eq(@manifest_entries)
        end

        it "creates products for each entry" do
          expect(@subject.products.size).to eq(2)
        end
      end

      context "when the manifest is not empty" do
        before do
          @other_manifest_entries = [{ id: "foo" }, { id: "bat" }]
          @subject.add_products(@other_manifest_entries)
          @subject.add_products(@manifest_entries)
        end

        it "adds only new entries to the manifest" do
          expect(@subject.manifest).to eq([
            { id: "foo" },
            { id: "bat" },
            { id: "bar" }
          ])
        end

        it "creates products for each new entry" do
          expect(@subject.products.size).to eq(3)
        end
      end

      context "when a block is provided" do
        before do
          @fake_products = ["1", "2"]
          @subject.stub!(:fetch) do |&block|
            block.call(@fake_products) if block
          end

          @subject.add_products(@manifest_entries) do |products|
            @products = products
          end
        end

        it "fetches the product info and yields the products to the block" do
          expect(@products).to eq(@fake_products)
        end
      end
    end

    describe "#reset_products=" do
      before do
        @manifest_entries = [{ id: "foo" }, { id: "bar" }]
        @subject = MotionStoreKit::StoreController.new([])
      end

      context "when the manifest is empty" do
        before do
          @subject.reset_products(@manifest_entries)
        end

        it "adds entries to the manifest" do
          expect(@subject.manifest).to eq(@manifest_entries)
        end

        it "creates products for each entry" do
          expect(@subject.products.size).to eq(2)
        end
      end

      context "when the manifest is not empty" do
        before do
          @other_manifest_entries = [{ id: "foo" }, { id: "bat" }]
          @subject.reset_products(@other_manifest_entries)
          @subject.reset_products(@manifest_entries)
        end

        it "replaces the manifest" do
          expect(@subject.manifest).to eq(@manifest_entries)
        end

        it "creates products for each entry" do
          expect(@subject.products.size).to eq(@manifest_entries.size)
        end
      end

      context "when a block is provided" do
        before do
          @fake_products = ["1", "2"]
          @subject.stub!(:fetch) do |&block|
            block.call(@fake_products) if block
          end

          @subject.reset_products(@manifest_entries) do |products|
            @products = products
          end
        end

        it "fetches the product info and yields the products to the block" do
          expect(@products).to eq(@fake_products)
        end
      end
    end

    describe "#can_make_payments?" do
      context "when the user can make payments" do
        before { SKPaymentQueue.stub!(:canMakePayments, return: true) }

        it "is true" do
          expect(@subject.can_make_payments?).to be_true
        end
      end

      context "when the user can't make payments" do
        before { SKPaymentQueue.stub!(:canMakePayments, return: false) }

        it "is false" do
          expect(@subject.can_make_payments?).to be_false
        end
      end
    end

    # TODO: figure out how to test this
    #describe "#close" do
      #after do
        #SKPaymentQueue.defaultQueue.reset(:removeTransactionObserver)
      #end

      #it "removes the controller as a transaction observer from the payment queue" do
        #SKPaymentQueue.defaultQueue.stub!(:removeTransactionObserver) do |thing|
          #expect(thing).to be(@subject)
        #end

        #@subject.close
      #end
    #end

    # TODO: figure out how to test this
    #describe "#open" do
      #after do
        #SKPaymentQueue.defaultQueue.reset(:removeTransactionObserver)
        #SKPaymentQueue.defaultQueue.reset(:addTransactionObserver)
      #end

      #it "removes, then adds the controller as a transaction observer from the payment queue" do
        #SKPaymentQueue.defaultQueue.stub!(:removeTransactionObserver) do |thing|
          #expect(thing).to be(@subject)
        #end
        #SKPaymentQueue.defaultQueue.stub!(:addTransactionObserver) do |thing|
          #expect(thing).to be(@subject)
        #end

        #@subject.open
      #end
    #end

  end # end instance methods

end
