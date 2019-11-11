mtail support for Puppet
========================

Description
-----------

This module does a minimal configuration of the [mtail][] parser in
Puppet.

[mtail]: https://github.com/google/mtail/

Setup
-----

No particular setup is required for this module.

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

Limitations
-----------

Assumes your package manager knows about mtail.

Tested on Debian buster, compatibility with other versions and
distributions unknown.

Development
-----------

Written by Antoine Beaupré <anarcat@debian.org> for the Tor Project.
