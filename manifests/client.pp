# == Class: ipa::client
#
# IPA Client module for configurint ipa-client package, nsswitch,
# and sssd services
#
# === Parameters
#
# Document parameters here.
#
# domain
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# server
#
# domain
#
# sudo_search_base
#
# === Examples
#
#  class { 'ipa::client':
#    realm => 'EXAMPLE.COM',
#  }
#
# === Authors
#
# Scott Neel <scott@neel.net>
#
# === Copyright
#
# Copyright 2014 Scott Neel.
#

class ipa::client (
    $realm,
    $server = '',
    $domain = '',
    $sudo_search_base = '',
  ) inherits ipa {

  #Ensure the realm is uppercase
  $ipa_realm = upcase($realm)

  #If we have domain, default to downcased realm
  if $domain == '' {
    $ipa_domain = downcase($ipa_realm)
  } else {
    $ipa_domain = $domain
  }

  #If we have server, default to downcased domain
  if $server == '' {
    $ipa_server = $ipa_domain
  } else {
    $ipa_server = $server
  }

  #If we have search_Base, default to free-ipa's standard sudoers OU based on realm
  if $sudo_search_base == '' {
    $search_base = inline_template('ou=SUDOers,dc=<%= ipa_realm.split(".").join(",dc=") %>')
  } else {
    $search_base = $sudo_search_base
  }

  #Ensure ipa-client and libsss_sudo is installed
  package { [
      'ipa-client',
      'libsss_sudo',
      'sssd'
    ]:
    ensure => present,
  }

  augeas {'ipa_set_sss':
    context => '/files/etc/nsswitch.conf',
    changes => [
        'set database[. = "sudoers"] sudoers',
        'set database[. = "sudoers"]/service[1] files',
        'set database[. = "sudoers"]/service[2] sss'
      ]
  }

  file { '/etc/sssd/sssd.conf':
    ensure  => present,
    content => template('ipa/sssd.conf.erb'),
    notify  => Service['sssd'],
  }

  service { 'sssd':
    ensure => running,
    enable => true,
  }
}