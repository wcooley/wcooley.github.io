= Authentication Notes =

Various general bits about authentication.

== Challenge-Response Authentication Requires Plain-text Passwords ==

It is often asked why plain-text passwords are necessary for challenge-response authentication types.  Examples of implementations of challenge-response authentication are CHAP for dial-up; SASL mechanisms CRAM-MD5; and NT and LanManager passwords used by Samba and Windows.

With traditional authentication, passwords are stored on the server in an encrypted, or hashed, format, that cannot be reversed.  Authentication happens because the password is passed to the authentication service in clear-text, which then hashes the password and compares the stored password hash with the resulting hash.  As a result, in client-server networks, the password must be passed over the wire at some level in clear-text.  The danger of passing the password in a readable format over a snoopable medium can be mitigated by using an encrypting layer below the authentication; this is particularly convenient if you want to be encrypt the other traffic too.  For example, you can use HTTP, IMAP, LDAP, POP3, and many other protocols easily over SSL/TLS; you can also encrypt all higher-level traffic using IPSec's ESP.

With challenge-response authentication, however, the password is never passed between client and server in clear-text.  In order to achive this, however, the password must be stored on the server in clear-text.  Challenge-response authentication work generally like this:
  1. The client sends an authentication request to the server.
  1. The server looks up the username or other identifier, generates some random data, and encrypts it with the stored password.
  1. The client, in order to demonstrate that it knows the same password as the server, decrypts the random data and sends it back to the server.
  1. The server verifies that the returned data is the same as the data that it started with, and proceeds accordingly.

This is a simple explanation of how challenge-response authentication works.  It very likely differs in many particulars from actual implementations, but should give you an idea of how things work.

See also:
  * [http://acs-wiki.andrew.cmu.edu/twiki/bin/view/Cyrus/WhyCyrusSaslPlaintextPasswords Why does Cyrus SASL store plaintext passwords in its databases? (Cyrus Wiki)]
  * [http://www.freeradius.org/faq/#4.4 PAP authentication works but CHAP fails (FreeRADIUS FAQ)]
  * [http://us1.samba.org/samba/ftp/docs/textdocs/ENCRYPTION.txt Samba ENCRYPTION.txt]
