require 'spec_helper'

describe APNS::Client do

  context 'when changing fields' do

    let(:client) { APNS::Client.new }

    before do
      client.port = 6400
    end

    it 'should have a different port' do
      client.port.should_not == APNS.port
    end

  end

end
