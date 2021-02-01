# mtail is a log counting software we use to derive metrics from logfiles
#
# @param ensure to install or remove all resources in this class
# @param logs which log files to parse, if not default
# @param program_directory where the programs should be stored
class mtail(
  Enum['present','absent'] $ensure = 'present',
  String $logs                     = undef,
  String $program_directory        = '/etc/mtail',
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
  package { 'pcregrep':
    ensure => $ensure,
  }
  service { 'mtail':
    ensure  => $service_ensure,
    require => Package['mtail'],
  }
  if $ensure == 'present' {
    # XXX: old-style init.d configuration, probably belongs in a systemd
    # override instead
    file_line { 'default-mtail-enable':
      path   => '/etc/default/mtail',
      line   => 'ENABLED=1',
      notify => Service['mtail'],
    }
    if $logs {
      file_line { 'default-mtail-logs':
        path   => '/etc/default/mtail',
        line   => "LOGS=${logs}",
        notify => Service['mtail'],
      }
    }
  }
}
