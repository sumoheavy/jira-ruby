require 'spec_helper'

describe JIRA::HTTPError do
  let(:response) do
    response = double('response')
    allow(response).to receive(:code).and_return(401)
    allow(response).to receive(:message).and_return('A MESSAGE WOO')
    response
  end

  subject { described_class.new(response) }

  it 'takes the response object as an argument' do
    expect(subject.response).to eq(response)
  end

  it 'has a code method' do
    expect(subject.code).to eq(response.code)
  end

  it 'returns code and class from message' do
    expect(subject.message).to eq(response.message)
  end
end
