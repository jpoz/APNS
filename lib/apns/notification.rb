module APNS
  class Notification
    attr_accessor :device_token, :alert, :badge, :sound, :other
    
    def send_notification
      APNS.send_notification(self.device_token, )
    end
  end
end
