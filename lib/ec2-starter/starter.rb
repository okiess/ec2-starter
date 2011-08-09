module Ec2Starter
  def self.start(ami_id, service_options, run_options, &block)
    instance = Instance.new(ami_id, service_options, run_options)
    instance.instance_eval(&block)
    ec2_starter = Ec2Starter::Execution.new(instance)
    ec2_starter.start
    return instance
  end

  class Instance
    attr_accessor :service_options, :default_options, :ami_id, :instance_id, :ips, :volumes, :commands

    def initialize(ami_id, service_options, options)
      @ami_id = ami_id.to_s
      @ips = []
      @volumes = []
      @commands = []
      @default_options = {}.merge(options)
      @service_options = {}.merge(service_options)
    end

    def ip(ip_address)
      @ips << ip_address
    end

    def volume(volume_hash)
      @volumes << volume_hash
    end

    def command(command)
      @commands << command
    end
  end
end
