module Ec2Starter
  def self.start(ami_id, options, &block)
    instance = Instance.new(ami_id, options)
    instance.instance_eval(&block)
    ec2_starter = Ec2Starter::Execution.new(instance)
    ec2_starter.start
    return instance
  end

  class Instance
    attr_accessor :default_options, :ami_id, :instance_id, :ips, :volumes, :commands

    def initialize(ami_id, options)
      @ami_id = ami_id.to_s
      @ips = []
      @volumes = []
      @commands = []
      @default_options = options
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

    def options(hash = {})
      @default_options = hash
    end
  end
end
