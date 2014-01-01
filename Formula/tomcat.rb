require 'formula'

class Tomcat < Formula
  homepage 'http://tomcat.apache.org/'
  url 'http://www.apache.org/dyn/closer.cgi?path=tomcat/tomcat-7/v7.0.47/bin/apache-tomcat-7.0.47.tar.gz'
  sha1 'ea54881535fccb3dfd7da122358d983297d69196'

  option "with-ssl", "Configure SSL and generate a self-signed cert. If building with APR, use OpenSSL to generate the cert, otherwise use java's keytool"
  option "with-apr", "Use Apache Portable Runtime"
  option "with-compression", "Configure tomcat to use gzip compression on the following mime types: text/html, text/xml, text/plain, text/css, application/javascript"
  option "with-trim-spaces", "Configure tomcat to trim white space in JSP template text between actions or directives"
  option "with-mysql-connector", "Install MySQL JDBC Connector into tomcat's lib folder. Useful for container managed connection pools"
  option "with-javamail", "Install the JavaMail jar into tomcat's lib folder. Useful for containter managed mail resources"
  option "with-fulldocs", "Install full documentation locally"
  option "with-ajp", "Configure AJP connector"
  option "without-headless", "Don't run tomcat with -Djava.awt.headless=true"
  option "with-standard-ports", "Configure tomcat to listen on port 80 (http) and 443 (https) instead of 8080 (http) and 8443 (https), respectively"

  depends_on 'tomcat-native' => '--without-tomcat' if build.with? 'apr'

  devel do
    url 'http://www.apache.org/dyn/closer.cgi?path=tomcat/tomcat-8/v8.0.0-RC10/bin/apache-tomcat-8.0.0-RC10.tar.gz'
    sha1 'c6a8dc2a62dd6a3980d30ca2961c283c39e28ebe'

    resource 'fulldocs' do
      url 'http://www.apache.org/dyn/closer.cgi?path=/tomcat/tomcat-8/v8.0.0-RC10/bin/apache-tomcat-8.0.0-RC10-fulldocs.tar.gz'
      version '8.0.0-RC10'
      sha1 'a1859e67f6aa70e448d7db8901b0fc5bc4051aa6'
    end
  end

  resource 'fulldocs' do
    url 'http://www.apache.org/dyn/closer.cgi?path=/tomcat/tomcat-7/v7.0.47/bin/apache-tomcat-7.0.47-fulldocs.tar.gz'
    version '7.0.47'
    sha1 '31d26adb234c4b58a74ad717aaf83b39f67e8ea3'
  end

  resource 'mysql-connector' do
    url 'http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.27.tar.gz/from/http://cdn.mysql.com/'
    sha1 'cb92776b7c72cc506cb5d3305dfc78f3003358bd'
  end

  resource 'javamail' do
    url 'https://maven.java.net/content/repositories/releases/com/sun/mail/javax.mail/1.5.1/javax.mail-1.5.1.jar'
    sha1 '9724dd44f1abbba99c9858aa05fc91d53f59e7a5'
  end

  # Keep log folders
  skip_clean 'libexec'

  def install
    # Remove Windows scripts
    rm_rf Dir['bin/*.bat']

    # Install files
    prefix.install %w{ NOTICE LICENSE RELEASE-NOTES RUNNING.txt }
    libexec.install Dir['*']
    bin.install_symlink "#{libexec}/bin/catalina.sh" => "catalina"

    indent = '    '
    doubleIndent = "#{indent}#{indent}"
    tripleIndent = "#{doubleIndent}#{indent}"
    attribute_indent = '               '

    catalina_opts = [];

    if build.with? 'headless'
      catalina_opts << '-Djava.awt.headless=true'
    end

    if build.without? 'ajp'
      # comment out the AJP connector element
      inreplace libexec/'conf/server.xml', /(<Connector\s+.[^>]*?\s+protocol=\"AJP\/\d+(?:.\d+)?\"[^>]*?\/>)/, "<!--\n#{indent}\\1\n#{indent}-->"
    end

    if build.with? 'ssl'
      # uncomment ssl connector in server.xml
      inreplace libexec/'conf/server.xml', /<!--\s*(<Connector\s+.[^>]*?\s+secure=\"true\"[^>]*?\/>)\s*-->/, "\\1"

      if build.with? 'apr'
        # generate a self signed cert
        system "openssl req -new -newkey rsa:4096 -nodes -x509 -subj \"/C=/ST=/L=/O=/CN=localhost\" -keyout #{libexec}/conf/privkey.pem -out #{libexec}/conf/cacert.pem"
        # configure the the connector for an OpenSSL cert
        inreplace libexec/'conf/server.xml', /(<Connector\s+.[^>]*?\s+secure=\"true\"[^>]*?)(\s*\/>)/,
                    "\\1\n#{attribute_indent}SSLCertificateFile=\"${catalina.home}/conf/cacert.pem\" SSLCertificateKeyFile=\"${catalina.home}/conf/privkey.pem\"\\2"
      else
        # generate a self signed cert
        system "`/usr/libexec/java_home`/bin/keytool -genkey -alias \"tomcat\" -keyalg \"RSA\" -keystore #{libexec}/conf/.keystore -keypass \"tomcat\" -storepass \"tomcat\" -dname \"CN=localhost, OU=, O=, L=, S=, C=\""
        # configure the connector for a .keystore cert
        inreplace libexec/'conf/server.xml', /(<Connector\s+.[^>]*?\s+secure=\"true\"[^>]*?)(\s*\/>)/, "\\1\n#{attribute_indent}keystoreFile=\"${catalina.home}/conf/.keystore\" keystorePass=\"tomcat\"\\2"
      end
    end

    if build.with? 'apr'
      # put tomcat-native into the classpath
      catalina_opts << "-Djava.library.path=#{HOMEBREW_PREFIX}/Cellar/tomcat-native/1.1.29/lib"
    end

    if build.with? 'standard-ports'
      # replace port and redirectPort attributes
      inreplace libexec/'conf/server.xml', /(port\s*=\s*")8443(")/i, '\\1443\\2'
      inreplace libexec/'conf/server.xml', /(port\s*=\s*")8080(")/i, '\\180\\2'
      # be nice and fix the comments too
      inreplace libexec/'conf/server.xml', /(port\s*)8080/i, '\\180'
      inreplace libexec/'conf/server.xml', /(port\s*)8443/i, '\\1443'
    end

    if build.with? 'compression'
      # add compression attributes to all HTTP/1.1 connectors
      compression_attributes = 'compression="on" compressableMimeType="text/html,text/xml,text/plain,text/css,application/javascript"'
      inreplace libexec/'conf/server.xml', /(<Connector\s+.[^>]*?\s+protocol=\"HTTP\/1.1\"[^>]*?)(\s*\/>)/, "\\1\n#{attribute_indent}#{compression_attributes}\\2"
    end

    if build.with? 'trim-spaces'
      trim_spaces_xml = "\n#{doubleIndent}<init-param>\n#{tripleIndent}<param-name>trimSpaces</param-name>\n#{tripleIndent}<param-value>true</param-value>\n#{doubleIndent}</init-param>"
      inreplace libexec/'conf/web.xml', /(<servlet>\s*<servlet-name>jsp<\/servlet-name>[\s\S]*?)(\s*<load-on-startup>\d+<\/load-on-startup>\s*<\/servlet>)/, "\\1#{trim_spaces_xml}\\2"
    end

    if build.with? 'mysql-connector'
      (libexec/'lib').install resource('mysql-connector').files('mysql-connector-java-5.1.27-bin.jar')
    end

    if build.with? 'javamail'
      (libexec/'lib').install resource('javamail').files('javax.mail-1.5.1.jar')
    end

    (share/'fulldocs').install resource('fulldocs') if build.with? 'fulldocs'

    if catalina_opts.any?
      setenv = "CATALINA_OPTS=\"" + catalina_opts.join(' ') + "\""
      File.open(libexec/'bin/setenv.sh', 'w') {|file| file.puts setenv}
      File.chmod(0755, libexec/'bin/setenv.sh')
    end
  end
end
