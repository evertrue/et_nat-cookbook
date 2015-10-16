#
# Cookbook Name:: et_nat
# Recipe:: default
#
# Copyright (C) 2013 EverTrue, Inc.
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'et_fog'
include_recipe 'et_nat::iptables'
include_recipe 'et_nat::ha'
