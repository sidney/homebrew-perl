class PerlAT520 < Formula
  desc "Highly capable and feature-rich programming language"
  homepage "https://www.perl.org/"
  url "https://www.cpan.org/src/5.0/perl-5.20.3.tar.bz2"
  sha256 "1b40068166c242e34a536836286e70b78410602a80615143301e52aa2901493b"
  license any_of: ["Artistic-1.0-Perl", "GPL-1.0-or-later"]

  bottle do
    root_url "https://github.com/sidney/homebrew-perl/releases/download/perl@5.20-5.20.3"
    rebuild 3
    sha256 ventura:  "b6d52487c569a9572109b42776f89597e7f7ac2e15fe1949309b5e46d320e278"
    sha256 monterey: "760bfca2fa6605ba4ba25f301f8468799a73397e1c9c3212c5e311ed9fbb8240"
    sha256 big_sur:  "e66b9f9a6a342c92c7a71f8e761b4d79b5fee890464443d1e346827273c0a40c"
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

    # necessary patch for perl versions last released before macOS 10.6 if they are to be built on newer macOS
    inreplace "hints/darwin.sh", "env MACOSX_DEPLOYMENT_TARGET=10.3 ", "" if OS.mac? && MacOS.version > :leopard

    system "./Configure", *args
    system "make"
    system "make", "install"
    # Some older perl versions have problems with some old version modules on newer macOS
    # Added install of cpanm and cpan-outdated then update some core cpan modules
    # This is done in install block so they end up in the bottles
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
