describe MotionStoreKit::Product do

  before do
    @controller = MotionStoreKit::StoreController.new
  end

  describe "initialization" do

    it "should raise an error when not provided an id argument" do
      lambda {
        MotionStoreKit::Product.new({}, @controller)
      }.should.raise(ArgumentError)
    end

    it "should raise an error when not provided a StoreController argument" do
      lambda {
        MotionStoreKit::Product.new({ id: "foo" }, nil)
      }.should.raise(ArgumentError)
    end

  end

  describe "instance methods" do
    before do
      @subject = MotionStoreKit::Product.new({ id: "foo" }, @controller)
    end

    describe "#update_attributes" do
      before do
        @attrs = {
          currency: "USD",
          description: "some description",
          formatted_price: "$1.99",
          id: "some.product.ID",
          price: 0.99,
          title: "some title"
        }

        @subject.update_attributes(@attrs)
      end

      it "sets an ivar for each given attribute" do
        @attrs.each do |key, value|
          expect(@subject.instance_variable_get("@#{key}")).to eq(value)
        end
      end
    end

    describe "#purchase" do
      it "intitates a purchase on the store controller" do
        @controller.stub!(:purchase) do |id|
          expect(id).to eq(@subject.id)
        end

        @subject.purchase
      end
    end

    describe "#purchased" do
      it "checks purchased status on the store controller" do
        @controller.stub!(:purchased?, return: true) do |id|
          expect(id).to eq(@subject.id)
        end

        expect(@subject.purchased?).to be_true
      end
    end

    describe "#on / #trigger" do
      it "raises when neither a handler proc or block is passed" do
        lambda {
          @subject.on(:some_event)
        }.should.raise(ArgumentError)
      end

      context "when a proc is passed" do
        before do
          @proc = ->{}
          @subject.on :some_event, @proc
        end

        it "adds the proc as an event handler for the event name" do
          @proc.stub!(:call) { @proc_called = true }
          @subject.trigger(:some_event)

          expect(@proc_called).to be_true
        end
      end

      context "when a block is passed" do
        before do
          @subject.on :some_event { @block_called = true }
        end

        it "adds the block as an event handler for the event name" do
          @subject.trigger(:some_event)

          expect(@block_called).to be_true
        end
      end

      context "when both a proc and a block are passed" do
        before do
          @proc = ->{}
          @proc.stub!(:call) { @proc_called = true }
          @subject.on :some_event, @proc { @block_called = true }
          @subject.trigger(:some_event)
        end

        it "calls the proc" do
          expect(@proc_called).to be_true
        end

        it "calls the block" do
          expect(@block_called).to be_true
        end
      end
    end

    describe "#off" do
      before do
        @proc_called = @block_called = false
        @proc = ->{}
        @proc.stub!(:call) { @proc_called = true }
        @subject.on :some_event, @proc { @block_called = true }
        @subject.off(:some_event)
        @subject.trigger(:some_event)
      end

      it "removes all event listeners for the given event name" do
        expect(@proc_called).to be_false
        expect(@block_called).to be_false
      end
    end

  end # end instance methods

end
