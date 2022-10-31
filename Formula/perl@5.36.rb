class PerlAT536 < Formula
  desc "Highly capable and feature-rich programming language"
  homepage "https://www.perl.org/"
  url "https://www.cpan.org/src/5.0/perl-5.36.0.tar.xz"
  sha256 "0f386dccbee8e26286404b2cca144e1005be65477979beb9b1ba272d4819bcf0"
  license any_of: ["Artistic-1.0-Perl", "GPL-1.0-or-later"]

  bottle do
    root_url "https://github.com/sidney/homebrew-perl/releases/download/perl@5.36-5.36.0"
    rebuild 1
    sha256 monterey: "9dbc27216182664bffdd6a58e25535778c8b00201268a842b8e56798f63b91a9"
    sha256 big_sur:  "ac8fbdeb4a6d945ff36c1da43d11e1badd31f08461ca24525fba7f153324e56b"
  end

  keg_only :versioned_formula

  depends_on "berkeley-db"
  depends_on "gdbm"
  depends_on :macos

  uses_from_macos "expat"
  uses_from_macos "libxcrypt"

  # Prevent site_perl directories from being removed
  skip_clean "lib/perl5/site_perl"

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

    system "./Configure", *args
    system "make"
    system "make", "install"
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
