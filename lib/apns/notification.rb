module APNS
  require 'openssl'

  class Notification
    attr_accessor :device_token, :alert, :badge, :sound, :category, :other, :priority
    attr_accessor :message_identifier, :expiration_date
    attr_accessor :content_available

    def initialize(device_token, message)
      self.device_token = device_token
      if message.is_a?(Hash)
        self.alert = message[:alert]
        self.badge = message[:badge]
        self.sound = message[:sound]
        self.category = message[:category]
        self.other = message[:other]
        self.message_identifier = message[:message_identifier]
        self.content_available = !message[:content_available].nil?
        self.expiration_date = message[:expiration_date]
        self.priority = if self.content_available
          message[:priority] || 5
        else
          message[:priority] || 10
        end
      elsif message.is_a?(String)
        self.alert = message
      else
        raise "Notification needs to have either a hash or string"
      end

      self.message_identifier ||= OpenSSL::Random.random_bytes(4)
    end

    def packaged_notification
      pt = self.packaged_token
      pm = self.packaged_message
      pi = self.message_identifier
      pe = (self.expiration_date || 0).to_i
      pr = (self.priority || 10).to_i

      # Each item consist of
      # 1. unsigned char [1 byte] is the item (type) number according to Apple's docs
      # 2. short [big endian, 2 byte] is the size of this item
      # 3. item data, depending on the type fixed or variable length
      data = ''
      data << [1, pt.bytesize, pt].pack("CnA*")
      data << [2, pm.bytesize, pm].pack("CnA*")
      data << [3, pi.bytesize, pi].pack("CnA*")
      data << [4, 4, pe].pack("CnN")
      data << [5, 1, pr].pack("CnC")

      data
    end

    def packaged_token
      [device_token.gsub(/[\s|<|>]/,'')].pack('H*')
    end

    def packaged_message
      aps = {'aps'=> {} }
      aps['aps']['alert'] = self.alert if self.alert
      aps['aps']['badge'] = self.badge if self.badge
      aps['aps']['sound'] = self.sound if self.sound
      aps['aps']['category'] = self.category if self.category
      aps['aps']['content-available'] = 1 if self.content_available

      aps.merge!(self.other) if self.other
      aps.to_json
    end
  end
end
