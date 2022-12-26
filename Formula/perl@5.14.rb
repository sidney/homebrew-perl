class PerlAT514 < Formula
  desc "Highly capable and feature-rich programming language"
  homepage "https://www.perl.org/"
  url "https://www.cpan.org/src/5.0/perl-5.14.4.tar.bz2"
  sha256 "eece8c2b0d491bf6f746bd1f4f1bb7ce26f6b98e91c54690c617d7af38964745"
  license any_of: ["Artistic-1.0-Perl", "GPL-1.0-or-later"]

  bottle do
    root_url "https://github.com/sidney/homebrew-perl/releases/download/perl@5.14-5.14.4"
    rebuild 2
    sha256 monterey: "732a4adcc3429d1383996fe13860f87f4b486f1564a80222dc6eb8219eedf176"
    sha256 big_sur:  "63df075ff51996547dce92d1190e3dfaed9b310e5b60d8663725bd26c27f03c9"
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

  def install
    args = %W[
      -des
      -Dinstallstyle=lib/perl5
      -Dinstallprefix=#{prefix}
      -Dprefix=#{opt_prefix}
      -Dprivlib=#{opt_lib}/perl5/#{version.major_minor}
      -Dsitelib=#{opt_lib}/perl5/site_perl/#{version.major_minor}
      -Dotherlibdirs=#{HOMEBREW_PREFIX}/lib/perl5/site_perl/#{version.major_minor}
      -Dperlpath=#{opt_bin}/perl
      -Dstartperl=#!#{opt_bin}/perl
      -Dman1dir=#{opt_share}/man/man1
      -Dman3dir=#{opt_share}/man/man3
      -Duseshrplib
      -Duselargefiles
      -Dusethreads
    ]

    inreplace "hints/darwin.sh", "env MACOSX_DEPLOYMENT_TARGET=10.3 ", "" if OS.mac? && MacOS.version > :leopard

    system "./Configure", *args
    system "make"
    system "make", "install"
  end

  def post_install
    resource("cpanm").stage do
      system "#{bin}/perl", "Makefile.PL", "INSTALL_BASE=#{prefix}",
                                "INSTALLSITEMAN1DIR=#{man1}",
                                "INSTALLSITEMAN3DIR=#{man3}"
      system "make", "install"
    end
    ENV["PERL_CPANM_HOME"] = "#{prefix}/.cpanm"
    system "#{bin}/cpanm", "Pod::Perldoc::ToMan"
    system "#{bin}/cpanm", "ExtUtils::MakeMaker"
    system "#{bin}/cpanm", "DB_File"
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
