require "lib/ec2-starter"

service_options = {
  :access_key_id => "YOUR KEY",
  :secret_access_key => "YOUR SECRET",
  :server => "eu-west-1.ec2.amazonaws.com" # Target Zone
}

start_options = {
  :instance_type => "t1.micro",
  :key_name => "YOUR KEY",
  :availability_zone => "eu-west-1a",
  :architecture => "x86_64",
  :kernel_id => 'aki-4feec43b', # your kernel, remove if not needed
  :ssh_user => 'deploy',
  :ssh_keys => ['/Users/your_user/.ssh/your_key']
}

Ec2Starter.start 'YOUR AMI_ID', service_options, start_options do
  ip 'YOUR ELASTIC IP'
  volume :volume_id => 'YOUR VOLUME', :mount_point => '/dev/sdf'
  command '/root/attach_volume.sh' # Shell command on the instance
end