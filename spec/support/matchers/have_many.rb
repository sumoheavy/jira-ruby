RSpec::Matchers.define :have_many do |collection, klass|
  match do |actual|
    expect(actual.send(collection).class).to eq(JIRA::HasManyProxy)
    expect(actual.send(collection).length).to be > 0
    actual.send(collection).each do |member|
      expect(member.class).to eq(klass)
    end
  end
end
