homebrew-tomcat
===============

Homebrew tap for Apache Tomcat supporting advanced configuration including SSL, APR, gzip and more

Usage:
-

1. Backup any existing configuration or webapps in your existing brewed tomcat as these will be deleted shortly. (Skip this step if brewed tomcat isn't installed)
2. Shutdown your existing brewed tomcat. (Skip this step if brewed tomcat isn't running) 

    `catalina stop`

3. Delete your existing brewed tomcat

    `brew rm tomcat`

4. Tap this repo:

    `brew tap asaph/tomcat`

    You'll see this warning which is safe to ignore. It just means you'll have to qualify the tomcat formula name when referencing it

    `Warning: Could not tap asaph/tomcat/tomcat over Homebrew/homebrew/tomcat`

5. Install tomcat with APR, SSL and gzip compression

    `brew install --with-apr --with-ssl --with-compression asaph/tomcat/tomcat`

6. Start tomcat

    `catalina start`

7. To validate tomcat is working, point your browser to [http://localhost:8080/](http://localhost:8080/).

8. To validate https is working, point your browser to [https://localhost:8443/](https://localhost:8443/).

That's it! To see all available options:

    brew options asaph/tomcat/tomcat
