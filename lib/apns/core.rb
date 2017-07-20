module APNS
  require 'socket'
  require 'openssl'
  require 'json'

  @host = 'gateway.sandbox.push.apple.com'
  @port = 2195
  # openssl pkcs12 -in mycert.p12 -out client-cert.pem -nodes -clcerts
  @pems = {} 
  # this should be the path of the pem file not the contentes
  # Example:
  # { some_ios_app : "file/to/pem" }

  @pass = nil

  class << self
    attr_accessor :host, :pems, :port, :pass
  end

  def self.pem=(default_pem_path)
    @pems = { default: default_pem_path }
  end

  def self.send_notification(app_or_device_token, device_token_or_message, message = nil)
    app, device_token, message = begin
      if message.nil?
       [:default, app_or_device_token, device_token_or_message]
      else
       [app_or_device_token, device_token_or_message, message]
      end
    end

    n = APNS::Notification.new(device_token, message)
    self.send_notifications(app, [n])
  end

  def self.send_notifications(app_or_notifications, notifications = nil)
    app, notifications = begin
      if notifications.nil?
        [:default, app_or_notifications]
      else
        [app_or_notifications, notifications]
      end
    end

    sock, ssl = self.open_connection(app)

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

  def self.feedback(app = :default)
    sock, ssl = self.feedback_connection(app)

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

  def self.open_connection(app = :default)
    pem = self.pems[app]
    raise "The path to your pem file is not set. (APNS.pem = /path/to/cert.pem)" unless pem
    raise "The path to your pem file does not exist!" unless File.exist?(pem)

    context = build_context(pem)

    sock = build_socket(self.host, self.port)
    ssl  = build_ssl(context, sock)
    ssl.connect

    return sock, ssl
  end

  def self.feedback_connection(app = :default)
    pem = self.pems[app]
    raise "The path to your pem file is not set. (APNS.pem = /path/to/cert.pem)" unless pem
    raise "The path to your pem file does not exist!" unless File.exist?(pem)

    context = build_context(pem)

    fhost = self.host.gsub('gateway','feedback')
    puts fhost

    sock = build_socket(fhost, 2196)
    ssl  = build_ssl(context, sock)
    ssl.connect

    return sock, ssl
  end

  def self.build_context(pem)
    context      = OpenSSL::SSL::SSLContext.new
    pem_content  = File.read(pem)
    context.cert = OpenSSL::X509::Certificate.new(pem_content)
    context.key  = OpenSSL::PKey::RSA.new(pem_content, self.pass)
    context
  end

  def self.build_socket(host, port)
    TCPSocket.new(host, port)
  end

  def self.build_ssl(context, socket)
    OpenSSL::SSL::SSLSocket.new(socket,context)
  end
end
