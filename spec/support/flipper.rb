require "flipper"
require "flipper/adapters/memory"

RSpec.configure do |config|
  config.before(:each) do
    Flipper.instance = Flipper.new(Flipper::Adapters::Memory.new)
  end
end
