module APNS
  require 'socket'
  require 'openssl'
  require 'json'

  @host = 'gateway.sandbox.push.apple.com'
  @port = 2195
  # openssl pkcs12 -in mycert.p12 -out client-cert.pem -nodes -clcerts
  @pem = nil # this should be the path of the pem file not the contentes
  @pass = nil

  class << self
    attr_accessor :host, :pem, :port, :pass
  end
  
  def self.send_notification(device_token, message)
    n = APNS::Notification.new(device_token, message)
    self.send_notifications([n])
  end
  
  def self.send_notifications(notifications)
    with_connection(NotificationConnection) do |conn|
      conn.send_notifications(notifications)
    end
  end
  
  def self.feedback
    with_connection(FeedbackConnection) do |conn|
      conn.feedback
    end
  end
  
  protected

  def self.with_connection(type)
    raise "The path to your pem file is not set. (APNS.pem = /path/to/cert.pem)" unless self.pem

    connection = type.new(:host => self.host, :port => self.port, :pem => self.pem, :pass => self.pass)
    yield connection
  
  ensure
    connection.close if connection    
  end

  def self.feedback_host
    self.host.gsub('gateway','feedback')
  end
end
