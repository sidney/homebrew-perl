class PerlAT532 < Formula
  desc "Highly capable and feature-rich programming language"
  homepage "https://www.perl.org/"
  url "https://www.cpan.org/src/5.0/perl-5.32.1.tar.xz"
  sha256 "57cc47c735c8300a8ce2fa0643507b44c4ae59012bfdad0121313db639e02309"
  license any_of: ["Artistic-1.0-Perl", "GPL-1.0-or-later"]

  bottle do
    root_url "https://github.com/sidney/homebrew-perl/releases/download/perl@5.32-5.32.1"
    rebuild 1
    sha256 ventura:  "ee76fcc21b33f33b3f388d9d4c9342a02d828dd92ebe9bc838423776710d9963"
    sha256 monterey: "9b7c5dd9487409c30b0d477ce0317ce4dc0d0c6de3575867a8aa9504e1693c2f"
    sha256 big_sur:  "3e8e62b67b9bf032dce774ac54dccd69b5afe2efa21dad1e52ceac4ab519789c"
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
