mtail support for Puppet
========================

Description
-----------

This module does a minimal configuration of the [mtail][] parser in
Puppet.

[mtail]: https://github.com/google/mtail/

Setup
-----

The module depends on the `apt` module to upgrade `mtail` to Debian
bullseye's version.

Usage
-----

This will enable mtail with the default configuration:

    include mtail

By default, mtail does nothing. It needs "programs" that will parse
and manipulate the data as required. Documentation of those programs
is outside of scope for this module, refer to the [upstream
documentation][] for details. For our purposes, it suffices to assume
a "program" is a file snippet. It can be shipped with this module
using the `mtail::program` directive:

    mtail::program { 'nginx':
        source => 'puppet:///modules/profiles/nginx/nginx.mtail',
    }

[upstream documentation]: https://google.github.io/mtail/

Notice how the `.mtail` extension is not required in the resource
name: it is automatically added.

Postfix queue sizes
---------------------

The Postfix mtail program does not know about queue sizes, naturally,
since that information is not included in logs. The `mtail::postfix`
class deploys a cron job that pushes metrics in the node exporter text
files collector.

Limitations
-----------

Assumes your package manager knows about mtail.

Tested on Debian buster, compatibility with other versions and
distributions unknown.

Will upgrade mtail to the bullseye version at least if not present,
because of issues in that older mtail version from buster.

Development
-----------

Written by Antoine Beaupré <anarcat@debian.org> for the Tor Project.
