# a Prometheus exporter for Postfix based on mtail
#
# this exporter conflicts with the basic postfix exporter: they share
# some metrics and shouldn't be scraped together!
class mtail::postfix (
  Boolean $scrape_job = true,
) {
  class { 'mtail':
    logs       => '/var/log/mail.log',
    scrape_job => $scrape_job,
  }
  mtail::program { 'postfix':
    source => 'puppet:///modules/mtail/postfix.mtail',
  }
  file { '/usr/local/bin/postfix-queues-sizes':
    source => 'puppet:///modules/mtail/postfix-queues-sizes',
    mode   => '0555',
  }
  cron { 'prometheus-postfix-queues':
    command => '/usr/local/bin/postfix-queues-sizes | sponge /var/lib/prometheus/node-exporter/postfix-queues-sizes.prom',
    minute  => '*',
    user    => 'root',
    require => [
      File['/usr/local/bin/postfix-queues-sizes'],
      File['/var/lib/prometheus/node-exporter'],
    ],
  }
}
