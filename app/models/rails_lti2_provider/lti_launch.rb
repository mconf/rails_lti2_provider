require 'ims/lti'

module RailsLti2Provider
  class LtiLaunch < ActiveRecord::Base
    validates_presence_of :tool_id, :nonce
    belongs_to :tool
    serialize :message

    def self.check_launch(lti_message)
      tool = Tool.find_by_uuid(lti_message.oauth_consumer_key)
      all_params = lti_message.post_params.merge(lti_message.oauth_params)

      Rails.logger.info "Checking launch for consumer_key=#{tool&.uuid} " \
                        "secret=#{tool&.shared_secret} launch_url=#{lti_message.launch_url} " \
                        "params=#{all_params.to_json}"

      raise Unauthorized.new(:invalid_key) unless tool
      raise Unauthorized.new(:invalid_signature) unless IMS::LTI::Services::MessageAuthenticator.new(lti_message.launch_url, all_params, tool.shared_secret).valid_signature?
      raise Unauthorized.new(:invalid_nonce) if tool.lti_launches.where(nonce: lti_message.oauth_nonce).count > 0
      raise Unauthorized.new(:request_too_old) if  DateTime.strptime(lti_message.oauth_timestamp,'%s') < 5.minutes.ago

      Rails.logger.info "Removing the old launches from before #{1.day.ago}"
      tool.lti_launches.where('created_at < ?', 1.day.ago).delete_all

      launch = tool.lti_launches.create!(nonce: lti_message.oauth_nonce, message: lti_message.post_params)
      Rails.logger.info "Launch created launch=#{launch.inspect}"
      launch
    end

    def message
      IMS::LTI::Models::Messages::Message.generate(read_attribute(:message))
    end

    def jwt_body
      read_attribute(:message)
    end

    class Unauthorized < StandardError;
      attr_reader :error
      def initialize(error = :unknown)
        @error = error
      end
    end
  end
end
