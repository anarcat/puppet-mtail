# a "mtail program" is one parser unit that will construct specific
# metrics from patterns
#
# @param ensure to install or remove all resources in this define
# @param content the content of the file
# @param source the source of the file
#
# All parameters are passed directly to the File resource.
define mtail::program(
  Enum['present','absent'] $ensure = 'present',
  Optional[String] $content = undef,
  Optional[String] $source  = undef,
) {
  include mtail
  file { "${mtail::program_directory}/${name}.mtail":
    ensure  => $ensure,
    content => $content,
    source  => $source,
    notify  => Service['mtail'],
    require => Package['mtail'],
  }
}
