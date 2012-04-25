require 'socket'
require 'openssl'
require 'json'

module APNS
  module Connector

    attr_accessor :host, :pem, :port, :pass

    def initialize(host = GATEWAY_HOST, port = 2195, pem = nil, pass = nil)
      @host = host
      @port = port
      @pem = pem
      @pass = pass
    end

    def send_notification(device_token, message)
      n = APNS::Notification.new(device_token, message)
      send_notifications([n])
    end

    def send_notifications(notifications)
      sock, ssl = open_connection

      notifications.each do |n|
        ssl.write(n.packaged_notification)
      end

      ssl.close
      sock.close
    end

    def feedback
      sock, ssl = feedback_connection

      apns_feedback = []

      while line = sock.gets # Read lines from the socket
        line.strip!
        f = line.unpack('N1n1H140')
        apns_feedback << [Time.at(f[0]), f[2]]
      end

      ssl.close
      sock.close

      apns_feedback
    end

    protected

    def open_connection
      check_pem!

      context      = OpenSSL::SSL::SSLContext.new
      context.cert = OpenSSL::X509::Certificate.new(read_pem)
      context.key  = OpenSSL::PKey::RSA.new(read_pem, pass)

      sock         = TCPSocket.new(host, port)
      ssl          = OpenSSL::SSL::SSLSocket.new(sock, context)
      ssl.connect

      [sock, ssl]
    end

    def feedback_connection
      check_pem!

      context      = OpenSSL::SSL::SSLContext.new
      context.cert = OpenSSL::X509::Certificate.new(read_pem)
      context.key  = OpenSSL::PKey::RSA.new(read_pem, pass)

      fhost = host.gsub!('gateway', 'feedback')

      sock         = TCPSocket.new(fhost, 2196)
      ssl          = OpenSSL::SSL::SSLSocket.new(sock, context)
      ssl.connect

      [sock, ssl]
    end

    private

    def check_pem!
      raise "the path to your pem file is not set. (apns.pem = /path/to/cert.pem)" unless self.pem
      raise "the path to your pem file does not exist!" unless pem_exists?
    end

    def pem_exists?
      File.exist?(pem)
    end

    def read_pem
      File.read(pem)
    end

  end

end
