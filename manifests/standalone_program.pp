# a standalone "mtail program" is one parser unit that will construct
# specific metrics from patterns
#
# this differs from mtail::program in that it creates its own systemd
# unit and expects its own unique program to be used.
#
# for high traffic logs, this is better because only the right regex
# pattern is applied to the right log
#
# @param ensure to install or remove all resources in this define
# @param content the content of the file
# @param source the source of the file
# @param logs which log files to parse, separated by commas, if not default
# @param scrape_job if enabled, will export a `prometheus::scrape_job`
#                   for the prometheus central server to collect
# @param scrape_job_labels which labels to add to the exported job
# @param firewall which firewall to configure to allow connexions. hackish.
#
# All parameters are passed directly to the File resource.
define mtail::standalone_program(
  String $logs,
  Enum['present','absent'] $ensure  = 'present',
  Optional[String] $content         = undef,
  Optional[String] $source          = undef,
  String[1] $program_directory      = $mtail::program_directory,
  Integer $port                     = 3904,
  Boolean $scrape_job               = true,
  String[1] $scrape_job_name        = 'mtail',
  Optional[Hash] $scrape_job_labels = {
    'alias'   => $facts['networking']['fqdn'],
    'classes' => "role::${pick($::role, 'undefined')}",
  },
  Optional['ferm'] $firewall        = 'ferm',
) {
  include mtail
  ensure_resource('file', extlib::dir_split($program_directory), {'ensure' => 'directory'})
  file { "${program_directory}/${name}":
    ensure  => $ensure ? {
      'present' => 'directory',
      'absent'  => 'absent',
    },
  }
  file { "${program_directory}/${name}/${name}.mtail":
    ensure  => $ensure,
    content => $content,
    source  => $source,
    notify  => Systemd::Unit_file["mtail_${name}_${port}.service"],
    require => File["${program_directory}/${name}"],
  }
  systemd::unit_file { "mtail_${name}_${port}.service":
    ensure  => present,
    enable  => true,
    active  => true,
    content => epp('mtail/systemd.epp', {
      logs              => $logs,
      port              => $port,
      program_directory => "${program_directory}/${name}",
    })
  }
  if $scrape_job {
    # this is pretty much cargo-culted from prometheus::daemon
    @@prometheus::scrape_job { "${facts['networking']['fqdn']}_${port}":
      job_name => $scrape_job_name,
      targets  => ["${facts['networking']['fqdn']}:${port}"],
      labels   => $scrape_job_labels,
    }
  }
  if $firewall == 'ferm' {
    # realize the allow rules defined on the prometheus server(s)
    # this is expected to be exported on the Prometheus server so
    # that it is realized here
    Ferm::Rule <<| tag == "profile::prometheus::server-${scrape_job_name}-exporter" |>>
  }
}
