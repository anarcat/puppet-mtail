# mtail is a log counting software we use to derive metrics from logfiles
#
# @param ensure to install or remove all resources in this class
# @param logs which log files to parse, if not default
# @param program_directory where the programs should be stored
# @param scrape_job if enabled, will export a `prometheus::scrape_job`
#                   for the prometheus central server to collect
# @param scrape_job_labels which labels to add to the exported job
# @param firewall which firewall to configure to allow connexions. hackish.
#
# Ideally, this would parse logs directly piped from syslog, so that
# we wouldn't have to specify conflicting LOGS parameters from
# different callers. But this requires piping (e.g.) Nginx access logs
# into syslog, which is currently a little bit of a problem:
# https://gitlab.torproject.org/tpo/tpa/team/-/issues/32461
class mtail(
  Enum['present','absent'] $ensure  = 'present',
  String $logs                      = undef,
  String $program_directory         = '/etc/mtail',
  Boolean $scrape_job               = true,
  Optional[Hash] $scrape_job_labels = {
    'alias'   => $::fqdn,
    'classes' => "role::${pick($::role, 'undefined')}",
  },
  Optional['ferm'] $firewall        = 'ferm',
) {
  if $ensure == 'present' {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }
  package { 'mtail':
    ensure => $ensure,
  }
  # to debug regexes
  $pcregrep_ensure = $facts['os']['distro']['codename'] ? {
    'bookworm' => $ensure,
    default    => 'purged',
  }
  package { 'pcregrep':
    ensure => $pcregrep_ensure,
  }
  if $::osfamily == 'Debian' {
    # before BULLSEYE, add mtail from bullseye
    if versioncmp($::lsbmajdistrelease, '11') < 0 {
      apt::source { 'bullseye':
        location => 'https://mirror.hetzner.de/debian/packages/',
        release  => 'bullseye',
        repos    => 'main',
      }
      apt::pin { 'bullseye':
        explanation => 'disable upgrades to bullseye',
        priority    => 1,
        codename    => 'bullseye',
      }
      apt::pin { 'mtail':
        explanation => 'mtail from buster and earlier is buggy, see https://gitlab.torproject.org/tpo/tpa/team/-/issues/33951',
        packages    => ['mtail'],
        priority    => 500,
        codename    => 'bullseye',
        notify      => Package['mtail'],
      }
      Package['mtail'] {
        require => [
          Apt::Source['bullseye'],
          Apt::Pin['mtail'],
          Apt::Pin['bullseye'],
          Exec['apt_update'],
        ],
      }
    }
  }
  service { 'mtail':
    ensure  => $service_ensure,
    require => Package['mtail'],
    enable  => $ensure == 'present',
  }
  if $ensure == 'present' {
    # XXX: old-style init.d configuration, probably belongs in a systemd
    # override instead
    file_line { 'default-mtail-enable':
      path    => '/etc/default/mtail',
      line    => 'ENABLED=1',
      notify  => Service['mtail'],
      require => Package['mtail'],
    }
    if $logs {
      file_line { 'default-mtail-logs':
        path    => '/etc/default/mtail',
        line    => "LOGS=${logs}",
        match   => '^LOGS=',
        notify  => Service['mtail'],
        require => Package['mtail'],
      }
    }
    if $scrape_job {
      # this is pretty much cargo-culted from prometheus::daemon
      @@prometheus::scrape_job { "${::fqdn}_3903":
        job_name => 'mtail',
        targets  => ["${::fqdn}:3903"],
        labels   => $scrape_job_labels,
      }
    }
    if $firewall == 'ferm' {
      # realize the allow rules defined on the prometheus server(s)
      # this is expected to be exported on the Prometheus server so
      # that it is realized here
      Ferm::Rule <<| tag == 'profile::prometheus::server-mtail-exporter' |>>
    }
  }
}
