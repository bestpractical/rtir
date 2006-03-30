use inc::Module::Install;

RTx('RT-IR');
license('GPL Version 2');
author('Best Practical Solutions <sales@bestpractical.com>');
#description('RT extension for Incident Response');
version('1.9.HEAD');

requires('DBIx::SearchBuilder', 1.40);
requires('Business::Hours');
requires('Business::SLA');
requires('Net::Whois::RIPE');
&auto_install;

# Test all of our sub-dist tests too
tests('t/*.t t/*/t/*.t');

&WriteAll;
