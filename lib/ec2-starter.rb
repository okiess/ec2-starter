require 'rubygems'
gem "net-ssh"
require 'net/ssh'
gem 'amazon-ec2'
require 'AWS'

require File.dirname(__FILE__) + '/ec2-starter/starter'
require File.dirname(__FILE__) + '/ec2-starter/execution'
