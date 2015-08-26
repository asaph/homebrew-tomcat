require 'formula'

class Tomcat < Formula
  homepage "https://tomcat.apache.org/"
  url "https://www.apache.org/dyn/closer.cgi?path=tomcat/tomcat-8/v8.0.26/bin/apache-tomcat-8.0.26.tar.gz"
  mirror "https://archive.apache.org/dist/tomcat/tomcat-8/v8.0.26/bin/apache-tomcat-8.0.26.tar.gz"
  sha256 "9f11588f0ff767adde63cd6919462c0c2742897560f4b367a0ffffdd8b1ed382"

  option "with-ssl", "Configure SSL and generate a self-signed cert. If building with APR,\n\tuse OpenSSL to generate the cert, otherwise use java's keytool"
  option "with-apr", "Use Apache Portable Runtime"
  option "with-compression", "Configure tomcat to use gzip compression on the following mime types:\n\ttext/html, text/xml, text/plain, text/css, application/javascript, application/xml, image/svg+xml"
  option "with-trim-spaces", "Configure tomcat to trim white space in JSP template text between actions or directives"
  option "with-https-only-manager", "Configure tomcat manager app to only allow connections via https"
  option "with-mysql-connector", "Install MySQL JDBC Connector into tomcat's lib folder.\n\tUseful for container managed connection pools"
  option "with-javamail", "Install the JavaMail jar into tomcat's lib folder.\n\tUseful for containter managed mail resources"
  option "with-fulldocs", "Install full documentation locally"
  option "with-ajp", "Configure AJP connector"
  option "without-headless", "Don't run tomcat with -Djava.awt.headless=true"
  option "without-sendfile", "Disable sendfile if the connector supports it"
  option "with-urlencoded-slashes", "Allow urlencoded slash characters (%2F) in the path component of urls"

  depends_on "openssl" if build.with? "apr"
  depends_on 'tomcat-native' => ['--without-tomcat', '--with-apr'] if build.with? 'apr'

  resource 'fulldocs' do
    url "https://www.apache.org/dyn/closer.cgi?path=/tomcat/tomcat-8/v8.0.26/bin/apache-tomcat-8.0.26-fulldocs.tar.gz"
    mirror "https://archive.apache.org/dist/tomcat/tomcat-8/v8.0.26/bin/apache-tomcat-8.0.26-fulldocs.tar.gz"
    version "8.0.26"
    sha256 "813513d61e6def5ccf01adc95bf9d28594fce71ff32f5e23dc1482c7ec2f129b"
  end

  resource 'mysql-connector' do
    url 'http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.35.tar.gz'
    sha256 'fa77909a62363c1aa49ef5ab537ed4affe90a4a6aa5dd1045555b16b2611306d'
  end

  resource 'javamail' do
    url 'https://maven.java.net/content/repositories/releases/com/sun/mail/javax.mail/1.5.2/javax.mail-1.5.2.jar'
    sha256 'fb3becba9b18c010b243e32211c26fcda1115e8a47b759d8d0cf288f929029b2'
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

    if build.with? 'urlencoded-slashes'
      catalina_opts << '-Dorg.apache.tomcat.util.buf.UDecoder.ALLOW_ENCODED_SLASH=true'
    end

    if build.without? 'ajp'
      # comment out the AJP connector element
      inreplace libexec/'conf/server.xml', /(<Connector\s+[^>]*?\s+protocol=\"AJP\/\d+(?:.\d+)?\"[^>]*?\/>)/, "<!--\n#{indent}\\1\n#{indent}-->"
    end

    if build.with? 'ssl'
      # uncomment ssl connector in server.xml
      inreplace libexec/'conf/server.xml', /<!--\s*(<Connector\s+.[^>]*?\s+secure=\"true\"[^>]*?\/>)\s*-->/, "\\1"

      if build.with? 'apr'
        # generate a self signed cert
        system "#{Formula['openssl'].bin}/openssl req -new -newkey rsa:2048 -nodes -days 365 -x509 -subj \"/C=/ST=/L=/O=/CN=localhost\" -keyout #{libexec}/conf/privkey.pem -out #{libexec}/conf/cacert.pem"
        # configure the the connector for an OpenSSL cert
        inreplace libexec/'conf/server.xml', /(<Connector\s+[^>]*?\s+protocol=\")[^\"]*(\"[^>]*?\s+secure=\"true\"[^>]*?)(\s*\/>)/,
                    "\\1HTTP/1.1\\2\n#{attribute_indent}SSLCertificateFile=\"${catalina.home}/conf/cacert.pem\" SSLCertificateKeyFile=\"${catalina.home}/conf/privkey.pem\"\\3"
      else
        # generate a self signed cert
        system "`/usr/libexec/java_home`/bin/keytool -genkey -validity 365 -alias \"tomcat\" -keyalg \"RSA\" -keystore #{libexec}/conf/.keystore -keypass \"tomcat\" -storepass \"tomcat\" -dname \"CN=localhost, OU=, O=, L=, S=, C=\""
        # configure the connector for a .keystore cert
        inreplace libexec/'conf/server.xml', /(<Connector\s+[^>]*?\s+secure=\"true\"[^>]*?)(\s*\/>)/, "\\1\n#{attribute_indent}keystoreFile=\"${catalina.home}/conf/.keystore\" keystorePass=\"tomcat\"\\2"
      end
    end

    if build.with? 'apr'
      # put tomcat-native into the classpath
      catalina_opts << "-Djava.library.path=#{Formula["tomcat-native"].lib}"
    end

    if build.with? 'compression'
      # add compression attributes to all HTTP/1.1 connectors
      compression_attributes = 'compression="on" compressableMimeType="text/html,text/xml,text/plain,text/css,application/javascript,application/xml,image/svg+xml"'
      inreplace libexec/'conf/server.xml', /(<Connector\s+[^>]*?\s+protocol=\"(?:HTTP\/1\.1|org\.apache\.coyote\.http11\.[A-Za-z0-9]+)\"[^>]*?)(\s*\/>)/, "\\1\n#{attribute_indent}#{compression_attributes}\\2"
    end

    if build.with? 'trim-spaces'
      trim_spaces_xml = "\n#{doubleIndent}<init-param>\n#{tripleIndent}<param-name>trimSpaces</param-name>\n#{tripleIndent}<param-value>true</param-value>\n#{doubleIndent}</init-param>"
      inreplace libexec/'conf/web.xml', /(<servlet>\s*<servlet-name>jsp<\/servlet-name>[\s\S]*?)(\s*<load-on-startup>\d+<\/load-on-startup>\s*<\/servlet>)/, "\\1#{trim_spaces_xml}\\2"
    end

    if build.with? 'https-only-manager'
      https_only_manager_xml = "\n    <user-data-constraint>\n      <transport-guarantee>CONFIDENTIAL</transport-guarantee>\n    </user-data-constraint>"
      inreplace libexec/'webapps/manager/WEB-INF/web.xml', /(\s*<\/security-constraint>)/, "#{https_only_manager_xml}\\1"
    end

    if build.without? 'sendfile'
      sendfileSize_xml = "\n#{doubleIndent}<init-param>\n#{tripleIndent}<param-name>sendfileSize</param-name>\n#{tripleIndent}<param-value>-1</param-value>\n#{doubleIndent}</init-param>"
      inreplace libexec/'conf/web.xml', /(<servlet>\s*<servlet-name>default<\/servlet-name>[\s\S]*?)(\s*<load-on-startup>\d+<\/load-on-startup>\s*<\/servlet>)/, "\\1#{sendfileSize_xml}\\2"
    end

    if build.with? 'mysql-connector'
      (libexec/'lib').install resource('mysql-connector').files('mysql-connector-java-5.1.35-bin.jar')
    end

    if build.with? 'javamail'
      (libexec/'lib').install resource('javamail').files('javax.mail-1.5.2.jar')
    end

    (share/'fulldocs').install resource('fulldocs') if build.with? 'fulldocs'

    if catalina_opts.any?
      setenv = "CATALINA_OPTS=\"" + catalina_opts.join(' ') + "\""
      File.open(libexec/'bin/setenv.sh', 'w') {|file| file.puts setenv}
      File.chmod(0755, libexec/'bin/setenv.sh')
    end
  end
end
