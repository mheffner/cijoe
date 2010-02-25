class CIJoe
  module Campfire
    def self.activate
      if valid_config?
        require 'broach'

        CIJoe::Build.class_eval do
          include CIJoe::Campfire
        end

        puts "Loaded Campfire notifier"
      else
        puts "Can't load Campfire notifier."
        puts "Please add the following to your project's .git/config:"
        puts "[campfire]"
        puts "\ttoken = 12345abcd"
        puts "\tsubdomain = whatever"
        puts "\troom = Awesomeness"
        puts "\tssl = false"
      end
    end

    def self.config
      @config ||= {
        :subdomain => Config.campfire.subdomain.to_s,
        :token      => Config.campfire.token.to_s,
        :room      => Config.campfire.room.to_s,
        :ssl       => Config.campfire.ssl.to_s.strip == 'true'
      }
    end

    def self.valid_config?
      %w( subdomain token room ).all? do |key|
        !config[key.intern].empty?
      end
    end

    def notify
      config = Campfire.config
      Broach.settings = {
        'account' => config[:subdomain],
        'token' => config[:token],
        'use_ssl' => config[:ssl] ? true : false
      }

      Broach.speak(config[:room], "#{short_message}. #{commit.url}")
      #room.speak "#{short_message}. #{commit.url}"
      #room.paste full_message if failed?
      #room.leave
    end

  private
    def room
      @room ||= begin
        config = Campfire.config
        options = {}
        options[:ssl] = config[:ssl] ? true : false
        campfire = Tinder::Campfire.new(config[:subdomain], options)
        campfire.login(config[:user], config[:pass])
        campfire.find_room_by_name(config[:room])
      end
    end

    def short_message
      "Build #{short_sha} of #{project} #{worked? ? "was successful" : "failed"}"
    end

    def full_message
      <<-EOM
Commit Message: #{commit.message}
Commit Date: #{commit.committed_at}
Commit Author: #{commit.author}

#{clean_output}
EOM
    end
  end
end
