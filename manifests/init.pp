# mtail is a log counting software we use to derive metrics from logfiles
#
# @param ensure to install or remove all resources in this class
# @param logs which log files to parse, separated by commas, if not default
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
  Enum['present','absent'] $ensure                    = 'present',
  Optional[Enum['running','stopped']] $service_ensure = undef,
  String $logs                                        = undef,
  String $program_directory                           = '/etc/mtail',
  Boolean $scrape_job                                 = true,
  Optional[Hash] $scrape_job_labels                   = {
    'alias'   => $facts['networking']['fqdn'],
    'classes' => "role::${pick($::role, 'undefined')}",
  },
  Optional['ferm'] $firewall                          = 'ferm',
) {
  if $service_ensure == undef {
    if $ensure == 'present' {
      $_service_ensure = 'running'
    } else {
      $_service_ensure = 'stopped'
    }
  } else {
    $_service_ensure = $service_ensure
  }
  package { 'mtail':
    ensure => $ensure,
  }
  service { 'mtail':
    ensure  => $_service_ensure,
    require => Package['mtail'],
    enable  => $_service_ensure == 'running',
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
      @@prometheus::scrape_job { "${facts['networking']['fqdn']}_3903":
        job_name => 'mtail',
        targets  => ["${facts['networking']['fqdn']}:3903"],
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
