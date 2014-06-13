module APNS
  require 'socket'
  require 'openssl'
  require 'json'

  @host = 'gateway.sandbox.push.apple.com'
  @port = 2195
  # openssl pkcs12 -in mycert.p12 -out client-cert.pem -nodes -clcerts
  @pem = nil # this should be the path of the pem file not the contentes
  @pem_contents = nil # Alternative, this is the contents of the pem file instead of the file path
  @pass = nil

  class << self
    attr_accessor :host, :pem, :port, :pass, :pem_contents
  end

  def self.send_notification(device_token, message)
    n = APNS::Notification.new(device_token, message)
    self.send_notifications([n])
  end

  def self.send_notifications(notifications)
    sock, ssl = self.open_connection

    packed_nofications = self.packed_nofications(notifications)

    notifications.each do |n|
      ssl.write(packed_nofications)
    end

    ssl.close
    sock.close
  end

  def self.packed_nofications(notifications)
    bytes = ''

    notifications.each do |notification|
      # Each notification frame consists of
      # 1. (e.g. protocol version) 2 (unsigned char [1 byte]) 
      # 2. size of the full frame (unsigend int [4 byte], big endian)
      pn = notification.packaged_notification
      bytes << ([2, pn.bytesize].pack('CN') + pn)
    end

    bytes
  end

  def self.feedback
    sock, ssl = self.feedback_connection

    apns_feedback = []

    while message = ssl.read(38)
      timestamp, token_size, token = message.unpack('N1n1H*')
      apns_feedback << [Time.at(timestamp), token]
    end

    ssl.close
    sock.close

    return apns_feedback
  end

  protected

  def self.open_connection
    context self.get_context
    sock = TCPSocket.new(self.host, self.port)
    ssl = OpenSSL::SSL::SSLSocket.new(sock,context)
    ssl.connect
    return sock, ssl
  end

  def self.feedback_connection
    context = self.get_context

    fhost = self.host.gsub('gateway','feedback')
    puts fhost

    sock = TCPSocket.new(fhost, 2196)
    ssl = OpenSSL::SSL::SSLSocket.new(sock,context)
    ssl.connect
    return sock, ssl
  end

  def self.get_context
    context      = OpenSSL::SSL::SSLContext.new
    if self.pem
      raise "The path to your pem file does not exist!" unless File.exist?(self.pem)
      context.cert = OpenSSL::X509::Certificate.new(File.read(self.pem))
      context.key  = OpenSSL::PKey::RSA.new(File.read(self.pem), self.pass)
    elsif self.pem_contents
      raise "The contents to your pem file are empty!" unless self.pem_contents.empty?
      context.cert = OpenSSL::X509::Certificate.new(self.pem_contents)
      context.key  = OpenSSL::PKey::RSA.new(self.pem_contents, self.pass)
    else
      raise "The path to your pem file is not set. (APNS.pem = /path/to/cert.pem)" unless self.pem
    end
    return context
  end

end
