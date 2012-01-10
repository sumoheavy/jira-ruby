RSpec::Matchers.define :have_many do |collection, klass|
  match do |actual|
    actual.send(collection).class.should == Array
    actual.send(collection).length.should > 0
    actual.send(collection).each do |member|
      member.class.should == klass
    end
  end
end
