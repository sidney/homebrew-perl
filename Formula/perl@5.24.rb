class PerlAT524 < Formula
  desc "Highly capable and feature-rich programming language"
  homepage "https://www.perl.org/"
  url "https://www.cpan.org/src/5.0/perl-5.24.4.tar.xz"
  sha256 "7f080287ff64750270689843ae945f02159a33cb8f2fc910248c15befba5db84"
  license any_of: ["Artistic-1.0-Perl", "GPL-1.0-or-later"]

  bottle do
    root_url "https://github.com/sidney/homebrew-perl/releases/download/perl@5.24-5.24.4"
    rebuild 1
    sha256 ventura:  "326877652a4cfce998a067f16f88028b6c6edcebb39e8e4ffddadcf354f621c0"
    sha256 monterey: "f9b744dda8c1b4e933761ecce87a99372d55b8ddd3f9fb4dd788fa318a3ffd79"
    sha256 big_sur:  "903600f9af90e1337f45aeb36570bb91d5236cbe9176d03837af7a24c1d3894f"
  end

  keg_only :versioned_formula

  depends_on "berkeley-db"
  depends_on "gdbm"
  depends_on :macos

  uses_from_macos "expat"
  uses_from_macos "libxcrypt"

  # Prevent site_perl directories from being removed
  skip_clean "lib/perl5/site_perl"
  resource("cpanm") do
    url "https://cpan.metacpan.org/authors/id/M/MI/MIYAGAWA/App-cpanminus-1.7046.tar.gz"
    sha256 "3e8c9d9b44a7348f9acc917163dbfc15bd5ea72501492cea3a35b346440ff862"
  end
  patch :DATA

  # all except first use of homebrew paths were changed from #{opt_foo} to {foo} so that perl is
  # built with paths that can be used in the install block before creating the opt links to Cellar
  def install
    args = %W[
      -des
      -Dinstallstyle=lib/perl5
      -Dinstallprefix=#{prefix}
      -Dprefix=#{prefix}
      -Dprivlib=#{lib}/perl5/#{version.major_minor}
      -Dsitelib=#{lib}/perl5/site_perl/#{version.major_minor}
      -Dotherlibdirs=#{HOMEBREW_PREFIX}/lib/perl5/site_perl/#{version.major_minor}
      -Dperlpath=#{bin}/perl
      -Dstartperl=#!#{bin}/perl
      -Dman1dir=#{man}/man1
      -Dman3dir=#{man}/man3
      -Duseshrplib
      -Duselargefiles
      -Dusethreads
    ]

    system "./Configure", *args
    system "make"
    system "make", "install"
    ENV["DYLD_LIBRARY_PATH"] = buildpath
    resource("cpanm").stage do
      system "#{bin}/perl", "Makefile.PL", "INSTALL_BASE=#{prefix}",
                                "INSTALLSITEMAN1DIR=#{man1}",
                                "INSTALLSITEMAN3DIR=#{man3}"
      system "make", "install"
    end
    ENV["PERL_CPANM_HOME"] = "#{buildpath}/.cpanm"
    system "#{bin}/cpanm", "-n", "ExtUtils::MakeMaker"
    system "#{bin}/cpanm", "-n", "Pod::Perldoc"
    system "#{bin}/cpanm", "-n", "DB_File"
    system "#{bin}/cpanm", "-n", "App::cpanoutdated"
    system "#{bin}/cpan-outdated -p | #{bin}/cpanm -n"
  end

  def post_install
    if OS.linux?
      perl_archlib = Utils.safe_popen_read(bin/"perl", "-MConfig", "-e", "print $Config{archlib}")
      perl_core = Pathname.new(perl_archlib)/"CORE"
      if File.readlines("#{perl_core}/perl.h").grep(/include <xlocale.h>/).any? &&
         (OS::Linux::Glibc.system_version >= "2.26" ||
         (Formula["glibc"].any_version_installed? && Formula["glibc"].version >= "2.26"))
        # Glibc does not provide the xlocale.h file since version 2.26
        # Patch the perl.h file to be able to use perl on newer versions.
        # locale.h includes xlocale.h if the latter one exists
        inreplace "#{perl_core}/perl.h", "include <xlocale.h>", "include <locale.h>"
      end
    end
  end

  def caveats
    <<~EOS
      By default non-brewed cpan modules are installed to the Cellar. If you wish
      for your modules to persist across updates we recommend using `local::lib`.

      You can set that up like this:
        PERL_MM_OPT="INSTALL_BASE=$HOME/perl5" cpan local::lib
        echo 'eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib=$HOME/perl5)"' >> #{shell_profile}
    EOS
  end

  test do
    (testpath/"test.pl").write "print 'Perl is not an acronym, but JAPH is a Perl acronym!';"
    system "#{bin}/perl", "test.pl"
  end
end
__END__
diff --git a/hints/darwin.sh b/hints/darwin.sh
index 0a91bc083c01c5649e930c2d4be61c8a5febfef9..fdfbdd4a3b9438a79d414c14aeaeb2820e213897 100644
--- a/hints/darwin.sh
+++ b/hints/darwin.sh
@@ -301,7 +301,7 @@ case "$osvers" in  # Note: osvers is the kernel version, not the 10.x
    # We now use MACOSX_DEPLOYMENT_TARGET, if set, as an override by
    # capturing its value and adding it to the flags.
     case "$MACOSX_DEPLOYMENT_TARGET" in
-    10.*)
+    [1-9][0-9].*)
       add_macosx_version_min ccflags $MACOSX_DEPLOYMENT_TARGET
       add_macosx_version_min ldflags $MACOSX_DEPLOYMENT_TARGET
       ;;
@@ -313,7 +313,7 @@ case "$osvers" in  # Note: osvers is the kernel version, not the 10.x
 
 *** Unexpected MACOSX_DEPLOYMENT_TARGET=$MACOSX_DEPLOYMENT_TARGET
 ***
-*** Please either set it to 10.something, or to empty.
+*** Please either set it to a valid macOS version number (e.g., 10.15) or to empty.
 
 EOM
       exit 1
@@ -327,7 +327,7 @@ EOM
     # "ProductVersion:    10.11"     "10.11"
         prodvers=`sw_vers|awk '/^ProductVersion:/{print $2}'|awk -F. '{print $1"."$2}'`
     case "$prodvers" in
-    10.*)
+    [1-9][0-9].*)
       add_macosx_version_min ccflags $prodvers
       add_macosx_version_min ldflags $prodvers
       ;;
