require File.dirname(__FILE__) + '/../spec_helper'

describe APNS::Notification do
  
  it "should take a string as the message" do
    n = APNS::Notification.new('device_token', 'Hello')
    n.alert.should == 'Hello'
  end
  
  it "should take a hash as the message" do
    n = APNS::Notification.new('device_token', {:alert => 'Hello iPhone', :badge => 3})
    n.alert.should == "Hello iPhone"
    n.badge.should == 3
  end
  
  describe '#packaged_message' do
    
    it "should return JSON with notification information" do
      n = APNS::Notification.new('device_token', {:alert => 'Hello iPhone', :badge => 3, :sound => 'awesome.caf'})
      n.packaged_message.should  == "{\"aps\":{\"alert\":\"Hello iPhone\",\"badge\":3,\"sound\":\"awesome.caf\"}}"
    end
    
    it "should not include keys that are empty in the JSON" do
      n = APNS::Notification.new('device_token', {:badge => 3})
      n.packaged_message.should == "{\"aps\":{\"badge\":3}}"
    end
    
  end
  
  describe '#package_token' do
    it "should package the token" do
      n = APNS::Notification.new('<5b51030d d5bad758 fbad5004 bad35c31 e4e0f550 f77f20d4 f737bf8d 3d5524c6>', 'a')
      Base64.encode64(n.packaged_token).should == "W1EDDdW611j7rVAEutNcMeTg9VD3fyDU9ze/jT1VJMY=\n"
    end
  end

  describe '#packaged_notification' do
    it "should package the token" do
      n = APNS::Notification.new('device_token', {:alert => 'Hello iPhone', :badge => 3, :sound => 'awesome.caf'})
      Base64.encode64(n.packaged_notification).should == "AAAg3vLO/YTnAEB7ImFwcyI6eyJhbGVydCI6IkhlbGxvIGlQaG9uZSIsImJh\nZGdlIjozLCJzb3VuZCI6ImF3ZXNvbWUuY2FmIn19\n"
    end
  end
  
end
