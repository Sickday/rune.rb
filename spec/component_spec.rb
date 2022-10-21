require 'spec_helper'

describe RuneRb::Component do
  describe '#new' do
    it "calls Component#setup in it's constructor" do
      expect { RuneRb::Component.new }.to raise_error(NoMethodError, 'The Component#setup function is abstract and has not been defined!')
    end
  end
end
