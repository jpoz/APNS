require 'rubygems'
require 'json'
  
class Hash
  include JSON
end

module APNS
  require 'socket'
  require 'openssl'

  @host = 'gateway.sandbox.push.apple.com'
  @port = 2195
  # openssl pkcs12 -in mycert.p12 -out client-cert.pem -nodes -clcerts
  @pem = nil # this should be the path of the pem file not the contentes
  @pass = nil
  
  class << self
    attr_accessor :host, :pem, :port, :pass
  end
  
  def self.send_notification(device_token, message_hash)
    sock, ssl = self.open_connection  
    ssl.write(self.packaged_notification(device_token, message_hash))

    ssl.close
    sock.close
  end
  
  private

  def self.packaged_notification(device_token, message_hash)
    pt = self.packaged_token(device_token)
    pm = self.packaged_message(message_hash)
    [0, 0, 32, pt, 0, pm.size, pm].pack("ccca*cca*")
  end
  
  def self.packaged_token(device_token)
    [device_token.gsub(/[\s|<|>]/,'')].pack('H*')
  end
  
  def self.packaged_message(message_hash)
    message_hash.to_json
  end
  
  def self.open_connection
    raise "The path to your pem file is not set. (APNS.pem = /path/to/cert.pem)" unless self.pem
    raise "The path to your pem file does not exist!" unless File.exist?(self.pem)
    
    context = OpenSSL::SSL::SSLContext.new
    context.cert = OpenSSL::X509::Certificate.new(File.read(self.pem))
    context.key = OpenSSL::PKey::RSA.new(File.read(self.pem), self.pass)

    sock = TCPSocket.new(self.host, self.port)
    ssl = OpenSSL::SSL::SSLSocket.new(sock,context)
    ssl.connect

    return sock, ssl
  end
  
end
