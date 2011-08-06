require "lib/ec2-starter"

start_options = {
  :access_key_id => "1FWCY02HG318RPREDQG2",
  :secret_access_key => "T/0kFxHvMEmJ/ylac9bFdoefk4sRHc0oVUUZb82r",
  :server => "eu-west-1.ec2.amazonaws.com",
  :instance_type => "t1.micro",
  :key_name => "gsg-keypair",
  :availability_zone => "eu-west-1a",
  :architecture => "x86_64"
}

Ec2Starter.start 'ami-7d95a209', start_options do
  ip '46.137.173.240'
  volume :volume_id => 'vol-16c5207f', :mount_point => '/dev/sdf'
  command '/root/attach_volume.sh && sleep 5; sudo /etc/init.d/mysql stop; sleep 2; sudo killall mysqld; sleep 5 && sudo /etc/init.d/mysql start'
end
