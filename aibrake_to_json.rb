# encoding: utf-8

Application.configure do
  config.lograge.enabled = true
  config.lograge.keep_original_rails_log = false
  config.lograge.logger = ActiveSupport::Logger.new "#{Rails.root}/log/#{Rails.env}.log" 
  config.lograge.formatter = Lograge::Formatters::Json.new
  
  # Ignore errors with Lograge, will send them through Airbrake,
  # so we have ez access to all the airbrake infos
  config.lograge.ignore_custom = lambda do |event|
    event.payload.has_key?(:exception)
  end

  config.lograge.custom_options = ->(event) {
    {
      time:  %Q('#{event.time}'),
      remote_ip: event.payload[:ip],
      current_user: event.payload[:current_user],
      current_administrator: event.payload[:current_administrator],
      params: event.payload[:params]
    }
  }
end

Airbrake.configure do |config|
  config.logger  = Logger.new("log/airbrake_#{Rails.env}.log")
  config.api_key = ###
  config.host    = ###
  config.port    = ###
  config.secure  = ###
  config.development_environments = ["development", "test"]
end

module Airbrake
  class << self
    def sender
      Airbrake::Sender.new(configuration)
    end

    private

    def send_notice(notice)
      sender.send_to_airbrake(notice)
    end
  end

  class Sender
    def send_to_airbrake(notice)
      data = prepare_notice(notice)
      Lograge.logger.error(data)
    end

    def json_api_enabled?
      true
    end
  end

  class Notice
    def backtrace
      exception_attribute(:backtrace, caller).join("\n")
    end

    def to_json
      # please check out Airbrake::Notice to know how and where to get your data from
      # 
      # https://github.com/airbrake/airbrake/blob/master/lib/airbrake/notice.rb#L211
      #
      # def to_json
      #     MultiJson.dump({
      #       'notifier' => {
      #         'name'    => 'airbrake',
      #         'version' => Airbrake::VERSION,
      #         'url'     => 'https://github.com/airbrake/airbrake'
      #         },
      #       'errors' => [{
      #           'type'       => error_class,
      #           'message'    => error_message,
      #           'backtrace'  => backtrace.lines.map do |line|
      #               {
      #                 'file'     => line.file,
      #                 'line'     => line.number.to_i,
      #                 'function' => line.method_name
      #               }
      #           end
      #         }],
      #        'context' => {}.tap do |hash|
      #           if request_present?
      #             hash['url']           = url
      #             hash['component']     = controller
      #             hash['action']        = action
      #             hash['rootDirectory'] = File.dirname(project_root)
      #             hash['environment']   = environment_name
      #           end
      #          end.tap do |hash|
      #           next if user.empty?
      # 
      #           hash['userId']    = user[:id]
      #           hash['userName']  = user[:name]
      #           hash['userEmail'] = user[:email]
      #         end
      # 
      #     }.tap do |hash|
      #         hash['environment'] = cgi_data     unless cgi_data.empty?
      #         hash['params']      = parameters   unless parameters.empty?
      #         hash['session']     = session_data unless session_data.empty?
      #     end)
      #   end
      
      { controller: controller,
        method: action,
        format: 'html', # you need to put actual stuff in here so it matches lograge structures
        params: parameters,
        env: "HELLO", # you need to put actual stuff in here
        duration: 1430.03, # you need to put actual stuff in here
        path: url,
        view: 903.63, # you need to put actual stuff in here
        remote_ip: 109.237.241.212, # you need to put actual stuff in here
        current_administrator: user[:email], # this is just an extra key for errors, can add more..
        action: action, 
        time: Time.now.utc,
        db: 497.16, # you need to put actual stuff in here
        status: 200, # you need to put actual stuff in here
        current_user: user[:email], 
        message: "ERROR " + error_message,
        backtrace: backtrace
      }.to_json
    end
  end
end
