# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "gitindex/version"

Gem::Specification.new do |spec|
  spec.name          = "gitindex"
  spec.version       = GitIndex::VERSION
  spec.authors       = ["Kirk Haines"]
  spec.email         = ["wyhaines@gmail.com"]

  spec.summary       = %q{This is a very simple little tool that creates an index of git repositories, keyed by the commit hash codes for the first and second commits in the repository.}
  spec.description   = <<~EDESC
    This tool takes a list of paths and checks them for git repositories. It
    writes to a sqlite database a table of repositories found, indexed by both
    the first and the second commit hashes on the repository. The rationale is
    that these first couple of commits are unlikely to ever change as the
    result of a rebase, and thus make a fairly reliable fingerprint of the
    identity of the repository.
  EDESC
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^#{spec.bindir}/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
