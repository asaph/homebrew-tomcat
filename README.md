homebrew-tomcat
===============

Homebrew tap for Apache Tomcat supporting advanced configuration including SSL, APR, gzip and more.

**Note: The tomcat formula included in this tap will generate self-signed SSL certs which are suitable for development use only.
Production sites should swap out the self-signed SSL certs generated by this tap for real ones purchased from a trusted vendor.**

Usage:
-

1. Backup any existing configuration or webapps in your existing brewed tomcat as these will be deleted shortly. (Skip this step if brewed tomcat isn't installed)
2. Shutdown your existing brewed tomcat. (Skip this step if brewed tomcat isn't running) 

    `catalina stop`

3. Delete your existing brewed tomcat. (Skip this step if brewed tomcat isn't installed)

    `brew rm tomcat`

4. Tap this repo:

    `brew tap asaph/tomcat`

    You'll see this warning which is safe to ignore. It just means you'll have to qualify the tomcat formula name when referencing it

    `Warning: Could not tap asaph/tomcat/tomcat over Homebrew/homebrew/tomcat`

5. Install tomcat 8 with APR, SSL and gzip compression:

    `brew install --with-apr --with-ssl --with-compression asaph/tomcat/tomcat`

    or if installing tomcat 7:

    `brew install --with-apr --with-ssl --with-compression asaph/tomcat/tomcat7`

    or if installing tomcat 9 (alpha):

    `brew install --with-apr --with-ssl --with-compression --devel asaph/tomcat/tomcat`

6. Start tomcat

    `catalina start`

7. To validate tomcat is working, point your browser to [http://localhost:8080/](http://localhost:8080/).

8. To validate https is working, point your browser to [https://localhost:8443/](https://localhost:8443/).

That's it! To see all available options:

    brew options asaph/tomcat/tomcat

which will output:

    --with-ajp
    	Configure AJP connector
    --with-apr
    	Use Apache Portable Runtime
    --with-compression
    	Configure tomcat to use gzip compression on the following mime types:
    		text/html, text/xml, text/plain, text/css, application/json,
    		application/javascript, application/xml, image/svg+xml
    --with-fulldocs
    	Install full documentation locally
    --with-https-only-manager
    	Configure tomcat manager app to only allow connections via https
    --with-javamail
    	Install the JavaMail jar into tomcat's lib folder.
    	Useful for containter managed mail resources
    --with-mysql-connector
    	Install MySQL JDBC Connector into tomcat's lib folder.
    	Useful for container managed connection pools
    --with-ssl
    	Configure SSL and generate a self-signed cert. If building with APR,
    	use OpenSSL to generate the cert, otherwise use java's keytool
    --with-trim-spaces
    	Configure tomcat to trim white space in JSP template text between actions or directives
    --with-urlencoded-slashes
    	Allow urlencoded slash characters (%2F) in the path component of urls
    --without-headless
    	Don't run tomcat with -Djava.awt.headless=true
    --without-sendfile
    	Disable sendfile if the connector supports it
    --devel
    	Install development version 9.0.0.M4

License:
-

Code licensed under [BSD 2 Clause (NetBSD) license](https://github.com/asaph/homebrew-tomcat/blob/master/LICENSE) (same as [Homebrew](https://github.com/Homebrew/homebrew)).
