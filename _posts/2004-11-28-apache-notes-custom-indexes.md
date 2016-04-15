---
tags: apache
category: application
title: "Application Notes: Apache httpd - Custom Indexes"
---
# Apache httpd - Custom Indexes

Inspired by the nice HTTP file server at [http://ftp.falsehope.com], I decided
to see what it took to make my [http://ftp.nakedape.cc FTP/HTTP server] look
nicer.  First, I had to adjust the Apache configuration itself to look for my
custom header and disable the generated HTML preamble.  Settings like this were
necessary:

```
AddType text/html .cgi
AddHandler cgi-script .cgi
<Directory /var/ftp>
    Options +Indexes +ExecCGI
    IndexOptions FancyIndexing NameWidth=* SuppressHTMLPreamble
    AllowOverride Indexes
    HeaderName /HEADER.cgi
    ReadmeName README.html
</Directory>
```

The `AddType` makes `.cgi` files type text/html, which is required by
`mod_autoindex`.  The `AddHandler` makes it a CGI, instead of just a plain
file, and of course the `ExecCGI` option is required to run it as a CGI.
`SuppressHTMLPreamble` makes it forego generating the HTML header.  Setting the
`HeaderName` to `/HEADER.cgi` means it always looks in the `DocumentRoot` for
the header-generator, instead of whatever path it is current in.  Setting the
`ReadmeName` gives you the option of including HTML in your README files and I
allow overriding the `Indexes` settings so I can use `AddDescription` in local
`.htaccess` files.

Why do you need to use a CGI anyway?  You can use a static HTML page, however,
it won't be able to tell the user what his current path is.  In the CGI
environment, this is stored in `REQUEST_URI` and is about the only thing you
need from the CGI environment (although I suppose you could pass other stuff
around).  It's rather too bad that `mod_autoindex` doesn't define an escape
sequence that will be replaced with the REQUEST_URI; you wouldn't need to
resort to CGI at all in that case.

I wrote two versions of the CGI, one in Perl and one in Python.  I could
probably have done it just with a shell script, but for some reason I have an
aversion to doing anything like this in shell.  Here's the Python version:

```
#!/usr/bin/python
 
import os
 
template_html_header = """Content-Type: text/html
 
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
<html>
<head>
    <title>Index of %s</title>
</head>
<body style="background-color: white">
<h1>Index of %s</h1>
"""

request_uri = os.environ.get('REQUEST_URI')

print template_html_header % (request_uri, request_uri)
```

And here's the version in Perl:

```
#!/usr/bin/perl
 
$path = $ENV{'REQUEST_URI'} ;
 
print <<EOF ;
Content-Type: text/html
 
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
<html>
<head>
    <title>Index of $path</title>
</head>
<body style="background-color: white">
<h1>Index of $path</h1>
EOF
```

And finally, the simplest way of all is to use server-side includes.  SSI is
generally too lame to be useful, but in this case it does enough and is
probably slightly faster than running a CGI script.  You'll want to make sure
SSI is enabled and change the `HeaderName` to `/HEADER.shtml`:

```
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
<html>
<head>
    <title>Index of <!--#echo var="DOCUMENT_URI" --></title>
</head>
<body style="background-color: white">
<h1>Index of <!--#echo var="DOCUMENT_URI" --></h1>
```

Pretty simple, eh?
