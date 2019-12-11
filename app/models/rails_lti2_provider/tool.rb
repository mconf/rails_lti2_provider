module RailsLti2Provider
  class Tool < ActiveRecord::Base
    validates_presence_of :shared_secret, :uuid, :tool_settings, :lti_version
    serialize :tool_settings
    has_many :lti_launches
    has_many :registrations

    def tool_proxy
      IMS::LTI::Models::ToolProxy.from_json(tool_settings)
    end

    def self.find_by_issuer(issuer, options = {})
      options['uuid'] = issuer
      Tool.find_by(options)
    end
  end
end
