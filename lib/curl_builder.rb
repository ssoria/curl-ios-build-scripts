require "logger"
require "optparse"
require "fileutils"
require "open3"


require_relative "curl_builder/errors"
require_relative "curl_builder/paths"
require_relative "curl_builder/logging"
require_relative "curl_builder/configurable_step"

# Steps
require_relative "curl_builder/parser"
require_relative "curl_builder/preparer"
require_relative "curl_builder/compiler"
require_relative "curl_builder/packer"
require_relative "curl_builder/cleaner"


# Phases
#   1. Read stdin: Parser
#   2. Download lib and create folders: Preparer
#   3. For each arch, compile: Compiler
#   4. Create output: Wrapper
#   5. Cleanup: Cleaner

module CurlBuilder
  extend self


  # Defaults

  DEFAULT_PROTOCOLS = {
    "http"   => true,
    "rtsp"   => false,
    "ftp"    => false,
    "file"   => false,
    "ldap"   => false,
    "ldaps"  => false,
    "dict"   => false,
    "telnet" => false,
    "tftp"   => false,
    "pop3"   => false,
    "imap"   => false,
    "smtp"   => false,
    "gopher" => false,

    # not really a protocol, but uses the "--enable-" prefix
    "threaded-resolver" => true,
  }

  DEFAULT_FLAGS = {
    "darwinssl" => true,
    "ssl"       => false,
    "libssh2"   => false,
    "librtmp"   => false,
    "libidn"    => false,
    "ca-bundle" => false
  }

  DEFAULT_SETUP = {
    log_level:          "info", # debug, info, warn, error
    verbose:            false,
    debug_symbols:      false,
    curldebug:          false,
    sdk_version:        `echo $iOS_SDK_VERSION`.strip,
    osx_sdk_version:    `echo $OSX_SDK_VERSION`.strip, #none for iPhoneSimulator
    libcurl_version:    `echo $LIB_CURL_VERSION`.strip,#"7.56.0",
    architectures:      %w(armv7 arm64 i386 x86_64),
    bitcode:            true,
    xcode_home:         "/Applications/Xcode.app/Contents/Developer",
    run_on_dir:         Dir::pwd,
    work_dir:           "build",
    result_dir:         "curl",
    clean_and_exit:     false,
    cleanup:            true,
  }

  VALID_ARGS = {architectures: %w(armv7 arm64 i386 x86_64)}


  attr_accessor :logger


  def logger
    @logger ||= Logger.new($stdout)
  end


  # Helper functions

  def build_protocols(protocols)
    protocols.collect { |protocol, enabled| enabled ? "--enable-#{protocol}" : "--disable-#{protocol}" }
  end

  def build_flags(flags)
    flags.collect { |flag, enabled| enabled ? "--with-#{flag}" : "--without-#{flag}" }
  end

  def filter_valid_archs(archs)
    VALID_ARGS[:architectures] & archs
  end
end
