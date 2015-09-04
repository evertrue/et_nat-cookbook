# et_nat cookbook

A cookbook to provide a NAT for an EC2 VPC (with HA if desired)

# Requirements

* An EC2 VPC
* 1 VPC node for a simple NAT or 3 VPC nodes for HA

# Usage

* Include `et_nat::default` in your node’s run list.
* Refer to @eherot’s [“The Right Way to set up NAT in EC2” blog post](http://evertrue.github.io/blog/2015/07/06/the-right-way-to-set-up-nat-in-ec2/) for more details.

When creating instances using this cookbook, in order to assign a public IP address in your VPC, you’ll want to use a command like this:

```bash
knife ec2 server create \
    -E prod \
    -N prod-nat \
    -s subnet-xxxxxxxx \
    -f c3.large \
    -g sg-xxxxxxxx \
    -r "recipe[xyz]" \
    --iam-profile nat-ha \
    --associate-public-ip
```

The `--associate-public-ip` is especially crucial, as otherwise, the instance will be unable to connect out, nor will it function as a NAT.

### Network Configuration

# Attributes

* `['nat']['yaml']['mocking']`: Default value is `true`

# Recipes

## default

* Installs Fog for making AWS API calls
* Uses the other two recipes in this cookbook to set up the NAT mechanisms

## ha

* Provides mechanisms for maintaining high availability of a cluster of NAT instances using Chef Search & a NAT monitor script

## iptables

* Does the bulk of the work to set up the NAT

# Author

Author:: Eric Herot (<eric.herot@evertrue.com>)
