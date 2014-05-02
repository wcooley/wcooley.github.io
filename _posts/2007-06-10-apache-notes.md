= Apache Notes =

 * ApplicationNotes/ApacheNotes/CustomIndexes

== Fix Dreadful Truncated File Names ==

As people use Apache to anonymously serve files, more and more are we plagued with truncated file names in the listing.  You can usually see the file name if you mouse over the index link.  Here's the way to configure it to list variable-length file names:

{{{
<IfModule mod_autoindex.c>
    # FancyIndexing is whether you want fancy directory indexing or standard
    #
    IndexOptions FancyIndexing NameWidth=*

    # ...
</IfModule>
}}}

== Filter Log Entries ==

You can use the {{{SetEnvIf}}} entry, along with the {{{CustomLog}}} directive, to filter unnecessary junk out of the logs.  I used to do this in post-processing as part of the log rotation, but it's easier to do it here.  Here's a sample:{{{
SetEnvIf Request_URI "default\.ida" filtered-log
SetEnvIf Request_URI "root\.exe" filtered-log
SetEnvIf Request_URI "server-status" filtered-log
SetEnvIf Request_URI "cmd\.exe" filtered-log
SetEnvIf Remote_Addr x.x.x.x filtered-log      # My monitoring host, which generates a lot of misleading log entries
SetEnvIf Remote_Addr 127.0.0.1 filtered-log
                                                                                                                
LogFormat "%V %h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" vcommon
CustomLog /var/log/httpd/virtual_log vcommon env=!filtered-log
}}}

== Empty Directory Listings in CentOS 5 / Red Hat Enterprise Linux 5 ==

Upon upgrading to CentOS5 and (mostly) successfully migrating my Apache 2.0 ''httpd.conf'' to 2.2 by merging with
the installed configuration file, I was most perplexed to find that all of my directory listings generated by ''mod_autoindex'' were empty--as if the directories contained no files.  After further review, I discovered this entry: {{{
IndexIgnore .??* *~ *
}}}

The last "'''*'''" indicates that all normal files should be ignored.  I removed that and files suddenly appeared again.