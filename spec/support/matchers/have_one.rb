RSpec::Matchers.define :have_one do |resource, klass|
  match do |actual|
    actual.send(resource).class.should == klass
  end
end
