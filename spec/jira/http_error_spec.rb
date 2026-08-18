require 'spec_helper'

describe JIRA::HTTPError do
  subject { described_class.new(response) }

  let(:response) do
    response = double('response')
    allow(response).to receive_messages(code: 401, message: 'A MESSAGE WOO')
    response
  end

  it 'takes the response object as an argument' do
    expect(subject.response).to eq(response)
  end

  it 'has a code method' do
    expect(subject.code).to eq(response.code)
  end

  it 'returns code and class from message' do
    expect(subject.message).to eq(response.message)
  end

  it 'gives the same text for to_s as for message' do
    expect(subject.to_s).to eq(response.message)
  end

  context 'when the response has no message' do
    let(:response) do
      response = double('response')
      allow(response).to receive_messages(code: 500, message: nil, body: 'THE BODY')
      response
    end

    it 'uses the body as the message' do
      expect(subject.message).to eq('THE BODY')
    end
  end
end
