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

    context "when a manifest a purchases directory is provided" do
      before do
        @directory = "/foo/bar"
        @subject = MotionStoreKit::StoreController.new([],
                                                       purchases_directory: @directory)
      end


      it "sets the purchases directory" do
        expect(@subject.purchases_directory).to be(@directory)
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

end
