module Ec2Starter
  class Execution
    attr_accessor :ec2_instance, :dns_name

    def initialize(ec2_instance)
      @ec2_instance = ec2_instance
    end

    def start
      success = false
      result = launch_ami(@ec2_instance.ami_id)
      instance_id = result.instancesSet.item[0].instanceId
      puts "=> Starting Instance Id: #{instance_id.white}"

      instance_state = nil
      while(instance_state != 'running')
        instance_state, @dns_name = get_instance_state(instance_id)
        puts "=> Checking for running state... #{output_running_state(instance_state)}"
        puts "=> Public DNS: #{@dns_name.white}" if instance_state == 'running'
        sleep 10 unless instance_state == 'running'
      end

      if @ec2_instance.ips.size > 0
        result = ec2.associate_address(:instance_id => instance_id, :public_ip => @ec2_instance.ips.first)
        puts "=> Elastic IP: #{@ec2_instance.ips.first.white}" if result["return"] == "true"
      else
        skip_ip = true
      end
      if result["return"] == "true" or skip_ip
        if @ec2_instance.volumes.size > 0
          result = ec2.attach_volume(:volume_id => @ec2_instance.volumes.first[:volume_id], :instance_id => instance_id,
           :device => @ec2_instance.volumes.first[:mount_point])

          volume_state = nil
          while(volume_state != 'attached')
            volume_state = get_volume_state(@ec2_instance.volumes.first[:volume_id])
            puts "=> Checking for attachment state... #{output_running_state(volume_state)}"
            sleep 10 unless volume_state == 'attached'
          end

          success = true
          puts "=> EBS Volume attached: #{@ec2_instance.volumes.first[:volume_id]}"
        end
        if @ec2_instance.commands.size > 0
          ip = @ec2_instance.ips.first || @dns_name
          system("ssh-keygen -R #{ip}")
          i = 0
          while(i < 3) do
            begin
              ssh
              break
            rescue => e
              puts e.message
              puts "Retrying in 10sec..."
              sleep 10
            end
            i += 1
          end
          success = true
          puts "=> SSH Commands were executed!"
        end
      else
        puts "=> Could not assign Elastic IP!"
      end

      unless success
        puts "Terminating instance: #{instance_id}".red
        @ec2.terminate_instances(:instance_id => instance_id)
      end
    end

    def ssh
      ip = @ec2_instance.ips.first || @dns_name
      Net::SSH.start(ip, @ec2_instance.default_options[:ssh_user], :keys => @ec2_instance.default_options[:ssh_keys]) do |ssh|
        @ec2_instance.commands.each do |command|
          if command.is_a?(String)
            ssh.exec(command)
          elsif command.is_a?(Hash) and command.include?(:sudo)
            ssh.sudo @ec2_instance.default_options[:sudo_password], command[:sudo]
          end
        end
        ssh.close
      end
    end

    def ec2
       @ec2 ||= AWS::EC2::Base.new(:access_key_id => @ec2_instance.service_options[:access_key_id],
        :secret_access_key => @ec2_instance.service_options[:secret_access_key],
        :server => @ec2_instance.service_options[:server])
    end

    def get_instance_state(instance_id)
      result = ec2.describe_instances(:instance_id => instance_id)
      instance_state = result["reservationSet"]["item"].first["instancesSet"]["item"].first["instanceState"]["name"]
      dns_name = result["reservationSet"]["item"].first["instancesSet"]["item"].first["dnsName"]
      return instance_state, dns_name
    end

    def get_volume_state(volume_id)
      result = ec2.describe_volumes(:volume_id => volume_id)
      volume_state = result["volumeSet"]["item"].first["attachmentSet"]["item"].first["status"]
      return volume_state
    end

    def launch_ami(ami_id, options = {})
      default_options = @ec2_instance.default_options.merge(:image_id => ami_id).merge(options)
      run_options = default_options.merge(options)
      puts "Launch Options: #{run_options.inspect}"
      ec2.run_instances(run_options)
    end

    def output_running_state(running_state)
      if running_state == 'running' or running_state == 'attached'
        running_state.green
      elsif running_state == 'terminated' or running_state == 'shutting-down'
        running_state.red
      elsif running_state == 'pending' or running_state == 'attaching'
        running_state.yellow
      else
        running_state
      end
    end
  end
end

class String
  def green
    "\033[32m#{self}\033[0m" 
  end

  def red
    "\033[31m#{self}\033[0m"
  end

  def yellow
    "\033[33m#{self}\033[0m"
  end

  def white
    "\033[1m#{self}\033[0m"
  end
end

class Net::SSH::Connection::Session
  def sudo(password, command)
    exec %Q%echo "#{password}" | sudo -S #{command}% 
  end
end
