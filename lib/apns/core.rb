module APNS
  require "net/http"
  require 'socket'
  require 'openssl'
  require 'json'
  require 'uri'

  @host = 'gateway.sandbox.push.apple.com'
  @port = 2195
  # openssl pkcs12 -in mycert.p12 -out client-cert.pem -nodes -clcerts
  @pem = nil # this should be the path of the pem file not the contentes
  @pass = nil

  class << self
    attr_accessor :host, :pem, :port, :pass, :proxy
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

  def self.open_conn_with_proxy(host, port)
    return TCPSocket.new(self.host, self.port) unless self.proxy.present?

    proxy_uri = URI.parse(self.proxy)
    sock = TCPSocket.new(proxy_uri.host, proxy_uri.port)
    sock << "CONNECT #{self.host}:#{self.port} HTTP/1.1\r\n"
    sock << "Host: #{self.host}:#{self.port}\r\n"
    sock << "Proxy-Authorization: Basic #{["#{proxy_uri.user}:#{proxy_uri.password}"].pack("m").chomp}\r\n" if proxy_uri.user
    sock << "\r\n"

    buffer = Net::BufferedIO.new(sock)
    response = Net::HTTPResponse.read_new(buffer)
    if not response.is_a? Net::HTTPOK
      raise SocketError.new("Proxy refused connection [#{response.code}]")
    end

    return sock
  end

  def self.open_connection
    raise "The path to your pem file is not set. (APNS.pem = /path/to/cert.pem)" unless self.pem
    raise "The path to your pem file does not exist!" unless File.exist?(self.pem)

    context      = OpenSSL::SSL::SSLContext.new
    context.cert = OpenSSL::X509::Certificate.new(File.read(self.pem))
    context.key  = OpenSSL::PKey::RSA.new(File.read(self.pem), self.pass)

    sock         = self.open_conn_with_proxy(self.host, self.port)
    ssl          = OpenSSL::SSL::SSLSocket.new(sock,context)
    ssl.connect

    return sock, ssl
  end

  def self.feedback_connection
    raise "The path to your pem file is not set. (APNS.pem = /path/to/cert.pem)" unless self.pem
    raise "The path to your pem file does not exist!" unless File.exist?(self.pem)

    context      = OpenSSL::SSL::SSLContext.new
    context.cert = OpenSSL::X509::Certificate.new(File.read(self.pem))
    context.key  = OpenSSL::PKey::RSA.new(File.read(self.pem), self.pass)

    fhost = self.host.gsub('gateway','feedback')
    puts fhost

    sock         = self.open_conn_with_proxy(fhost, 2196)
    ssl          = OpenSSL::SSL::SSLSocket.new(sock,context)
    ssl.connect

    return sock, ssl
  end
end
