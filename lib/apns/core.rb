module APNS
  require 'socket'
  require 'openssl'
  require 'json'

  TIMEOUT = 0.2

  @host = 'gateway.sandbox.push.apple.com'
  @port = 2195
  # openssl pkcs12 -in mycert.p12 -out client-cert.pem -nodes -clcerts
  @pem = nil # this should be the path of the pem file not the contentes
  @pass = nil
  @pem_contents # alternative way to specify pem certificate, overrides pem file path

  class << self
    attr_accessor :host, :pem, :port, :pass, :pem_contents
  end

  def self.send_notification(device_token, message)
    n = APNS::Notification.new(device_token, message)
    self.send_notifications([n])
  end

  # improved send_notification to listen on errors
  def self.send_notifications(notifications)
    error = 0; idx = 0
    sock, ssl = self.open_connection

    # prepares the messages to be send
    notifications.each_with_index{|apns_notf, idx| apns_notf.message_identifier = [idx].pack('N')}

    # packs all notifications into a single pack
    packed_nofications = self.packed_nofications(notifications)

    # sends the notifications
    ssl.write(packed_nofications)         

      # if we get and error
      if IO.select([ssl], nil, nil, TIMEOUT)
        
        if buffer = ssl.read(6)
          _, error_code, idx = buffer.unpack('CCN')
          error = error_code.to_i
        end
      end

    ssl.close
    sock.close

    return error, idx
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

  def self.get_pem
    return self.pem_contents unless self.pem_contents.nil?

    raise "The path to your pem file is not set. (APNS.pem = /path/to/cert.pem)" unless self.pem
    raise "The path to your pem file does not exist!" unless File.exist?(self.pem)

    File.read(self.pem)
  end

  def self.open_connection
    cert_contents = self.get_pem

    context      = OpenSSL::SSL::SSLContext.new
    context.cert = OpenSSL::X509::Certificate.new(cert_contents)
    context.key  = OpenSSL::PKey::RSA.new(cert_contents, self.pass)

    sock         = TCPSocket.new(self.host, self.port)
    ssl          = OpenSSL::SSL::SSLSocket.new(sock,context)
    ssl.connect

    return sock, ssl
  end

  def self.feedback_connection
    cert_contents = self.get_pem

    context      = OpenSSL::SSL::SSLContext.new
    context.cert = OpenSSL::X509::Certificate.new(cert_contents)
    context.key  = OpenSSL::PKey::RSA.new(cert_contents, self.pass)

    fhost = self.host.gsub('gateway','feedback')
    puts fhost

    sock         = TCPSocket.new(fhost, 2196)
    ssl          = OpenSSL::SSL::SSLSocket.new(sock,context)
    ssl.connect

    return sock, ssl
  end
end
