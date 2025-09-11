# a Prometheus exporter for Postfix based on mtail
#
# this exporter conflicts with the basic postfix exporter: they share
# some metrics and shouldn't be scraped together!
class mtail::postfix (
  Enum['present','absent'] $ensure  = 'present',
  Boolean $scrape_job = $mtail::scrape_job,
  Optional[Hash] $scrape_job_labels = $mtail::scrape_job_labels,
) {
  class { 'mtail':
    ensure     => $ensure,
    logs       => '/var/log/mail.log',
    scrape_job => $scrape_job,
    scrape_job_labels => $scrape_job_labels,
  }
  mtail::program { 'postfix':
    ensure => $ensure,
    source => 'puppet:///modules/mtail/postfix.mtail',
  }
  file { '/usr/local/bin/postfix-queues-sizes':
    ensure => $ensure,
    source => 'puppet:///modules/mtail/postfix-queues-sizes',
    mode   => '0555',
  }
  cron { 'prometheus-postfix-queues':
    ensure  => $ensure,
    command => '/usr/local/bin/postfix-queues-sizes | sponge /var/lib/prometheus/node-exporter/postfix-queues-sizes.prom',
    minute  => '*',
    user    => 'root',
    require => [
      File['/usr/local/bin/postfix-queues-sizes'],
      File['/var/lib/prometheus/node-exporter'],
    ],
  }
}
