require 'formula'

class Tomcat < Formula
  desc "Implementation of Java Servlet and JavaServer Pages"
  homepage "https://tomcat.apache.org/"

  stable do
    url "https://www.apache.org/dyn/closer.cgi?path=tomcat/tomcat-8/v8.5.4/bin/apache-tomcat-8.5.4.tar.gz"
    mirror "https://archive.apache.org/dist/tomcat/tomcat-8/v8.5.4/bin/apache-tomcat-8.5.4.tar.gz"
    sha256 "155cf7f09e13c63b8301ddc8c37d90be64bc3d5e9ddf163c4f10a6406a49a191"

    depends_on :java => "1.7+"

    resource "fulldocs" do
      url "https://www.apache.org/dyn/closer.cgi?path=/tomcat/tomcat-8/v8.5.4/bin/apache-tomcat-8.5.4-fulldocs.tar.gz"
      mirror "https://archive.apache.org/dist/tomcat/tomcat-8/v8.5.4/bin/apache-tomcat-8.5.4-fulldocs.tar.gz"
      version "8.5.4"
      sha256 "3971b2c802860e3eb7902136cb421c953bb87c42fb510b0dcf65d604129453d2"
    end
  end

  devel do
    url "https://www.apache.org/dyn/closer.cgi?path=/tomcat/tomcat-9/v9.0.2/bin/apache-tomcat-9.0.2.tar.gz"
    version "9.0.2"
    sha512 "6f365c7ef0359de8ca5d2e79608ac9d88549dac09189559c1c8a65bccecf0fed396c3d16827dd0698cc5d9c3f5aaf42e29b788968de60e63c288a8d2b6dc85b2"

    depends_on :java => "1.8+"

    resource "fulldocs" do
      url "https://www.apache.org/dyn/closer.cgi?path=/tomcat/tomcat-9/v9.0.2/bin/apache-tomcat-9.0.2-fulldocs.tar.gz"
      version "9.0.2"
      sha512 "8ea3fd0f2fe352bde755c5ffbcb2de5cb021746af38041af1f980ea1d55e2c4e6f10664fce492066ea47a834398421b2d0f48be91996169087cd90044ce9a3ba"
    end
  end

  bottle :unneeded

  option "with-ssl", "Configure SSL and generate a self-signed cert. If building with APR,\n\tuse OpenSSL to generate the cert, otherwise use java's keytool"
  option "with-apr", "Use Apache Portable Runtime"
  option "with-compression", "Configure tomcat to use gzip compression on the following mime types:\n\t\ttext/html, text/xml, text/plain, text/css, application/json,\n\t\tapplication/javascript, application/xml, image/svg+xml"
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
  depends_on 'tomcat-native' => ['1.2.7+', '--without-tomcat', '--with-apr'] if build.with? 'apr'

  resource 'mysql-connector' do
    url 'https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.38.tar.gz'
    sha256 'fa6232a0bcf67dc7d9acac9dc58910644e50790cbd8cc2f854e2c17f91b2c224'
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

    if build.with? 'apr'
      inreplace libexec/'conf/server.xml', /<Connector port="8080" protocol="HTTP\/1\.1"/, "<Connector port=\"8080\" protocol=\"org.apache.coyote.http11.Http11AprProtocol\""
    end

    if build.with? 'ssl'
      if build.with? 'apr'
        # generate a self signed cert
        system "#{Formula['openssl'].bin}/openssl req -new -newkey rsa:2048 -nodes -days 365 -x509 -subj \"/C=/ST=/L=/O=/CN=localhost\" -keyout #{libexec}/conf/privkey.pem -out #{libexec}/conf/cacert.pem"
        # configure the the connector for an OpenSSL cert
        # uncomment APR SSL connector in server.xml
        inreplace libexec/'conf/server.xml',
                  /<!--\s*(<Connector\s+.[^>]*?\s+protocol=\"org.apache.coyote.http11.Http11AprProtocol\"\s+.[^>]*?\s+SSLEnabled=\"true\"[^>]*?(\/>|.*?<\/Connector>))\s*-->/m, "\\1"
        # configure the self signed cert generated above
        inreplace libexec/'conf/server.xml', /(<Certificate\s+certificateKeyFile=\")[^\"]*(\"\s+certificateFile=\")[^\"]*(\"[^>]*\/>)/,
                  "\\1conf/privkey.pem\\2conf/cacert.pem\\3"
      else
        # generate a self signed cert
        system "`/usr/libexec/java_home`/bin/keytool -genkey -validity 365 -alias \"tomcat\" -keyalg \"RSA\" -keystore #{libexec}/conf/.keystore -keypass \"tomcat\" -storepass \"tomcat\" -dname \"CN=localhost, OU=, O=, L=, S=, C=\""
        # configure the connector for a .keystore cert
        # uncomment NIO SSL connector in server.xml
        inreplace libexec/'conf/server.xml',
                  /<!--\s*(<Connector\s+.[^>]*?\s+protocol=\"org.apache.coyote.http11.Http11NioProtocol\"\s+.[^>]*?\s+SSLEnabled=\"true\"[^>]*?(\/>|.*?<\/Connector>))\s*-->/m, "\\1"
        # configure the self signed cert generated above
        inreplace libexec/'conf/server.xml', /(<Certificate\s+certificateKeystoreFile=\")[^\"]*(\"[^>]*\/>)/,
                  "\\1conf/.keystore\" certificateKeystorePassword=\"tomcat\\2"
      end
    end

    if build.with? 'apr'
      # put tomcat-native into the classpath
      catalina_opts << "-Djava.library.path=$(brew --prefix tomcat-native)/lib"
    end

    if build.with? 'compression'
      # add compression attributes to all HTTP/1.1 connectors
      compression_attributes = 'compression="on" compressableMimeType="text/html,text/xml,text/plain,text/css,application/json,application/javascript,application/xml,image/svg+xml"'
      inreplace libexec/'conf/server.xml', /(<Connector\s+[^>]*?\s+protocol=\"(?:HTTP\/1\.1|org\.apache\.coyote\.http11\.[A-Za-z0-9]+)\"[^>]*?)(\s*\/?>)/, "\\1\n#{attribute_indent}#{compression_attributes}\\2"
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
      (libexec/'lib').install resource('mysql-connector').files('mysql-connector-java-5.1.38-bin.jar')
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
