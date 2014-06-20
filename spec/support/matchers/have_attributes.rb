RSpec::Matchers.define :have_attributes do |expected|
  match do |actual|
    expected.each do |key, value|
      actual.attrs[key].should == value
    end
  end

  failure_message do |actual|
    "expected #{actual.attrs} to match #{expected}"
  end
end
