require 'apns/connector'
require 'apns/notification'

module APNS

  # We are a connector
  include Connector

  # And we have a class Client, which is also a connector
  class Client
    include Connector
  end

end
